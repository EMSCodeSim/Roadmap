import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';
import 'package:firepath/widgets/certification_renewal_tile.dart';
import 'package:firepath/widgets/calm_empty_state.dart';

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

  const _CertSummaryHeader({
    required this.total,
    required this.current,
    required this.expiring,
    required this.expired,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: AppCardTokens.padding,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total Certs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$current Current • $expiring Expiring • $expired Expired',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add cert'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCardTokens.radius)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _CertEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return CalmEmptyState(
      icon: Icons.verified_outlined,
      title: 'Start your cert record',
      message: 'Add the certs you already hold. We’ll track renewals and keep your Task Book accurate.',
      primaryAction: SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add cert'),
        ),
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  final _CertFilter filter;
  final VoidCallback onShowAll;

  const _FilteredEmptyState({
    required this.filter,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (title, detail, icon) = switch (filter) {
      _CertFilter.current => (
          'No current certifications',
          'Add certs you currently hold to track renewals.',
          Icons.verified_outlined,
        ),
      _CertFilter.expiring => (
          'Nothing expiring soon',
          'No tracked certifications expire within the next 90 days.',
          Icons.event_available_outlined,
        ),
      _CertFilter.expired => (
          'No expired certifications',
          'Good to go — no expired certs on file.',
          Icons.check_circle_outline,
        ),
      _CertFilter.all => (
          'No certifications found',
          'Try another filter or clear your search.',
          Icons.search_off_outlined,
        ),
    };

    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: cs.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onShowAll,
              child: const Text('Show all certs'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertMatchBanner extends StatelessWidget {
  final int count;
  final VoidCallback onReview;

  const _CertMatchBanner({
    required this.count,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.tertiaryContainer.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(AppCardTokens.radius),
      child: InkWell(
        onTap: onReview,
        borderRadius: BorderRadius.circular(AppCardTokens.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.rule_outlined, color: cs.onTertiaryContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? '1 certification match needs review'
                          : '$count certification matches need review',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: cs.onTertiaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Confirm matches so your credentials count correctly toward roadmap requirements.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onTertiaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, color: cs.onTertiaryContainer),
            ],
          ),
        ),
      ),
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
    final currentCount = certs
        .where((c) => c.status == CertificationStatus.current)
        .length;
    final expiringCount = certs
        .where((c) => c.status == CertificationStatus.expiringSoon)
        .length;
    final expiredCount = certs
        .where((c) => c.status == CertificationStatus.expired)
        .length;

    List<Certification> filtered() {
      switch (_filter) {
        case _CertFilter.current:
          return certs
              .where((c) => c.status == CertificationStatus.current)
              .toList();
        case _CertFilter.expiring:
          return certs
              .where((c) => c.status == CertificationStatus.expiringSoon)
              .toList();
        case _CertFilter.expired:
          return certs
              .where((c) => c.status == CertificationStatus.expired)
              .toList();
        case _CertFilter.all:
          return certs;
      }
    }

    final sorted = [...filtered()]..sort((a, b) {
        int statusRank(Certification c) {
          return switch (c.status) {
            CertificationStatus.expired => 0,
            CertificationStatus.expiringSoon => 1,
            CertificationStatus.current => 2,
          };
        }

        final statusComparison = statusRank(a).compareTo(statusRank(b));
        if (statusComparison != 0) return statusComparison;

        final aDate = a.doesNotExpire ? null : a.expirationDate;
        final bDate = b.doesNotExpire ? null : b.expirationDate;
        if (aDate == null && bDate != null) return 1;
        if (aDate != null && bDate == null) return -1;
        if (aDate != null && bDate != null) {
          final dateComparison = aDate.compareTo(bDate);
          if (dateComparison != 0) return dateComparison;
        }
        return state
            .certificationDisplayName(a)
            .compareTo(state.certificationDisplayName(b));
      });

    return Scaffold(
      appBar: const FirefighterRoadmapAppBar(subtitle: 'Certs'),
      body: SafeArea(
        child: total == 0
            ? Center(
                child: SingleChildScrollView(
                  padding: AppSpacing.paddingLg,
                  child: _CertEmptyState(
                    onAdd: () => context.push(AppRoutes.certificationAdd),
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: AppSpacing.horizontalMd.add(
                      const EdgeInsets.only(top: AppSpacing.sm),
                    ),
                    child: _CertSummaryHeader(
                      total: total,
                      current: currentCount,
                      expiring: expiringCount,
                      expired: expiredCount,
                      onAdd: () => context.push(AppRoutes.certificationAdd),
                    ),
                  ),
                  if (state.pendingCertMatches.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: AppSpacing.horizontalMd,
                      child: _CertMatchBanner(
                        count: state.pendingCertMatches.length,
                        onReview: () => _showCertMatchSheet(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 44,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: AppSpacing.horizontalMd,
                      child: SegmentedButton<_CertFilter>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: _CertFilter.all,
                            label: Text('All'),
                          ),
                          ButtonSegment(
                            value: _CertFilter.current,
                            label: Text('Current'),
                          ),
                          ButtonSegment(
                            value: _CertFilter.expiring,
                            label: Text('Expiring'),
                          ),
                          ButtonSegment(
                            value: _CertFilter.expired,
                            label: Text('Expired'),
                          ),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (selection) {
                          setState(() => _filter = selection.first);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: sorted.isEmpty
                        ? _FilteredEmptyState(
                            filter: _filter,
                            onShowAll: () {
                              setState(() => _filter = _CertFilter.all);
                            },
                          )
                        : ListView.builder(
                            padding: AppSpacing.paddingLg,
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
                              final cert = sorted[index];

                              final displayName =
                                  state.certificationDisplayName(cert);

                              final expirationText = cert.doesNotExpire
                                  ? 'Does not expire'
                                  : cert.expirationDate == null
                                      ? 'No expiration date'
                                      : 'Expires ${_formatDate(cert.expirationDate!)}';

                              final isUrgent = cert.status !=
                                  CertificationStatus.current;

                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: isUrgent
                                    ? CertificationRenewalTile.fromCert(
                                        cert: cert,
                                        displayName: displayName,
                                        onOpen: () => context.push(
                                          '${AppRoutes.certificationDetail}/${cert.id}',
                                        ),
                                        onRenew: () => context.push(
                                          '${AppRoutes.certificationDetail}/${cert.id}',
                                          extra: const {
                                            'focus': 'renewal',
                                          },
                                        ),
                                      )
                                    : InkWell(
                                        onTap: () => context.push(
                                          '${AppRoutes.certificationDetail}/${cert.id}',
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.lg),
                                        child: Container(
                                          padding: AppSpacing.paddingMd,
                                          decoration: BoxDecoration(
                                            color: cs.surface,
                                            borderRadius:
                                                BorderRadius.circular(AppRadius.lg),
                                            border: Border.all(
                                              color: cs.outline
                                                  .withValues(alpha: 0.14),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color:
                                                    FireOpsSemanticColors.completed,
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.md),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      displayName,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      expirationText,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: cs
                                                                .onSurfaceVariant,
                                                            height: 1.35,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.sm),
                                              Icon(Icons.chevron_right,
                                                  color: cs.onSurfaceVariant),
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
    );
  }

  Future<void> _showCertMatchSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer<AppState>(
          builder: (sheetContext, state, _) {
            final matches = state.pendingCertMatches;
            final definitions = FireOpsCatalog.certificationById();

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.86,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Review certification matches',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Confirm how your cert names match the catalog. This helps your Task Book auto-satisfy what you already have.',
                        style: Theme.of(sheetContext).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: matches.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 48,
                                      color: Theme.of(sheetContext)
                                          .colorScheme
                                          .primary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'All matches reviewed',
                                      style: Theme.of(sheetContext)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: matches.length,
                                itemBuilder: (context, index) {
                                  final match = matches[index];
                                  final suggested = definitions[
                                      match.suggestedDefinitionId];

                                  return Card(
                                    margin:
                                        const EdgeInsets.only(bottom: 10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            match.userText,
                                            style: Theme.of(sheetContext)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Suggested match: ${suggested?.displayName ?? match.suggestedDefinitionId}',
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () async {
                                                    await state
                                                        .confirmCertificationMatch(
                                                      userText: match.userText,
                                                      suggestedDefinitionId: match
                                                          .suggestedDefinitionId,
                                                      accepted: false,
                                                    );
                                                  },
                                                  child:
                                                      const Text('Not a match'),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: FilledButton(
                                                  onPressed: () async {
                                                    await state
                                                        .confirmCertificationMatch(
                                                      userText: match.userText,
                                                      suggestedDefinitionId: match
                                                          .suggestedDefinitionId,
                                                      accepted: true,
                                                    );
                                                  },
                                                  child: const Text('Confirm'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 50,
                        child: FilledButton.tonal(
                          onPressed: () => sheetContext.pop(),
                          child: Text(matches.isEmpty ? 'Done' : 'Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
