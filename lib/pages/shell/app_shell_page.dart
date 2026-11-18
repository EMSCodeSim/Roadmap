import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/state/department_inbox_controller.dart';

/// Primary mobile shell.
///
/// Keep the navigation focused on the responder's core jobs:
/// - Home: what needs attention now
/// - Timeline: lifelong career history, with goals as a secondary tool
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
    const roadmapRed = Color(0xFFC8102E);
    final inbox = context.watch<DepartmentInboxController>();
    final unreadLabel = inbox.unreadCount > 99 ? '99+' : '${inbox.unreadCount}';
    final isTrainingSheetDetail = GoRouterState.of(context)
        .uri
        .path
        .startsWith('/department/training-sheets/');

    return Scaffold(
      body: navigationShell,
      floatingActionButton: isTrainingSheetDetail
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: FloatingActionButton(
                key: const Key('quick_log_fab'),
                tooltip: 'Log something now',
                onPressed: () => QuickLogLauncher.open(context),
                child: const Icon(Icons.add_rounded),
              ),
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
            padding: const EdgeInsets.only(bottom: 2),
            child: NavigationBar(
              backgroundColor: cs.surface,
              indicatorColor: roadmapRed.withValues(alpha: 0.10),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _go,
              height: 64,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.timeline_outlined),
                  selectedIcon: Icon(Icons.timeline_rounded),
                  label: 'Timeline',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.folder_copy_outlined),
                  selectedIcon: Icon(Icons.folder_copy_rounded),
                  label: 'Records',
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
