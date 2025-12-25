import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:route_assistant/assets/constants/color.dart';
import 'package:route_assistant/services/supabase_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final pswrdCtrl = TextEditingController();

  bool loading = false;
  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      await SupabaseService.signIn(emailCtrl.text, pswrdCtrl.text);
      if (mounted)
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: HexColor(lightSecondColor),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back),
          ),
          centerTitle: true,
          title: Image.asset(
            "lib/assets/images/logo_text_transparan.png",
            height: 100,
          ),
        ),
        body: Container(
          width: deviceWidth,
          height: deviceHeight,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("lib/assets/images/login01.png"),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 20,
                ),
                child: Text(
                  "Giriş Yap",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green[800],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(35, 30, 0, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("E-mail", textAlign: TextAlign.left),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
                child: TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
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
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(35, 10, 0, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Şifre", textAlign: TextAlign.left),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
                child: TextField(
                  controller: pswrdCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
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
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FloatingActionButton.extended(
                heroTag: 'signInFab',
                onPressed: loading ? null : _submit,
                label: const Text(
                  'Giriş Yap',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Color(0xFF2E7D32), // yeşil ton
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
