import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShellV2Page extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellV2Page({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Path'),
          NavigationDestination(icon: Icon(Icons.add_task_outlined), selectedIcon: Icon(Icons.add_task), label: 'Log'),
          NavigationDestination(icon: Icon(Icons.trending_up_outlined), selectedIcon: Icon(Icons.trending_up), label: 'Growth'),
          NavigationDestination(icon: Icon(Icons.verified_outlined), selectedIcon: Icon(Icons.verified), label: 'Certs'),
        ],
      ),
    );
  }
}
