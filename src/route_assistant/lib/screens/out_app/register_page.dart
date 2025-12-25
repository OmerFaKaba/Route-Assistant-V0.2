import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:route_assistant/assets/constants/color.dart';
import 'package:route_assistant/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailCtrl = TextEditingController();
  final pswrdCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();

  bool loading = false;

  Timer? _debounce;
  bool?
  _isAvailable; // null: kontrol yok/ediliyor, true: uygun, false: kullanımda
  String? _usernameError; // format hatası metni

  @override
  void initState() {
    super.initState();
    usernameCtrl.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    emailCtrl.dispose();
    pswrdCtrl.dispose();
    usernameCtrl.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final text = usernameCtrl.text.trim();

    final reg = RegExp(r'^[A-Za-z0-9_.]{3,30}$');
    if (text.isEmpty) {
      setState(() {
        _usernameError = 'Kullanıcı adı zorunlu';
        _isAvailable = null;
      });
      return;
    } else if (!reg.hasMatch(text)) {
      setState(() {
        _usernameError = '3–30, harf/rakam/_/. dışında karakter olamaz';
        _isAvailable = null;
      });
      return;
    } else {
      setState(() => _usernameError = null);
    }

    _debounce?.cancel();
    setState(() => _isAvailable = null);

    _debounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final ok = await SupabaseService.isUsernameAvailable(text);
        if (!mounted) return;

        // kullanıcı o sırada text'i değiştirdiyse eski sonucu basmayalım
        if (usernameCtrl.text.trim() == text) {
          setState(() => _isAvailable = ok);
        }
      } catch (_) {
        if (mounted) setState(() => _isAvailable = null);
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (loading) return;

    final username = usernameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = pswrdCtrl.text;

    // doğrulamalar
    if (username.isEmpty) {
      _showSnack('Kullanıcı adı zorunlu');
      return;
    }
    if (_usernameError != null) {
      _showSnack(_usernameError!);
      return;
    }
    if (email.isEmpty) {
      _showSnack('Email zorunlu');
      return;
    }
    final emailOk = RegExp(r'^\S+@\S+\.\S+$').hasMatch(email);
    if (!emailOk) {
      _showSnack('Geçerli bir email giriniz');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showSnack('Şifre en az 6 karakter olmalı');
      return;
    }

    setState(() => loading = true);

    try {
      // ✅ Submit anında username'i tekrar kontrol et (race condition fix)
      final stillOk = await SupabaseService.isUsernameAvailable(username);
      if (!stillOk) {
        _showSnack('Bu kullanıcı adı kullanımda.');
        return;
      }

      await SupabaseService.signUpWithProfile(
        email: email,
        password: password,
        username: username,
      );

      if (!mounted) return;

      // ✅ En garanti: stack’i temizle
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('user already') ||
          msg.contains('registered')) {
        _showSnack('Bu e-posta zaten kayıtlı.');
      } else {
        _showSnack('Kayıt hatası: ${e.message}');
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        _showSnack('Bu kullanıcı adı kullanımda.');
      } else {
        _showSnack(e.message.isNotEmpty ? e.message : 'Veritabanı hatası.');
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _usernameStatusIcon() {
    if (usernameCtrl.text.trim().isEmpty || _usernameError != null) {
      return const Icon(Icons.help_outline, size: 20);
    }
    if (_isAvailable == null) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_isAvailable == true) {
      return const Icon(Icons.check_circle_outline, size: 20);
    }
    return const Icon(Icons.error_outline, size: 20);
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      filled: true,
      fillColor: HexColor(lightPrimarColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: HexColor(raGreen)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: HexColor(raGreen)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: HexColor(raGreen)),
      ),
      hintText: hint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // ✅ ARKAPLAN TÜM SAYFAYI (buton dahil) KAPLAR
        Positioned.fill(
          child: Image.asset(
            "lib/assets/images/login01.png",
            fit: BoxFit.cover, // istersen BoxFit.fill yap
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,

          appBar: AppBar(
            backgroundColor: HexColor(lightSecondColor),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            centerTitle: true,
            title: Image.asset(
              "lib/assets/images/logo_text_transparan.png",
              height: 100,
            ),
          ),

          // ✅ Buton şeffaf alt bar içinde -> arkaplan görünür
          bottomNavigationBar: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  12,
                ), // ✅ bottomInset yok
                child: SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HexColor(raGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: loading ? null : _submit,
                    child: Text(
                      loading ? "Hesap Oluşturuluyor..." : "Hesap Oluştur",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: Text(
                    "Hesap Oluşturma",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),

                // USERNAME
                const Padding(
                  padding: EdgeInsets.fromLTRB(35, 10, 0, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Kullanıcı Adı"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        controller: usernameCtrl,
                        decoration: _fieldDecoration(hint: 'kullanici_adi'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _usernameStatusIcon(),
                      ),
                    ],
                  ),
                ),
                if (_usernameError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(35, 0, 30, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _usernameError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),

                // EMAIL
                const Padding(
                  padding: EdgeInsets.fromLTRB(35, 10, 0, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("E-mail"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
                  child: TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _fieldDecoration(hint: 'name@example.com'),
                  ),
                ),

                // PASSWORD
                const Padding(
                  padding: EdgeInsets.fromLTRB(35, 10, 0, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Şifre"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
                  child: TextField(
                    controller: pswrdCtrl,
                    obscureText: true,
                    decoration: _fieldDecoration(hint: '••••••'),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
