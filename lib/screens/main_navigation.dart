import 'package:flutter/material.dart';
import 'home_page.dart';
import 'run_page.dart';
import 'map_page.dart';
import 'leaderboard_page.dart';
import 'profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    MapPage(),
    RunPage(),
    LeaderboardPage(),
    ProfilePage(),
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFF1A1A1A);
    const accent = Color(0xFF3B82F6);

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        color: headerColor,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(Icons.home_rounded, 'Home', 0, accent),
              navItem(Icons.map_rounded, 'Map', 1, accent),
              navItem(Icons.play_circle_fill_rounded, 'Run', 2, accent),
              navItem(Icons.emoji_events_rounded, 'Leaderboard', 3, accent),
              navItem(Icons.person_rounded, 'Profile', 4, accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, int index, Color accent) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? accent : Colors.white54,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accent : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}