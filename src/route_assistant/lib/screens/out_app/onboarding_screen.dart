// lib/screens/out_app/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:route_assistant/assets/constants/color.dart';
import 'package:route_assistant/screens/out_app/login_page.dart';
import 'package:route_assistant/screens/out_app/register_page.dart';
import 'package:route_assistant/services/auth_service.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;

    return Scaffold(
      backgroundColor: HexColor(lightPrimarColor),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/assets/images/login01.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üst kısım: logo + textler
                  Column(
                    children: [
                      Text(
                        "Welcome to",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                      SizedBox(
                        height: height * 0.25,
                        child: Image.asset(
                          "lib/assets/images/logo_transparan.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                      Text(
                        "We are millions of members exploring and sharing great outdoor trails",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: HexColor(lightTextColor),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.04),

                  // Already member? Login
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Zaten üye misin?  "),
                          Text(
                            "Giriş Yap",
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Hesap Oluştur",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Google butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue[400],
                        foregroundColor: HexColor(lightTextColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await AuthService.signInWithGoogle(
                            forceAccountPicker: true,
                          );
                          if (!context.mounted) return;

                          Navigator.pushReplacementNamed(context, '/home');
                        } catch (e) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Google hata: $e")),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "lib/assets/icons/google_logo.png",
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Google ile Kayıt Ol",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Mail butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HexColor(raGreen),
                        foregroundColor: HexColor(lightTextColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "lib/assets/icons/mail_logo.png",
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Mail ile Kayıt Ol",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
