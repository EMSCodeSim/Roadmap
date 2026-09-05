import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/department_inbox_controller.dart';

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
    final mode = context.watch<AppModeController>();
    final inbox = context.watch<DepartmentInboxController>();
    final elevatedRole = mode.role == 'TRAINING_OFFICER' ||
        mode.role == 'DEPARTMENT_ADMINISTRATOR';
    final fourthLabel = mode.isDepartment
        ? elevatedRole
            ? 'Admin'
            : mode.canReview
                ? 'Review'
                : 'Department'
        : 'Advance';
    return Scaffold(
      body: navigationShell,
      floatingActionButton: navigationShell.currentIndex == 0
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
            border: Border(
              top: BorderSide(color: cs.outline.withValues(alpha: 0.14)),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: navigationShell.currentIndex,
              onTap: _onTap,
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
                const BottomNavigationBarItem(
                  icon: Icon(Icons.route_outlined),
                  activeIcon: Icon(Icons.route),
                  label: 'Task Book',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.add_task_outlined),
                  activeIcon: Icon(Icons.add_task),
                  label: 'Log',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: mode.isDepartment && inbox.unreadCount > 0,
                    label: Text('${inbox.unreadCount}'),
                    child: Icon(mode.isDepartment
                        ? mode.canReview
                            ? Icons.fact_check_outlined
                            : Icons.apartment_outlined
                        : Icons.trending_up_outlined),
                  ),
                  activeIcon: Icon(mode.isDepartment
                      ? mode.canReview
                          ? Icons.fact_check_rounded
                          : Icons.apartment_rounded
                      : Icons.trending_up),
                  label: fourthLabel,
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.verified_outlined),
                  activeIcon: Icon(Icons.verified),
                  label: 'Certs',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
