// lib/services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static const String webClientId =
      '687987351427-e496bq9n4208rfuqrqqd1qa9hohi8mmh.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: webClientId,
  );

  /// forceAccountPicker=true => her seferinde mail seçtirir
  static Future<void> signInWithGoogle({
    bool forceAccountPicker = false,
  }) async {
    if (forceAccountPicker) {
      try {
        await _googleSignIn.disconnect(); // izinleri de sıfırlar (en güçlü)
      } catch (_) {}
      try {
        await _googleSignIn.signOut(); // session temizler
      } catch (_) {}
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw 'Kullanıcı iptal etti.';

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) throw 'No ID Token found.';
    if (accessToken == null) throw 'No Access Token found.';

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }
}
