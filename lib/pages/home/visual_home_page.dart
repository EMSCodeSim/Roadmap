import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/state/app_state.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    final profile = state.profile;
    final certs = state.certifications;

    final currentLevel = profile.currentRoles.isEmpty
        ? 'Set your current level'
        : profile.currentRoles.join(' / ');

    final currentCount = certs
        .where((cert) => cert.status == CertificationStatus.current)
        .length;
    final expiringCount = certs
        .where((cert) => cert.status == CertificationStatus.expiringSoon)
        .length;
    final expiredCount = certs
        .where((cert) => cert.status == CertificationStatus.expired)
        .length;

    final datedCerts = certs
        .where((cert) => !cert.doesNotExpire && cert.expirationDate != null)
        .toList()
      ..sort((a, b) => a.expirationDate!.compareTo(b.expirationDate!));
    final nextExpiration = datedCerts
        .where((cert) => !cert.expirationDate!.isBefore(DateTime.now()))
        .firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            const _GraphicHeader(),
            const SizedBox(height: 14),
            _CurrentLevelCard(
              level: currentLevel,
              serviceType: profile.serviceType,
              yearsOfService: profile.yearsOfService,
            ),
            const SizedBox(height: 12),
            _GoalCard(
              goalTitle: roadmap?.goal.title,
              targetDate: profile.careerPlan.targetDate,
              completed: roadmap?.completedCount ?? 0,
              total: roadmap?.totalCount ?? 0,
              nextStep: roadmap?.nextStep?.requirement.name,
              onTap: () => context.go(AppRoutes.myPath),
            ),
            const SizedBox(height: 12),
            _CertificationsCard(
              total: certs.length,
              current: currentCount,
              expiring: expiringCount,
              expired: expiredCount,
              nextExpirationName: nextExpiration == null
                  ? null
                  : state.certificationDisplayName(nextExpiration),
              nextExpirationDate: nextExpiration?.expirationDate,
              pendingMatches: state.pendingCertMatches.length,
              onTap: () => context.go(AppRoutes.certifications),
              onReviewMatches: state.pendingCertMatches.isEmpty
                  ? null
                  : () => _showCertMatchSheet(context, state),
            ),
            const SizedBox(height: 12),
            _PersonalLogCard(
              onTap: () => context.go(AppRoutes.personalLog),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showCertMatchSheet(
    BuildContext context,
    AppState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final matches = state.pendingCertMatches;
        final defs = FireOpsCatalog.certificationById();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Review certification matches',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Confirm these so your certifications count correctly toward your career goal.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ...matches.map((match) {
                  final suggested = defs[match.suggestedDefinitionId];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.userText,
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Match to: ${suggested?.displayName ?? match.suggestedDefinitionId}',
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await state.confirmCertificationMatch(
                                      userText: match.userText,
                                      suggestedDefinitionId:
                                          match.suggestedDefinitionId,
                                      accepted: false,
                                    );
                                    if (sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                  },
                                  child: const Text('Not a match'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () async {
                                    await state.confirmCertificationMatch(
                                      userText: match.userText,
                                      suggestedDefinitionId:
                                          match.suggestedDefinitionId,
                                      accepted: true,
                                    );
                                    if (sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
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
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _GraphicHeader extends StatelessWidget {
  const _GraphicHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      minHeight: 126,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF071A33),
            cs.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/icons/career_road_icon.png',
              width: 82,
              height: 82,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'FireOps Career Road',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your career. Your progress. Your record.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentLevelCard extends StatelessWidget {
  final String level;
  final String? serviceType;
  final int? yearsOfService;

  const _CurrentLevelCard({
    required this.level,
    required this.serviceType,
    required this.yearsOfService,
  });

  @override
  Widget build(BuildContext context) {
    final detailParts = <String>[
      if (serviceType != null && serviceType!.trim().isNotEmpty) serviceType!,
      if (yearsOfService != null)
        '$yearsOfService ${yearsOfService == 1 ? 'year' : 'years'} of service',
    ];

    return _HomeCard(
      icon: Icons.badge_outlined,
      eyebrow: 'CURRENT LEVEL',
      title: level,
      subtitle: detailParts.isEmpty
          ? 'Your current fire/EMS role and experience level.'
          : detailParts.join(' • '),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String? goalTitle;
  final DateTime? targetDate;
  final int completed;
  final int total;
  final String? nextStep;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goalTitle,
    required this.targetDate,
    required this.completed,
    required this.total,
    required this.nextStep,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasGoal = goalTitle != null;
    final progress = total == 0 ? 0.0 : completed / total;
    return _HomeCard(
      icon: Icons.flag_outlined,
      eyebrow: 'GOAL',
      title: hasGoal ? goalTitle! : 'Choose your next career goal',
      subtitle: hasGoal
          ? [
              if (targetDate != null) 'Target ${_formatMonthYear(targetDate!)}',
              '$completed of $total requirements complete',
            ].join(' • ')
          : 'Build a roadmap for the position or specialty you want next.',
      detail: hasGoal && nextStep != null ? 'Next: $nextStep' : null,
      progress: hasGoal ? progress : null,
      actionLabel: hasGoal ? 'Open Roadmap' : 'Build My Path',
      onTap: onTap,
    );
  }
}

class _CertificationsCard extends StatelessWidget {
  final int total;
  final int current;
  final int expiring;
  final int expired;
  final String? nextExpirationName;
  final DateTime? nextExpirationDate;
  final int pendingMatches;
  final VoidCallback onTap;
  final VoidCallback? onReviewMatches;

  const _CertificationsCard({
    required this.total,
    required this.current,
    required this.expiring,
    required this.expired,
    required this.nextExpirationName,
    required this.nextExpirationDate,
    required this.pendingMatches,
    required this.onTap,
    required this.onReviewMatches,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _HomeCard(
      icon: Icons.verified_outlined,
      eyebrow: 'CERTIFICATIONS',
      title: total == 0
          ? 'No certifications added yet'
          : '$total certifications tracked',
      subtitle: 'Current $current • Expiring $expiring • Expired $expired',
      detail: nextExpirationName == null || nextExpirationDate == null
          ? 'Track certifications and expiration dates in one place.'
          : 'Next expiration: $nextExpirationName • ${_formatDate(nextExpirationDate!)}',
      actionLabel: 'View Certifications',
      onTap: onTap,
      footer: pendingMatches == 0
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: InkWell(
                onTap: onReviewMatches,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.rule_outlined,
                        size: 18,
                        color: cs.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$pendingMatches certification ${pendingMatches == 1 ? 'match needs' : 'matches need'} review',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: cs.onTertiaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _PersonalLogCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PersonalLogCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      icon: Icons.add_task_outlined,
      eyebrow: 'PERSONAL LOG',
      title: 'Build your career history as you go',
      subtitle:
          'Calls • Skills • Trainings • Awards • Leadership • Achievements',
      detail:
          'Use the daily logger for quick entries, then add detail when an experience may matter later.',
      actionLabel: 'Open Daily Logger',
      onTap: onTap,
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? detail;
  final double? progress;
  final String? actionLabel;
  final VoidCallback? onTap;
  final Widget? footer;

  const _HomeCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.detail,
    this.progress,
    this.actionLabel,
    this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
          ],
          if (footer != null) footer!,
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            Text(
              actionLabel!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: card,
    );
  }
}

String _formatMonthYear(DateTime date) {
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
  return '${months[date.month - 1]} ${date.year}';
}

String _formatDate(DateTime date) {
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
