import 'package:flutter/material.dart';

// 🔹 Alt barın tema ayarları
class AppNavigationTheme {
  static NavigationBarThemeData theme = NavigationBarThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 6,
    indicatorColor: Colors.transparent, // M3 “pill” efekti kapalı
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final isSelected = states.contains(WidgetState.selected);
      return IconThemeData(
        size: 22,
        color: isSelected ? const Color(0xFF2EB872) : Colors.black87,
      );
    }),
  );
}

class NavDestinationSpec {
  final IconData icon;
  final String label;

  const NavDestinationSpec({required this.icon, required this.label});
}

class NavScaffold extends StatefulWidget {
  final List<Widget> pages;
  final List<NavDestinationSpec> destination;
  final int initialIndex;

  const NavScaffold({
    super.key,
    required this.pages,
    required this.destination,
    this.initialIndex = 0,
  }) : assert(pages.length == destination.length);

  @override
  State<NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends State<NavScaffold> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(navigationBarTheme: AppNavigationTheme.theme),
      child: Scaffold(
        body: IndexedStack(index: index, children: widget.pages),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1, thickness: 1, color: Color(0x11000000)),
            SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => setState(() => index = i),
                destinations: widget.destination
                    .map(
                      (d) => NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.icon),
                        label: d.label,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
