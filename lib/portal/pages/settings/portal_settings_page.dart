import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/services/theme.dart';

class PortalSettingsPage extends StatelessWidget {
  const PortalSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;

    return PortalPageScaffold(
      title: 'Settings',
      subtitle: 'Portal session and demo data controls.',
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text('Signed in as: ${portal.sessionUser?.name ?? '—'}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text('Role: ${portal.sessionRole?.label ?? '—'}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          await portal.signOut();
                          if (!context.mounted) return;
                          context.go(AppRoutes.portalLogin);
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await portal.resetDemoData();
                          if (!context.mounted) return;
                          context.go(AppRoutes.portalLogin);
                        },
                        icon: Icon(Icons.restart_alt, color: cs.onSurface),
                        label: Text('Reset demo data', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
                      ),
                    ],
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
                  Text('Backend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    'No backend is connected yet. When you\'re ready, open the Firebase or Supabase panel in Dreamflow and complete setup — then we\'ll swap this portal store from local demo mode to a secure multi-tenant backend.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
