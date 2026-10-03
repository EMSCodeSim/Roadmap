import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/state/department_inbox_controller.dart';

/// The mobile app is personal-first:
/// Home = where I am, Roadmap = where I want to go/how to get there,
/// Log + Certifications = my evidence, Department = what my department needs from me.
class AppShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellPage({super.key, required this.navigationShell});

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inbox = context.watch<DepartmentInboxController>();
    final bottomPad = MediaQuery.paddingOf(context).bottom;

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
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              top: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPad == 0 ? 10 : 6),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _go,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route_rounded),
                  label: 'Roadmap',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.note_alt_outlined),
                  selectedIcon: Icon(Icons.note_alt_rounded),
                  label: 'Log',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.workspace_premium_outlined),
                  selectedIcon: Icon(Icons.workspace_premium_rounded),
                  label: 'Certificates',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: inbox.unreadCount > 0,
                    label: Text('${inbox.unreadCount}'),
                    child: const Icon(Icons.apartment_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: inbox.unreadCount > 0,
                    label: Text('${inbox.unreadCount}'),
                    child: const Icon(Icons.apartment_rounded),
                  ),
                  label: 'Department',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
