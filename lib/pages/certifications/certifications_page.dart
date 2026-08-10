import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

enum _CertFilter { all, current, expiring, expired }

class CertificationsPage extends StatefulWidget {
  const CertificationsPage({super.key});

  @override
  State<CertificationsPage> createState() => _CertificationsPageState();
}

class _CertificationsPageState extends State<CertificationsPage> {
  _CertFilter _filter = _CertFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final certs = state.certifications;

    List<Certification> filtered() {
      switch (_filter) {
        case _CertFilter.current:
          return certs.where((c) => c.status == CertificationStatus.current).toList();
        case _CertFilter.expiring:
          return certs.where((c) => c.status == CertificationStatus.expiringSoon).toList();
        case _CertFilter.expired:
          return certs.where((c) => c.status == CertificationStatus.expired).toList();
        case _CertFilter.all:
          return certs;
      }
    }

    final list = filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certifications'),
        actions: [
          IconButton(
            tooltip: 'Add',
            onPressed: () => context.push(AppRoutes.certificationAdd),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.horizontalMd.add(const EdgeInsets.only(top: AppSpacing.sm)),
              child: SegmentedButton<_CertFilter>(
                segments: const [
                  ButtonSegment(value: _CertFilter.all, label: Text('All')),
                  ButtonSegment(value: _CertFilter.current, label: Text('Current')),
                  ButtonSegment(value: _CertFilter.expiring, label: Text('Expiring')),
                  ButtonSegment(value: _CertFilter.expired, label: Text('Expired')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Padding(
                        padding: AppSpacing.paddingLg,
                        child: Text('No certifications yet. Tap + to add one.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                    )
                  : ListView.builder(
                      padding: AppSpacing.paddingLg,
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final cert = list[i];
                        final status = cert.status;
                        final (label, color, icon) = switch (status) {
                          CertificationStatus.current => ('Current', FireOpsSemanticColors.completed, Icons.check_circle),
                          CertificationStatus.expiringSoon => ('Expiring Soon', FireOpsSemanticColors.warning, Icons.warning_amber_rounded),
                          CertificationStatus.expired => ('Expired', FireOpsSemanticColors.expired, Icons.cancel),
                        };

                        final expText = cert.doesNotExpire
                            ? 'Does not expire'
                            : cert.expirationDate == null
                                ? 'Expiration: —'
                                : 'Expires ${_formatDate(cert.expirationDate!)}';

                        final remaining = cert.daysRemaining;
                        final remainingText = remaining == null
                            ? null
                            : remaining < 0
                                ? '${remaining.abs()} days past'
                                : '$remaining days remaining';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InkWell(
                            onTap: () => context.push('${AppRoutes.certificationDetail}/${cert.id}'),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Container(
                              padding: AppSpacing.paddingMd,
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                              ),
                              child: Row(
                                children: [
                                  Icon(icon, color: color),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(state.certificationDisplayName(cert), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 2),
                                        Text(
                                          [label, expText, if (remainingText != null) remainingText].join(' • '),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.certificationAdd),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
