// lib/services/supabase_service.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseClient client = Supabase.instance.client;

  // ============================================================
  // AUTH
  // ============================================================

  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email.trim(), password: password);
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Session? get currentSession => client.auth.currentSession;
  static User? get currentUser => client.auth.currentUser;

  // ============================================================
  // USERNAME & AVATAR
  // ============================================================

  /// Username regex doğrulama (client tarafı)
  static void _validateUsernameOrThrow(String username) {
    final reg = RegExp(r'^[A-Za-z0-9_.]{3,30}$');
    if (!reg.hasMatch(username)) {
      throw Exception(
        'Username 3–30 karakter olmalı; harf/rakam/_/. dışında karakter olamaz.',
      );
    }
  }

  /// Username müsait mi? (citext zaten case-insensitive)
  static Future<bool> isUsernameAvailable(String username) async {
    _validateUsernameOrThrow(username);

    final row = await client
        .from('profiles')
        .select('id')
        .eq('username', username.trim())
        .maybeSingle();

    return row == null;
  }

  /// Avatar'ı 'avatars' bucket'ına yükle ve public URL döndür
  static Future<String> _uploadAvatarAndGetPublicUrl(
    String uid,
    File file,
  ) async {
    final ext = p.extension(file.path); // .png/.jpg
    final path = 'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}$ext';

    final storage = client.storage.from('avatars');
    await storage.upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return storage.getPublicUrl(path);
  }

  // ============================================================
  // PROFILE
  // ============================================================

  /// Kayıt + profil tek adım (mail ile)
  static Future<void> signUpWithProfile({
    required String email,
    required String password,
    required String username,
    File? avatarFile,
  }) async {
    _validateUsernameOrThrow(username);

    final res = await client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Kullanıcı oluşturulamadı.');
    }

    String? avatarUrl;
    if (avatarFile != null) {
      avatarUrl = await _uploadAvatarAndGetPublicUrl(user.id, avatarFile);
    }

    await client.rpc(
      'upsert_profile',
      params: {'p_username': username.trim(), 'p_avatar_url': avatarUrl},
    );
  }

  /// Aktif kullanıcının profilini getir
  static Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    final row = await client
        .from('profiles')
        .select('id, username, avatar_url, created_at, updated_at')
        .eq('id', uid)
        .maybeSingle();

    return row;
  }

  /// Başka bir kullanıcının profilini getir
  static Future<Map<String, dynamic>?> getProfileById(String userId) async {
    final row = await client
        .from('profiles')
        .select('id, username, avatar_url, created_at, updated_at')
        .eq('id', userId)
        .maybeSingle();

    return row;
  }

  /// Profil güncelle (username ve/veya avatar)
  static Future<void> updateMyProfile({
    String? username,
    File? newAvatar,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Giriş gerekli');

    String? avatarUrl;
    if (newAvatar != null) {
      avatarUrl = await _uploadAvatarAndGetPublicUrl(uid, newAvatar);
    }

    await client.rpc(
      'upsert_profile',
      params: {
        'p_username': username ?? (await _ensureCurrentUsername()),
        'p_avatar_url': avatarUrl ?? (await _ensureCurrentAvatarUrl()),
      },
    );
  }

  static Future<String> _ensureCurrentUsername() async {
    final me = await getMyProfile();
    final u = me?['username'] as String?;
    if (u == null || u.isEmpty) {
      throw Exception('Mevcut username bulunamadı.');
    }
    return u;
  }

  static Future<String?> _ensureCurrentAvatarUrl() async {
    final me = await getMyProfile();
    return me?['avatar_url'] as String?;
  }

  /// Username değiştir (Google / Mail fark etmez)
  static Future<void> setMyUsername(String username) async {
    _validateUsernameOrThrow(username);

    final user = client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'username': username.trim(),
      }, onConflict: 'id');
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('duplicate') || msg.contains('unique')) {
        throw Exception('Bu kullanıcı adı kullanımda.');
      }
      rethrow;
    }
  }
}
