import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/timeline_planner.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    final roles = state.profile.currentRoles;
    final currentLine = roles.isEmpty ? 'Set your current role' : roles.join(' / ');

    final certs = state.certifications;
    final currentCount = certs.where((c) => c.status == CertificationStatus.current).length;
    final expiringCount = certs.where((c) => c.status == CertificationStatus.expiringSoon).length;
    final expiredCount = certs.where((c) => c.status == CertificationStatus.expired).length;

    final timelinePlan = roadmap == null ? null : CareerTimelinePlanner.build(state);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            _TopHeader(title: 'FireOps Path', subtitle: 'Your Fire Service Career Roadmap'),
            const SizedBox(height: AppSpacing.lg),
            if (roadmap == null) ...[
              _EmptyHome(onChooseGoal: () => context.go(AppRoutes.onboarding)),
              const SizedBox(height: AppSpacing.md),
              _CertSummaryCard(
                current: currentCount,
                expiring: expiringCount,
                expired: expiredCount,
                onTap: () => context.go(AppRoutes.certifications),
              ),
              const SizedBox(height: AppSpacing.xl),
            ] else ...[
              _CurrentGoalHeader(
                currentLine: currentLine,
                goalTitle: roadmap.goal.title,
                targetReadyDate: timelinePlan?.targetReadyDate,
                timelineStatus: timelinePlan?.status ?? TimelineStatus.noTargetDate,
                progressLabel: '${roadmap.completedCount} of ${roadmap.totalCount} requirements complete',
                progressValue: roadmap.percentComplete,
                onTapGoal: () => context.go(AppRoutes.myPath),
              ),
              const SizedBox(height: AppSpacing.md),
              _NextStepCard(
                nextStepTitle: roadmap.nextStep?.requirement.name ?? 'You’re all caught up!',
                nextStepSubtitle: roadmap.nextStep == null ? null : _whyNextStep(roadmap, roadmap.nextStep!.requirement),
                requirement: roadmap.nextStep?.requirement,
                onTap: roadmap.nextStep == null ? null : () => context.push(AppRoutes.requirementDetail, extra: roadmap.nextStep!.requirement),
                primaryCta: roadmap.nextStep == null ? 'VIEW MY PATH' : _ctaLabelFor(state, roadmap, roadmap.nextStep!.requirement),
                primaryAction: () => roadmap.nextStep == null ? context.go(AppRoutes.myPath) : _ctaAction(context, state, roadmap.nextStep!.requirement),
                onWhyThisNext: roadmap.nextStep == null ? null : () => _showWhyNext(context, state, roadmap, roadmap.nextStep!.requirement),
              ),
              const SizedBox(height: AppSpacing.md),
              _CurrentlyWorkingOnSection(roadmap: roadmap),
              const SizedBox(height: AppSpacing.md),
              _UpcomingTrainingSection(roadmap: roadmap),
              const SizedBox(height: AppSpacing.md),
              _CertAlertCard(certifications: certs, onTap: () => context.go(AppRoutes.certifications)),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }

  static String _whyNextStep(Roadmap roadmap, Requirement r) {
    final goalName = roadmap.goal.title;
    final prereqs = r.prerequisiteRequirementIds;
    final prereqsOk = prereqs.isEmpty
        ? null
        : prereqs.every((p) => roadmap.included.any((e) => (e.requirement.certificationReference ?? e.requirement.name).toLowerCase() == p.toLowerCase() && e.isComplete));
    final reason = switch (r.requirementSource) {
      RequirementSource.commonlyRequired => 'a core item on your $goalName path',
      RequirementSource.recommended => 'a recommended item on your $goalName path',
      RequirementSource.stateRequirement => 'a state-dependent item on your $goalName path',
      RequirementSource.departmentRequirement => 'a department-dependent item on your $goalName path',
    };
    if (prereqsOk == true) return 'Recommended next because it is $reason and you have the common prerequisites complete.';
    if (prereqsOk == false) return 'Recommended next because it is $reason. Complete prerequisites first to stay on track.';
    return 'Recommended next because it is $reason.';
  }

  static String _ctaLabelFor(AppState state, Roadmap roadmap, Requirement r) {
    if (r.type == RequirementType.certification) {
      final cert = state.certifications.where((c) => c.name.trim().toLowerCase() == r.name.trim().toLowerCase()).firstOrNull;
      if (cert != null && cert.status == CertificationStatus.expired) return 'RENEW';
      return 'GET STARTED';
    }
    final status = state.activityStatusFor(goalId: roadmap.goal.id, requirementId: r.id);
    if (status == RequirementActivityStatus.scheduled) return 'VIEW TRAINING';
    if (status == RequirementActivityStatus.inProgress) return 'CONTINUE';
    if (r.type == RequirementType.experience) return 'LOG HOURS';
    if (r.type == RequirementType.taskBook) return 'UPDATE PROGRESS';
    if (r.type == RequirementType.numericProgress) return 'ADD HOURS';
    return 'GET STARTED';
  }

  static VoidCallback _ctaAction(BuildContext context, AppState state, Requirement r) {
    final road = state.roadmap;
    if (road == null) return () {};
    final status = state.activityStatusFor(goalId: road.goal.id, requirementId: r.id);
    if (status == RequirementActivityStatus.scheduled) {
      return () => context.push(AppRoutes.requirementDetail, extra: r);
    }
    if (r.type == RequirementType.numericProgress || r.type == RequirementType.taskBook) {
      return () => context.push(AppRoutes.requirementDetail, extra: r);
    }
    return () => context.push(AppRoutes.getStarted, extra: r);
  }

  static Future<void> _showWhyNext(BuildContext context, AppState state, Roadmap roadmap, Requirement r) async {
    final text = _whyNextStep(roadmap, r);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why this next?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.sm),
              Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(height: 52, width: double.infinity, child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it'))),
            ],
          ),
        );
      },
    );
  }
}

extension _FirstOrNullCert<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _CurrentGoalHeader extends StatelessWidget {
  final String currentLine;
  final String goalTitle;
  final DateTime? targetReadyDate;
  final TimelineStatus timelineStatus;
  final String progressLabel;
  final double progressValue;
  final VoidCallback onTapGoal;

  const _CurrentGoalHeader({
    required this.currentLine,
    required this.goalTitle,
    required this.targetReadyDate,
    required this.timelineStatus,
    required this.progressLabel,
    required this.progressValue,
    required this.onTapGoal,
  });

  static String _fmtMonthYear(DateTime d) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[d.month - 1]} ${d.year}';
  }

  static String _statusLabel(TimelineStatus s) {
    return switch (s) {
      TimelineStatus.onTrack => 'On Track',
      TimelineStatus.needsAttention => 'Needs Attention',
      TimelineStatus.atRisk => 'At Risk',
      TimelineStatus.noTargetDate => 'No Target Date',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dotColor = switch (timelineStatus) {
      TimelineStatus.onTrack => FireOpsSemanticColors.completed,
      TimelineStatus.needsAttention => FireOpsSemanticColors.warning,
      TimelineStatus.atRisk => FireOpsSemanticColors.expired,
      TimelineStatus.noTargetDate => cs.onSurfaceVariant,
    };
    final targetLine = targetReadyDate == null ? 'No Target Date' : 'Target Ready: ${_fmtMonthYear(targetReadyDate!)}';
    return InkWell(
      onTap: onTapGoal,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('MY GOAL', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900))),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: dotColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(99))),
                      const SizedBox(width: 8),
                      Text(_statusLabel(timelineStatus).toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: dotColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(goalTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(targetLine, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            Text('CURRENT', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(currentLine, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
            const SizedBox(height: AppSpacing.sm),
            Text(progressLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progressValue.clamp(0, 1),
                backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation(cs.primary),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentlyWorkingOnSection extends StatelessWidget {
  final Roadmap roadmap;
  const _CurrentlyWorkingOnSection({required this.roadmap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    final list = roadmap.included.where((e) {
      if (e.isComplete) return false;
      final s = state.activityStatusFor(goalId: roadmap.goal.id, requirementId: e.requirement.id);
      return s == RequirementActivityStatus.planning || s == RequirementActivityStatus.scheduled || s == RequirementActivityStatus.inProgress;
    }).toList();

    int rank(RequirementActivityStatus s) {
      return switch (s) {
        RequirementActivityStatus.scheduled => 0,
        RequirementActivityStatus.inProgress => 1,
        RequirementActivityStatus.planning => 2,
        RequirementActivityStatus.notStarted => 99,
      };
    }

    list.sort((a, b) {
      final sa = state.activityStatusFor(goalId: roadmap.goal.id, requirementId: a.requirement.id);
      final sb = state.activityStatusFor(goalId: roadmap.goal.id, requirementId: b.requirement.id);
      final r = rank(sa).compareTo(rank(sb));
      if (r != 0) return r;
      return a.requirement.sortOrder.compareTo(b.requirement.sortOrder);
    });

    if (list.isEmpty) return const SizedBox.shrink();

    final top = list.take(3).toList();
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.playlist_add_check, color: cs.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text('CURRENTLY WORKING ON', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
              const Spacer(),
              TextButton(onPressed: () => context.go(AppRoutes.myPath), child: const Text('View all')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...top.map((e) {
            final s = state.activityStatusFor(goalId: roadmap.goal.id, requirementId: e.requirement.id);
            final label = switch (s) {
              RequirementActivityStatus.planning => 'Planning',
              RequirementActivityStatus.scheduled => 'Scheduled',
              RequirementActivityStatus.inProgress => 'In progress',
              RequirementActivityStatus.notStarted => 'Not started',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.push(AppRoutes.requirementDetail, extra: e.requirement),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: cs.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(e.requirement.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _UpcomingTrainingSection extends StatelessWidget {
  final Roadmap roadmap;
  const _UpcomingTrainingSection({required this.roadmap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final scheduled = <(Requirement req, TrainingSchedule schedule)>[];
    for (final e in roadmap.included) {
      final s = state.activityStatusFor(goalId: roadmap.goal.id, requirementId: e.requirement.id);
      if (s != RequirementActivityStatus.scheduled) continue;
      final sched = state.scheduleFor(goalId: roadmap.goal.id, requirementId: e.requirement.id);
      final start = sched?.startDate;
      if (sched == null || start == null) continue;
      if (start.isBefore(today)) continue;
      scheduled.add((e.requirement, sched));
    }
    scheduled.sort((a, b) => a.$2.startDate!.compareTo(b.$2.startDate!));
    if (scheduled.isEmpty) return const SizedBox.shrink();

    final first = scheduled.first;
    final start = first.$2.startDate!;
    final dateLabel = _formatDate(start);

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(
        children: [
          Icon(Icons.event, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UPCOMING TRAINING', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(first.$1.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('${dateLabel}${(first.$2.provider ?? '').trim().isEmpty ? '' : ' • ${first.$2.provider}'}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => context.push(AppRoutes.requirementDetail, extra: first.$1),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TopHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [FireOpsSemanticColors.headerDark, cs.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: cs.onSecondary, fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSecondary.withValues(alpha: 0.9), height: 1.5)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String goalTitle;
  final String? progressLabel;
  final double? progressValue;
  final VoidCallback onTap;

  const _GoalCard({required this.goalTitle, required this.progressLabel, required this.progressValue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Text('MY GOAL', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                const Spacer(),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('🎯 $goalTitle', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            if (progressLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(progressLabel!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (progressValue ?? 0).clamp(0, 1),
                  backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                  minHeight: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  final String nextStepTitle;
  final String? nextStepSubtitle;
  final Requirement? requirement;
  final VoidCallback? onTap;
  final String primaryCta;
  final VoidCallback primaryAction;
  final VoidCallback? onWhyThisNext;

  const _NextStepCard({required this.nextStepTitle, required this.nextStepSubtitle, required this.requirement, required this.onTap, required this.primaryCta, required this.primaryAction, required this.onWhyThisNext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: cs.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('YOUR NEXT STEP', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(nextStepTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            ),
          ),
          if (nextStepSubtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(nextStepSubtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.88), height: 1.5)),
          ],
          if (onWhyThisNext != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onWhyThisNext,
                style: TextButton.styleFrom(foregroundColor: cs.primary, padding: EdgeInsets.zero),
                child: const Text('Why this next?'),
              ),
            ),
          ],
          if (requirement?.type == RequirementType.numericProgress && requirement?.progressRequired != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InlineProgress(current: requirement!.progressCurrent ?? 0, required: requirement!.progressRequired ?? 0, unit: requirement!.progressUnit),
          ],
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: primaryAction,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
              child: Text(primaryCta),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineProgress extends StatelessWidget {
  final double current;
  final double required;
  final String? unit;
  const _InlineProgress({required this.current, required this.required, required this.unit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final u = unit ?? '';
    final progress = required <= 0 ? 0.0 : ((current / required).clamp(0, 1) as num).toDouble();
    final remaining = (((required - current).clamp(0, double.infinity)) as num).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${current.toStringAsFixed(0)} / ${required.toStringAsFixed(0)}${u.isEmpty ? '' : ' $u'}', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6), valueColor: AlwaysStoppedAnimation(cs.primary)),
          ),
          const SizedBox(height: 6),
          Text('${remaining.toStringAsFixed(0)} remaining', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  final VoidCallback onChooseGoal;
  const _EmptyHome({required this.onChooseGoal});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where do you want to go next?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          Text('Choose a fire-service career goal and FireOps Path will build a roadmap.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: onChooseGoal,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
              child: const Text('Choose My Goal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertAlertCard extends StatelessWidget {
  final List<Certification> certifications;
  final VoidCallback onTap;
  const _CertAlertCard({required this.certifications, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expiring = certifications.where((c) => c.status == CertificationStatus.expiringSoon).toList();
    expiring.sort((a, b) {
      final ad = a.expirationDate ?? DateTime(2100);
      final bd = b.expirationDate ?? DateTime(2100);
      return ad.compareTo(bd);
    });
    final expired = certifications.where((c) => c.status == CertificationStatus.expired).toList();
    expired.sort((a, b) {
      final ad = a.expirationDate ?? DateTime(2100);
      final bd = b.expirationDate ?? DateTime(2100);
      return ad.compareTo(bd);
    });

    final primary = (expired.isNotEmpty) ? expired.first : (expiring.isNotEmpty ? expiring.first : null);

    final label = primary == null
        ? 'No certification alerts'
        : primary.status == CertificationStatus.expired
            ? '⚠️ ${primary.name} is expired'
            : _expiringLabel(primary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Row(
          children: [
            Icon(primary == null ? Icons.check_circle : Icons.warning_amber_rounded, color: primary == null ? FireOpsSemanticColors.completed : FireOpsSemanticColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CERTIFICATION ALERTS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  static String _expiringLabel(Certification c) {
    final exp = c.expirationDate;
    if (exp == null) return '⚠️ ${c.name} expiring soon';
    final now = DateTime.now();
    final days = exp.difference(DateTime(now.year, now.month, now.day)).inDays;
    return '⚠️ ${c.name} expires in $days days';
  }
}

class _MiniPathCard extends StatelessWidget {
  final Roadmap roadmap;
  final VoidCallback onTap;
  const _MiniPathCard({required this.roadmap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = roadmap.included.take(4).toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Text('MY PATH', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                const Spacer(),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...items.map((r) {
              final icon = r.isComplete ? Icons.check_circle : Icons.circle_outlined;
              final color = r.isComplete ? FireOpsSemanticColors.completed : cs.onSurfaceVariant;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(r.requirement.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.25), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CertSummaryCard extends StatelessWidget {
  final int current;
  final int expiring;
  final int expired;
  final VoidCallback onTap;

  const _CertSummaryCard({required this.current, required this.expiring, required this.expired, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Text('CERTIFICATIONS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                const Spacer(),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                _Pill(icon: Icons.check_circle, label: '$current Current', color: FireOpsSemanticColors.completed),
                _Pill(icon: Icons.warning_amber_rounded, label: '$expiring Expiring Soon', color: FireOpsSemanticColors.warning),
                _Pill(icon: Icons.cancel, label: '$expired Expired', color: FireOpsSemanticColors.expired),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
