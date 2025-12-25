// lib/screens/in_app/home_wrapper.dart
import 'package:flutter/cupertino.dart';
import 'package:route_assistant/screens/in_app/explore_screen.dart';
import 'package:route_assistant/screens/in_app/nearby/map_nearby_screen.dart';
import 'package:route_assistant/screens/in_app/profile_screen.dart';
import 'package:route_assistant/screens/in_app/trail_screen.dart';
import 'package:route_assistant/screens/in_app/message_screen.dart'; // ✅ NEW
import 'package:route_assistant/screens/widget/navigation_bar.dart';

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return NavScaffold(
      pages: const [
        ExploreScreen(),
        TrailScreen(),
        MapNearbyScreen(),
        MessagesScreen(),
        ProfileScreen(),
      ],
      destination: const [
        NavDestinationSpec(icon: CupertinoIcons.globe, label: "Keşfet"),
        NavDestinationSpec(icon: CupertinoIcons.compass, label: "Rota"),
        NavDestinationSpec(icon: CupertinoIcons.map, label: "Harita"),
        NavDestinationSpec(
          icon: CupertinoIcons.chat_bubble_2,
          label: "Mesajlar",
        ),
        NavDestinationSpec(icon: CupertinoIcons.person, label: "Profil"),
      ],
    );
  }
}
