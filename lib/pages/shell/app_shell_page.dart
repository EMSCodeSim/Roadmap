import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/widgets/unread_pulse_indicator.dart';

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
class AppShellPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellPage({super.key, required this.navigationShell});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  static const _quickAddIntroSeenKey = 'fireops.quickAddIntroSeen.v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showQuickAddIntroIfNeeded();
    });
  }

  Future<void> _showQuickAddIntroIfNeeded() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_quickAddIntroSeenKey) ?? false) return;
      await prefs.setBool(_quickAddIntroSeenKey, true);
    } catch (error) {
      debugPrint('Quick Add introduction preference failed: $error');
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.add_circle_outline_rounded),
        title: const Text('Meet Quick Add'),
        content: const Text(
          'Tap the + button at the bottom of the screen to quickly add a '
          'career record, training, certification, or other activity. It is '
          'available from every main tab.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              QuickLogLauncher.open(context);
            },
            child: const Text('Try Quick Add'),
          ),
        ],
      ),
    );
  }

  void _go(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inbox = context.watch<DepartmentInboxController>();
    final unreadLabel = inbox.unreadCount > 99 ? '99+' : '${inbox.unreadCount}';
    final isTrainingSheetDetail = GoRouterState.of(context)
        .uri
        .path
        .startsWith('/department/training-sheets/');

    return Scaffold(
      body: widget.navigationShell,
      floatingActionButton: isTrainingSheetDetail
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: FloatingActionButton(
                key: const Key('quick_log_fab'),
                tooltip: 'Quick Add',
                backgroundColor: cs.secondary,
                foregroundColor: cs.onSecondary,
                elevation: 0,
                onPressed: () => QuickLogLauncher.open(context),
                child: const Icon(Icons.add_rounded),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: cs.primary,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: NavigationBar(
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: _go,
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
                label: 'Roadmap',
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
                  child: inbox.unreadCount > 0
                      ? const UnreadPulseIndicator(icon: Icons.apartment_outlined, size: 20)
                      : const Icon(Icons.apartment_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: inbox.unreadCount > 0,
                  label: Text(unreadLabel),
                  child: inbox.unreadCount > 0
                      ? const UnreadPulseIndicator(icon: Icons.apartment_rounded, size: 20)
                      : const Icon(Icons.apartment_rounded),
                ),
                label: 'Department',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
