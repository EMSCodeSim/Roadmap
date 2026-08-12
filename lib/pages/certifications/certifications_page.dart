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

class _CertSummaryHeader extends StatelessWidget {
  final int total;
  final int current;
  final int expiring;
  final int expired;
  final VoidCallback onAdd;

  const _CertSummaryHeader({required this.total, required this.current, required this.expiring, required this.expired, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$total Certifications', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('$current Current • $expiring Expiring • $expired Expired', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _CertEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Start your credential record', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: AppSpacing.sm),
        Text('Add the certifications you already hold and FireOps will help track renewals.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(height: 52, child: FilledButton(onPressed: onAdd, child: const Text('Add Certification'))),
      ],
    );
  }
}

class _CertificationsPageState extends State<CertificationsPage> {
  _CertFilter _filter = _CertFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final certs = state.certifications;

    final total = certs.length;
    final currentCount = certs.where((c) => c.status == CertificationStatus.current).length;
    final expiringCount = certs.where((c) => c.status == CertificationStatus.expiringSoon).length;
    final expiredCount = certs.where((c) => c.status == CertificationStatus.expired).length;

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
    final sorted = [...list]..sort((a, b) {
      int statusRank(Certification c) {
        return switch (c.status) {
          CertificationStatus.expired => 0,
          CertificationStatus.expiringSoon => 1,
          CertificationStatus.current => 2,
        };
      }

      final sr = statusRank(a).compareTo(statusRank(b));
      if (sr != 0) return sr;
      final ad = a.doesNotExpire ? null : a.expirationDate;
      final bd = b.doesNotExpire ? null : b.expirationDate;
      if (ad == null && bd != null) return 1;
      if (ad != null && bd == null) return -1;
      if (ad != null && bd != null) {
        final dr = ad.compareTo(bd);
        if (dr != 0) return dr;
      }
      return state.certificationDisplayName(a).compareTo(state.certificationDisplayName(b));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certifications'),
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
              child: _CertSummaryHeader(
                total: total,
                current: currentCount,
                expiring: expiringCount,
                expired: expiredCount,
                onAdd: () => context.push(AppRoutes.certificationAdd),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
              child: sorted.isEmpty
                  ? Center(
                      child: Padding(
                        padding: AppSpacing.paddingLg,
                        child: _CertEmptyState(onAdd: () => context.push(AppRoutes.certificationAdd)),
                      ),
                    )
                  : ListView.builder(
                      padding: AppSpacing.paddingLg,
                      itemCount: sorted.length,
                      itemBuilder: (context, i) {
                        final cert = sorted[i];
                        final status = cert.status;
                        final (label, color, icon) = switch (status) {
                          CertificationStatus.current => ('Current', FireOpsSemanticColors.completed, Icons.check_circle),
                          CertificationStatus.expiringSoon => ('Expiring Soon', FireOpsSemanticColors.warning, Icons.warning_amber_rounded),
                          CertificationStatus.expired => ('Expired', FireOpsSemanticColors.expired, Icons.cancel),
                        };

                        final expText = cert.doesNotExpire
                            ? 'Does not expire'
                            : cert.expirationDate == null
                                ? 'Expires —'
                                : 'Expires ${_formatDate(cert.expirationDate!)}';

                        final org = (cert.issuingOrganization ?? '').trim();

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
                                          [if (org.isNotEmpty) org, label, expText].join(' • '),
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
