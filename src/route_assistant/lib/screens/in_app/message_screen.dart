import 'dart:async';
import 'package:flutter/material.dart';
import 'package:route_assistant/services/message_service.dart';
import 'package:route_assistant/screens/in_app/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  RealtimeChannel? _channel;
  Timer? _debounce;

  // ✅ Search
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  bool _searching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeInboxRealtime();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchDebounce?.cancel();
    _searchCtrl.dispose();

    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await MessageService.fetchInbox();
      if (!mounted) return;
      setState(() {
        _items = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _load();
    });
  }

  void _subscribeInboxRealtime() {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _channel = _client.channel('inbox_${user.id}');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) => _scheduleReload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
  }

  // =========================
  // SEARCH USERS
  // =========================
  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchUsers(q.trim());
    });
  }

  Future<void> _searchUsers(String q) async {
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);

    try {
      final me = _client.auth.currentUser?.id;

      final res = await _client
          .from('profiles')
          .select('id, username, avatar_url')
          .ilike('username', '%$q%')
          .limit(20);

      if (!mounted) return;
      setState(() {
        _searchResults = (res as List)
            .map((e) => Map<String, dynamic>.from(e))
            .where((u) => u['id']?.toString() != me)
            .toList();
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Arama hatası: $e')));
    }
  }

  Future<int> _getOrCreateConversation(String otherUserId) async {
    final me = _client.auth.currentUser!.id;

    final existing = await _client
        .from('conversations')
        .select('id')
        .or(
          'and(user_a.eq.$me,user_b.eq.$otherUserId),and(user_a.eq.$otherUserId,user_b.eq.$me)',
        )
        .maybeSingle();

    if (existing != null) return existing['id'] as int;

    final created = await _client
        .from('conversations')
        .insert({'user_a': me, 'user_b': otherUserId})
        .select('id')
        .single();

    return created['id'] as int;
  }

  Widget _buildSearchResults() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('Sonuç yok'));
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final u = _searchResults[i];
        final uid = u['id'].toString();
        final username = u['username']?.toString() ?? 'user';
        final avatar = u['avatar_url']?.toString();

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (avatar != null && avatar.isNotEmpty)
                ? NetworkImage(avatar)
                : null,
            child: (avatar == null || avatar.isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text('@$username'),
          onTap: () async {
            final convoId = await _getOrCreateConversation(uid);

            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: convoId,
                  peerId: uid,
                  peerName: '@$username',
                  peerAvatarUrl: avatar,
                ),
              ),
            );

            await _load();
            _searchCtrl.clear();
            if (mounted) {
              setState(() => _searchResults = []);
            }
          },
        );
      },
    );
  }

  Widget _buildInbox() {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(child: Text(_error!))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final row = _items[i];
                final convo = row['conversation'] as Map<String, dynamic>;
                final other = row['other'] as Map<String, dynamic>?;
                final last = row['last'] as Map<String, dynamic>?;

                final username = other?['username']?.toString() ?? 'user';
                final avatar = other?['avatar_url']?.toString();
                final preview = last?['content']?.toString() ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                        ? NetworkImage(avatar)
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text('@$username'),
                  subtitle: Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    final otherId = other?['id']?.toString();
                    final avatar = other?['avatar_url']?.toString();

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: convo['id'] as int,
                          peerId: otherId,
                          peerName: '@$username',
                          peerAvatarUrl: avatar,
                        ),
                      ),
                    );

                    await _load();
                  },
                );
              },
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Kullanıcı ara (@username)...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (q.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _searchResults = [];
                  _searching = false;
                });
              },
            ),
        ],
      ),
      body: q.isNotEmpty ? _buildSearchResults() : _buildInbox(),
    );
  }
}
