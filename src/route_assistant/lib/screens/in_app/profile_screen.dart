// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:route_assistant/services/supabase_service.dart';

import 'package:route_assistant/services/message_service.dart';
import 'package:route_assistant/screens/in_app/chat_screen.dart';

// ✅ ekle
import 'package:route_assistant/screens/in_app/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  /// null => kendi profili, dolu => başka kullanıcının profili
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  String? error;

  String? username;
  String? avatarUrl;
  String? email;

  late final String? _currentUserId;
  late final String? _targetUserId;

  bool get _isOwnProfile =>
      _targetUserId != null && _targetUserId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _targetUserId = widget.userId ?? _currentUserId;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          error = 'Oturum bulunamadı.';
          loading = false;
        });
        return;
      }

      // email sadece kendi profilinde
      email = _isOwnProfile ? currentUser.email : null;

      if (_targetUserId == null) {
        setState(() {
          error = 'Kullanıcı bulunamadı.';
          loading = false;
        });
        return;
      }

      final prof = await SupabaseService.getProfileById(_targetUserId!);
      if (prof == null) {
        setState(() {
          error = 'Profil bulunamadı.';
          loading = false;
        });
        return;
      }

      setState(() {
        username = (prof['username'] as String?)?.trim();
        avatarUrl = (prof['avatar_url'] as String?)?.trim();
        loading = false;
      });
    } on PostgrestException catch (e) {
      setState(() {
        error = e.message.isNotEmpty
            ? e.message
            : 'Bir veritabanı hatası oluştu.';
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Hata: $e';
        loading = false;
      });
    }
  }

  /// Sadece kendi profilinde avatar değiştir
  Future<void> _changeAvatar() async {
    if (!_isOwnProfile) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Avatar yükleniyor...')));

    try {
      await SupabaseService.updateMyProfile(newAvatar: file);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar başarıyla güncellendi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _openChat() async {
    if (_targetUserId == null) return;

    final convoId = await MessageService.getOrCreateConversation(
      otherUserId: _targetUserId!,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversationId: convoId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isOwnProfile ? 'Profil' : 'Profil'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : (error != null)
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(error!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar dene'),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _isOwnProfile ? _changeAvatar : null,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundImage:
                                    (avatarUrl != null && avatarUrl!.isNotEmpty)
                                    ? NetworkImage(avatarUrl!)
                                    : null,
                                child: (avatarUrl == null || avatarUrl!.isEmpty)
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                              ),
                              if (_isOwnProfile)
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          (username?.isNotEmpty ?? false)
                              ? '@${username!}'
                              : '@username',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),

                        if (_isOwnProfile && email?.isNotEmpty == true)
                          Text(email!, style: theme.textTheme.bodySmall),

                        const SizedBox(height: 12),

                        // ✅ Kendi profilinde Edit, başkasında Message
                        if (_isOwnProfile)
                          FilledButton.icon(
                            onPressed: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfileScreen(
                                    initialUsername: username,
                                  ),
                                ),
                              );

                              // ✅ değişiklik varsa yenile
                              if (changed == true) {
                                await _load();
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Profili Düzenle'),
                          )
                        else
                          FilledButton.icon(
                            onPressed: _openChat,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Mesaj Gönder'),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),

                  // ✅ Profilde SADECE 1 satır: My Routes
                  if (_isOwnProfile) ...[
                    Text('Content', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.map_outlined),
                            title: const Text('Rotalarım'),
                            subtitle: const Text('Oluşturduğun rotaları gör'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pushNamed(context, '/myRoutes');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_isOwnProfile) ...[
                    Text('Account', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.key),
                            title: const Text('User ID'),
                            subtitle: Text(_currentUserId ?? '-'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Çıkış Yap'),
                            onTap: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (!mounted) return;
                              Navigator.pushReplacementNamed(context, '/');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
