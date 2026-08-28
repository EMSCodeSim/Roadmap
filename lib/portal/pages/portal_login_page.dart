import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/calm_loading.dart';

class PortalLoginPage extends StatefulWidget {
  const PortalLoginPage({super.key});

  @override
  State<PortalLoginPage> createState() => _PortalLoginPageState();
}

class _PortalLoginPageState extends State<PortalLoginPage> {
  String? _selectedUserId;
  PortalRole _role = PortalRole.trainingOfficer;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final portal = context.watch<PortalController>();

    if (!portal.bootstrapped) {
      return const Scaffold(body: Center(child: CalmLoading(label: 'Loading portal…')));
    }

    final dept = portal.activeDepartment;
    final users = portal.departmentMembers;
    if (_selectedUserId == null || _selectedUserId!.isEmpty) {
      final preferred = users.where((u) => u.name == 'Sam Lee').toList();
      _selectedUserId = preferred.isNotEmpty
          ? preferred.first.id
          : (users.isEmpty ? null : users.first.id);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield, color: cs.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ResponderRoadmap Department Portal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(dept?.name ?? 'Department', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Demo sign-in', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: (_selectedUserId?.isEmpty ?? true) ? null : _selectedUserId,
                              items: users
                                  .map((u) => DropdownMenuItem(
                                        value: u.id,
                                        child: Text('${u.name} — ${u.rank ?? 'Member'}'),
                                      ))
                                  .toList(),
                              onChanged: _submitting ? null : (v) => setState(() => _selectedUserId = v),
                              decoration: const InputDecoration(labelText: 'User'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<PortalRole>(
                              value: _role,
                              items: PortalRole.values
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                                  .toList(),
                              onChanged: _submitting ? null : (v) => setState(() => _role = v ?? _role),
                              decoration: const InputDecoration(labelText: 'Role'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting
                            ? null
                            : () async {
                                final userId = _selectedUserId;
                                if (userId == null || userId.isEmpty) return;
                                setState(() => _submitting = true);
                                try {
                                  await portal.signInAs(userId: userId, role: _role);
                                  if (!context.mounted) return;
                                  context.go('${AppRoutes.portal}/dashboard');
                                } finally {
                                  if (mounted) setState(() => _submitting = false);
                                }
                              },
                        icon: const Icon(Icons.login),
                        label: Text(_submitting ? 'Signing in…' : 'Enter Portal'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'This portal runs in local demo mode (no backend connected).\n\nNext: Dashboard → Members → Alex Morgan → Assign Probationary Firefighter → Sign-Off queue.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
