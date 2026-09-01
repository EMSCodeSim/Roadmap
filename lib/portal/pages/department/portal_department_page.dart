import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/status_pill.dart';

class PortalDepartmentPage extends StatelessWidget {
  const PortalDepartmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final dept = portal.activeDepartment;
    final members = portal.departmentMembers;

    return PortalPageScaffold(
      title: 'Department',
      subtitle: 'Department settings, roles, and membership (demo mode).',
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Department Profile', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatusPill(text: dept?.name ?? '—', icon: Icons.apartment, maxWidth: 340),
                      StatusPill(text: 'Code: ${dept?.joinCode ?? '—'}', icon: Icons.qr_code, maxWidth: 220),
                      StatusPill(text: dept?.timeZone ?? '—', icon: Icons.schedule, maxWidth: 240),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Privacy principle: Department participation never takes ownership of a member\'s personal career record. This portal only models department-managed data.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Roles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: PortalRole.values
                        .map((r) => StatusPill(text: r.label, icon: Icons.badge_outlined, maxWidth: 260))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Role-based permissions must be enforced server-side once a backend is connected. This demo mode focuses on UX and data model shape.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  ...members.map((m) {
                    final mem = portal.membershipFor(m.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 14, backgroundColor: cs.primaryContainer, foregroundColor: cs.onPrimaryContainer, child: Text(m.name.isEmpty ? '?' : m.name[0], style: const TextStyle(fontWeight: FontWeight.w900))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w900))),
                          StatusPill(text: mem?.role.label ?? '—', icon: Icons.badge_outlined, maxWidth: 200),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
