import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:route_assistant/assets/constants/color.dart';
import 'package:route_assistant/screens/in_app/home_wrapper.dart';
import 'package:route_assistant/screens/in_app/notification_screens.dart';
import 'package:route_assistant/screens/in_app/trail_detail/trail_detail_screen.dart';

import 'package:route_assistant/screens/out_app/onboarding_screen.dart';
import 'package:route_assistant/screens/out_app/register_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:route_assistant/screens/in_app/my_route_section.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Route Assistant",
      theme: ThemeData(colorSchemeSeed: HexColor(raGreen), useMaterial3: true),

      home: const AuthGate(),

      routes: {
        '/home': (_) => const HomeWrapper(),
        '/explore': (_) => const HomeWrapper(),
        '/trailDetail': (_) => const TrailDetailScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/myRoutes': (_) => const MyRoutesScreen(),
        '/register': (_) => const RegisterPage(),
      },
    );
  }
}

/// Session varsa HomeWrapper, yoksa Onboarding
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = client.auth.currentSession;

        // ilk açılışta kısa loading normal
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session != null) {
          return const HomeWrapper();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}
