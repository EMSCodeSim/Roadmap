import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/services/theme.dart';

class PortalReportsPage extends StatelessWidget {
  const PortalReportsPage({super.key});

  void _showNotReady(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming next'),
        content: Text(message),
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;

    return PortalPageScaffold(
      title: 'Reports',
      subtitle: 'Focused compliance and readiness reports (no “chart spam”).',
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Task Book Progress', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('In MVP demo mode, reports share the same local data as the dashboard.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _showNotReady(context, 'Task Book Progress report table will be implemented next.'),
                        icon: const Icon(Icons.table_view),
                        label: const Text('View table'),
                      ),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.file_download),
                        label: const Text('Export (later)'),
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
                  Text('Certification Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('Use the Certifications screen for operational filtering. Exports will appear here later.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _showNotReady(context, 'Certification Status report table will be implemented next.'),
                        icon: const Icon(Icons.table_view),
                        label: const Text('View table'),
                      ),
                      OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.print), label: const Text('Print/PDF (later)')),
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
              child: Text(
                'Department: ${portal.activeDepartment?.name ?? '—'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
