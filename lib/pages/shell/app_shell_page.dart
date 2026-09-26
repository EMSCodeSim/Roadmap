import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/department_inbox_controller.dart';

class AppShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellPage({super.key, required this.navigationShell});

  void _go(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  int _selectedIndex(AppModeController mode) {
    if (navigationShell.currentIndex == 0) return 0;
    if (mode.isDepartment) {
      if (navigationShell.currentIndex == 4) return 2;
      return 1;
    }
    if (navigationShell.currentIndex == 1) return 1;
    return 2;
  }

  void _select(AppModeController mode, int index) {
    if (index == 0) return _go(navigationShell.context, 0);
    if (index == 1) return _go(navigationShell.context, mode.isDepartment ? 3 : 1);
    _go(navigationShell.context, mode.isDepartment ? 4 : 3);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mode = context.watch<AppModeController>();
    final inbox = context.watch<DepartmentInboxController>();
    final selected = _selectedIndex(mode);

    return Scaffold(
      body: navigationShell,
      floatingActionButton: !mode.isDepartment && selected == 0
          ? FloatingActionButton(
              key: const Key('quick_log_fab'),
              tooltip: 'Quick Log',
              onPressed: () => QuickLogLauncher.open(context),
              child: const Icon(Icons.add_task_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.14))),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: selected,
            onTap: (index) => _select(mode, index),
            selectedItemColor: cs.primary,
            unselectedItemColor: cs.onSurfaceVariant,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            iconSize: 26,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: mode.isDepartment && inbox.unreadCount > 0,
                  label: Text('${inbox.unreadCount}'),
                  child: const Icon(Icons.assignment_outlined),
                ),
                activeIcon: const Icon(Icons.assignment),
                label: 'Training',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
