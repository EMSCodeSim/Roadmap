import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/services/theme.dart';

class PortalShellPage extends StatelessWidget {
  final Widget child;
  const PortalShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 980;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Row(
        children: [
          if (useRail) const _PortalNavRail(),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(left: BorderSide(color: cs.outline.withValues(alpha: 0.14))),
              ),
              child: child,
            ),
          ),
        ],
      ),
      drawer: useRail ? null : const Drawer(child: SafeArea(child: _PortalNavRail(asDrawer: true))),
    );
  }
}

class _PortalNavRail extends StatelessWidget {
  final bool asDrawer;
  const _PortalNavRail({this.asDrawer = false});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final selected = _selectedIndexFor(context);

    NavigationRailDestination destination({required IconData icon, required String label}) =>
        NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(icon), label: Text(label));

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.shield, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ResponderRoadmap', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                Text('Department Portal', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );

    final footer = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 14, backgroundColor: cs.primaryContainer, foregroundColor: cs.onPrimaryContainer, child: const Icon(Icons.person, size: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(portal.sessionUser?.name ?? 'Not signed in', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                        Text('${portal.activeDepartment?.name ?? '—'} • ${portal.sessionRole?.label ?? '—'}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () {
                      if (asDrawer) context.pop();
                      context.go('${AppRoutes.portal}/settings');
                    },
                    icon: Icon(Icons.settings, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final rail = NavigationRail(
      backgroundColor: cs.surface,
      selectedIndex: selected,
      onDestinationSelected: (index) {
        final dest = _PortalDest.values[index];
        if (asDrawer) context.pop();
        context.go(dest.path);
      },
      minWidth: 82,
      labelType: NavigationRailLabelType.all,
      destinations: [
        destination(icon: Icons.dashboard_outlined, label: 'Dashboard'),
        destination(icon: Icons.groups_outlined, label: 'Members'),
        destination(icon: Icons.menu_book_outlined, label: 'Task Books'),
        destination(icon: Icons.assignment_outlined, label: 'Assignments'),
        destination(icon: Icons.fact_check_outlined, label: 'Sign-Offs'),
        destination(icon: Icons.verified_outlined, label: 'Certs'),
        destination(icon: Icons.bar_chart_outlined, label: 'Reports'),
        destination(icon: Icons.apartment_outlined, label: 'Department'),
        destination(icon: Icons.tune_outlined, label: 'Settings'),
      ],
    );

    return Column(
      children: [
        header,
        Expanded(child: rail),
        footer,
      ],
    );
  }

  int _selectedIndexFor(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    for (final dest in _PortalDest.values) {
      if (loc == dest.path || loc.startsWith('${dest.path}/')) return dest.index;
    }
    return _PortalDest.dashboard.index;
  }
}

enum _PortalDest {
  dashboard('${AppRoutes.portal}/dashboard'),
  members('${AppRoutes.portal}/members'),
  taskBooks('${AppRoutes.portal}/task-books'),
  assignments('${AppRoutes.portal}/assignments'),
  signoffs('${AppRoutes.portal}/signoffs'),
  certifications('${AppRoutes.portal}/certifications'),
  reports('${AppRoutes.portal}/reports'),
  department('${AppRoutes.portal}/department'),
  settings('${AppRoutes.portal}/settings');

  final String path;
  const _PortalDest(this.path);
}
