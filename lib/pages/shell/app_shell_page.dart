import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellPage({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
                top: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
            selectedItemColor: cs.primary,
            unselectedItemColor: cs.onSurfaceVariant,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.route_outlined),
                  activeIcon: Icon(Icons.route),
                  label: 'Roadmap'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.add_task_outlined),
                  activeIcon: Icon(Icons.add_task),
                  label: 'Log'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.trending_up_outlined),
                  activeIcon: Icon(Icons.trending_up),
                  label: 'Growth'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.verified_outlined),
                  activeIcon: Icon(Icons.verified),
                  label: 'Certs'),
            ],
          ),
        ),
      ),
    );
  }
}
