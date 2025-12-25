import 'dart:async';
import 'package:flutter/material.dart';
import 'package:route_assistant/services/message_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:route_assistant/screens/in_app/profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;

  // ✅ yeni: peer bilgileri
  final String? peerId;
  final String? peerName; // username veya görünen ad
  final String? peerAvatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.peerId,
    this.peerName,
    this.peerAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _client = Supabase.instance.client;

  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _msgs = [];

  RealtimeChannel? _channel;

  String? get _me => _client.auth.currentUser?.id;

  // Header (peer)
  bool _headerLoading = true;
  String? _peerId;
  String? _peerName;
  String? _peerAvatarUrl;

  @override
  void initState() {
    super.initState();

    // ✅ Parametreyle geldiyse direkt kullan
    _peerId = widget.peerId;
    _peerName = widget.peerName;
    _peerAvatarUrl = widget.peerAvatarUrl;

    _init();
  }

  Future<void> _init() async {
    // ✅ peer bilgisi yoksa DB’den bul
    if (_peerId == null || (_peerName == null && _peerAvatarUrl == null)) {
      await _loadPeerInfoFromDb();
    } else {
      if (mounted) setState(() => _headerLoading = false);
    }

    await _loadInitial();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    super.dispose();
  }

  // =========================
  // PEER INFO (DB fallback)
  // conversations: id, user_a, user_b
  // profiles: id, username/full_name, avatar_url  (hangisi varsa)
  // =========================
  Future<void> _loadPeerInfoFromDb() async {
    final me = _me;
    if (!mounted) return;
    setState(() => _headerLoading = true);

    if (me == null) {
      if (!mounted) return;
      setState(() {
        _peerName = _peerName ?? 'Kullanıcı';
        _headerLoading = false;
      });
      return;
    }

    try {
      final convo = await _client
          .from('conversations')
          .select('user_a, user_b')
          .eq('id', widget.conversationId)
          .single();

      final userA = convo['user_a']?.toString();
      final userB = convo['user_b']?.toString();
      if (userA == null || userB == null) throw 'Conversation invalid';

      final peerId = (userA == me) ? userB : userA;

      final profile = await _client
          .from('profiles')
          .select('username, full_name, avatar_url')
          .eq('id', peerId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _peerId = peerId;
        final uname = (profile?['username'] as String?)?.trim();
        final fname = (profile?['full_name'] as String?)?.trim();
        _peerName = (fname != null && fname.isNotEmpty)
            ? fname
            : (uname != null && uname.isNotEmpty)
            ? '@$uname'
            : 'Kullanıcı';
        _peerAvatarUrl = (profile?['avatar_url'] as String?);
        _headerLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _peerName = _peerName ?? 'Kullanıcı';
        _headerLoading = false;
      });
    }
  }

  void _openPeerProfile() {
    if (_peerId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: _peerId!)),
    );
  }

  // =========================
  // MESSAGES
  // =========================
  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await MessageService.fetchMessages(
        conversationId: widget.conversationId,
        limit: 200,
      );

      if (!mounted) return;
      setState(() {
        _msgs = data;
        _loading = false;
      });

      _scrollToBottom(jump: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _subscribeRealtime() {
    _channel = _client.channel('chat:${widget.conversationId}');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId.toString(),
          ),
          callback: (payload) {
            final row = payload.newRecord;
            final newId = row['id'];
            if (_msgs.any((m) => m['id'] == newId)) return;

            if (!mounted) return;
            setState(() => _msgs.add(Map<String, dynamic>.from(row)));
            _scrollToBottom();
          },
        )
        .subscribe();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    try {
      await MessageService.sendMessage(
        conversationId: widget.conversationId,
        content: text,
      );
      _ctrl.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mesaj gönderilemedi: $e')));
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      if (jump) {
        _scrollCtrl.jumpTo(max);
      } else {
        _scrollCtrl.animateTo(
          max,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _openPeerProfile,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      (_peerAvatarUrl != null &&
                          _peerAvatarUrl!.trim().isNotEmpty)
                      ? NetworkImage(_peerAvatarUrl!)
                      : null,
                  child:
                      (_peerAvatarUrl == null || _peerAvatarUrl!.trim().isEmpty)
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _headerLoading
                        ? 'Yükleniyor...'
                        : (_peerName ?? 'Kullanıcı'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _msgs.length,
                    itemBuilder: (context, i) {
                      final m = _msgs[i];
                      final mine = m['sender_id'].toString() == me;

                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: mine
                                ? Colors.green.withOpacity(0.15)
                                : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(m['content'].toString()),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 3,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Mesaj yaz...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
