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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mode = context.watch<AppModeController>();
    final inbox = context.watch<DepartmentInboxController>();

    return Scaffold(
      body: navigationShell,
      floatingActionButton: !mode.isDepartment && navigationShell.currentIndex == 0
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
          child: mode.isDepartment
              ? _DepartmentNavigation(
                  mode: mode,
                  inbox: inbox,
                  currentIndex: navigationShell.currentIndex,
                  onBranch: (index) => _go(context, index),
                )
              : BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: navigationShell.currentIndex,
                  onTap: (index) => _go(context, index),
                  selectedItemColor: cs.primary,
                  unselectedItemColor: cs.onSurfaceVariant,
                  selectedFontSize: 12,
                  unselectedFontSize: 12,
                  iconSize: 26,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.route_outlined), activeIcon: Icon(Icons.route), label: 'Task Book'),
                    BottomNavigationBarItem(icon: Icon(Icons.add_task_outlined), activeIcon: Icon(Icons.add_task), label: 'Log'),
                    BottomNavigationBarItem(icon: Icon(Icons.trending_up_outlined), activeIcon: Icon(Icons.trending_up), label: 'Advance'),
                    BottomNavigationBarItem(icon: Icon(Icons.verified_outlined), activeIcon: Icon(Icons.verified), label: 'Certs'),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DepartmentNavigation extends StatelessWidget {
  const _DepartmentNavigation({
    required this.mode,
    required this.inbox,
    required this.currentIndex,
    required this.onBranch,
  });

  final AppModeController mode;
  final DepartmentInboxController inbox;
  final int currentIndex;
  final ValueChanged<int> onBranch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final homeLabel = mode.isInstructor
        ? 'My Classes'
        : mode.isEvaluator
            ? 'Evaluations'
            : 'My Training';
    final workLabel = mode.isAdmin
        ? 'Admin'
        : mode.isInstructor
            ? 'Classes'
            : mode.isEvaluator
                ? 'Evaluations'
                : 'Updates';
    final workIcon = mode.isAdmin
        ? Icons.admin_panel_settings_outlined
        : mode.isInstructor
            ? Icons.class_outlined
            : mode.isEvaluator
                ? Icons.fact_check_outlined
                : Icons.notifications_outlined;

    // Department mode deliberately exposes only official department surfaces.
    // Personal Task Book, Log and Advance remain available after switching back
    // to Personal mode; they are not mixed into department navigation.
    final selected = currentIndex == 4 ? 2 : currentIndex == 3 ? 1 : 0;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selected,
      onTap: (index) {
        if (index == 0) onBranch(0);
        if (index == 1) onBranch(3);
        if (index == 2) onBranch(4);
      },
      selectedItemColor: cs.primary,
      unselectedItemColor: cs.onSurfaceVariant,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      iconSize: 26,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: homeLabel,
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: inbox.unreadCount > 0,
            label: Text('${inbox.unreadCount}'),
            child: Icon(workIcon),
          ),
          activeIcon: Icon(workIcon),
          label: workLabel,
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.verified_outlined),
          activeIcon: Icon(Icons.verified),
          label: 'Certificates',
        ),
      ],
    );
  }
}
