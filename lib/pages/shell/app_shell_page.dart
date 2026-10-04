import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/state/department_inbox_controller.dart';

/// Primary mobile shell.
///
/// Keep the navigation focused on the responder's core jobs:
/// - Home: what needs attention now
/// - My Roadmap: personal progression and next requirements
/// - Record: durable personal evidence and activity history
/// - Credentials: licenses/certifications and expiration upkeep
/// - Department: official assignments, evaluations, and department work
///
/// Quick Add is intentionally available from every primary tab so field capture
/// never depends on navigating back to Home first.
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
    final unreadLabel = inbox.unreadCount > 99 ? '99+' : '${inbox.unreadCount}';

    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        key: const Key('quick_log_fab'),
        tooltip: 'Quick Add',
        onPressed: () => QuickLogLauncher.open(context),
        child: const Icon(Icons.add_rounded),
      ),
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
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route_rounded),
                  label: 'My Roadmap',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.note_alt_outlined),
                  selectedIcon: Icon(Icons.note_alt_rounded),
                  label: 'Record',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.workspace_premium_outlined),
                  selectedIcon: Icon(Icons.workspace_premium_rounded),
                  label: 'Credentials',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: inbox.unreadCount > 0,
                    label: Text(unreadLabel),
                    child: const Icon(Icons.apartment_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: inbox.unreadCount > 0,
                    label: Text(unreadLabel),
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
