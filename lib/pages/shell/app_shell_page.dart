import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellPage({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
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
            border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
          ),
          child: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (i) => _onTap(context, i),
            selectedItemColor: cs.primary,
            unselectedItemColor: cs.onSurfaceVariant,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.route), label: 'My Path'),
              BottomNavigationBarItem(icon: Icon(Icons.verified), label: 'Certifications'),
              BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Resources'),
            ],
          ),
        ),
      ),
    );
  }
}
