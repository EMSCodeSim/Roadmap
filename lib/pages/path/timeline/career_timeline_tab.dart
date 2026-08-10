import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/timeline_planner.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class CareerTimelineTab extends StatelessWidget {
  const CareerTimelineTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    if (roadmap == null) return const SizedBox.shrink();

    final plan = CareerTimelinePlanner.build(state);
    final target = plan?.targetReadyDate;

    if (plan == null || target == null || plan.status == TimelineStatus.noTargetDate) {
      return SafeArea(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: _TimelineEmpty(
            onAddTarget: () async {
              final picked = await _pickTargetReadyDate(context, initial: state.profile.careerPlan.targetDate);
              if (picked == null) return;
              await context.read<AppState>().setTargetReadyDate(picked);
              if (!context.mounted) return;
              await _maybeShowAggressiveTargetNotice(context);
            },
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          _TimelineHeader(
            goalTitle: plan.goalTitle,
            target: target,
            status: plan.status,
            progressLabel: '${roadmap.completedCount} / ${roadmap.totalCount} complete',
            progressValue: roadmap.percentComplete,
            onEditTarget: () async {
              final picked = await _pickTargetReadyDate(context, initial: target);
              if (picked == null) return;
              await context.read<AppState>().setTargetReadyDate(picked);
              if (!context.mounted) return;
              await _maybeShowAggressiveTargetNotice(context);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          _ThisMonthCard(
            item: plan.thisMonthFocus,
            onOpen: plan.thisMonthFocus?.requirement == null ? null : () => context.push(AppRoutes.getStarted, extra: plan.thisMonthFocus!.requirement!),
          ),
          const SizedBox(height: AppSpacing.md),

          _ThisYearCard(
            year: DateTime.now().year,
            priorities: plan.thisYearPriorities,
            onTapItem: (item) {
              final r = item.requirement;
              if (r == null) return;
              context.push(AppRoutes.requirementDetail, extra: r);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('CAREER TIMELINE', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),

          ...plan.sections.expand((section) {
            if (section.items.isEmpty && section.hint != null && section.title == plan.goalTitle.toUpperCase()) {
              return [const SizedBox.shrink()];
            }
            return [
              _TimelineSection(section: section, onTap: (item) {
                if (item.kind == TimelineItemKind.renewal) {
                  context.go(AppRoutes.certifications);
                  return;
                }
                if (item.requirement != null) context.push(AppRoutes.requirementDetail, extra: item.requirement!);
              }),
              const SizedBox(height: AppSpacing.md),
            ];
          }),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  final String goalTitle;
  final DateTime target;
  final TimelineStatus status;
  final String progressLabel;
  final double progressValue;
  final VoidCallback onEditTarget;

  const _TimelineHeader({
    required this.goalTitle,
    required this.target,
    required this.status,
    required this.progressLabel,
    required this.progressValue,
    required this.onEditTarget,
  });

  static String _fmtMonthYear(DateTime d) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (pillBg, pillFg) = _statusColors(status, cs);
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(goalTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(99)),
                child: Text(_statusLabel(status).toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: pillFg)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.event, color: cs.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Target Ready: ${_fmtMonthYear(target)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
              TextButton(onPressed: onEditTarget, child: const Text('Edit Target Date')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('PATH PROGRESS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(progressLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0, 1),
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation(cs.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Timeline status is a planning estimate (not a guarantee of promotion/hiring/appointment).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(TimelineStatus s) {
    return switch (s) {
      TimelineStatus.onTrack => 'On Track',
      TimelineStatus.needsAttention => 'Needs Attention',
      TimelineStatus.atRisk => 'At Risk',
      TimelineStatus.noTargetDate => 'No Target Date',
    };
  }

  static (Color bg, Color fg) _statusColors(TimelineStatus s, ColorScheme cs) {
    switch (s) {
      case TimelineStatus.onTrack:
        return (FireOpsSemanticColors.completed.withValues(alpha: 0.14), FireOpsSemanticColors.completed);
      case TimelineStatus.needsAttention:
        return (FireOpsSemanticColors.warning.withValues(alpha: 0.16), FireOpsSemanticColors.warning);
      case TimelineStatus.atRisk:
        return (FireOpsSemanticColors.expired.withValues(alpha: 0.14), FireOpsSemanticColors.expired);
      case TimelineStatus.noTargetDate:
        return (cs.surfaceContainerHighest.withValues(alpha: 0.6), cs.onSurfaceVariant);
    }
  }
}

class _ThisYearCard extends StatelessWidget {
  final int year;
  final List<TimelineItem> priorities;
  final ValueChanged<TimelineItem> onTapItem;
  const _ThisYearCard({required this.year, required this.priorities, required this.onTapItem});

  @override
  Widget build(BuildContext context) {
    if (priorities.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: cs.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Text('THIS YEAR', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
              const Spacer(),
              Text('$year', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...priorities.take(5).toList().asMap().entries.map((e) {
            final idx = e.key + 1;
            final item = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onTapItem(item),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                        child: Text('$idx', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(item.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ThisMonthCard extends StatelessWidget {
  final TimelineItem? item;
  final VoidCallback? onOpen;
  const _ThisMonthCard({required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (item == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.primary.withValues(alpha: 0.18))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Text('THIS MONTH', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onPrimaryContainer)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item!.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.onPrimaryContainer)),
          if ((item!.subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item!.subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.9), height: 1.4)),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
              child: const Text('Open Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final TimelineSection section;
  final ValueChanged<TimelineItem> onTap;
  const _TimelineSection({required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (section.items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(section.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant))),
              if (section.hint != null) Text(section.hint!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...section.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onTap(item),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.kind == TimelineItemKind.target
                            ? Icons.flag
                            : item.kind == TimelineItemKind.renewal
                                ? Icons.warning_amber
                                : item.isNextStep
                                    ? Icons.bolt
                                    : Icons.chevron_right,
                        color: item.kind == TimelineItemKind.renewal ? FireOpsSemanticColors.warning : cs.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                            if ((item.subtitle ?? '').isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(item.subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                            ],
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
          }),
        ],
      ),
    );
  }
}

class _TimelineEmpty extends StatelessWidget {
  final VoidCallback onAddTarget;
  const _TimelineEmpty({required this.onAddTarget});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BUILD YOUR CAREER TIMELINE', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "You're already tracking what you need. Add a target ready date and FireOps Path can help organize when to work on each step.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: onAddTarget,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
              child: const Text('ADD TARGET DATE'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
              child: const Text('Not Now'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<DateTime?> _pickTargetReadyDate(BuildContext context, {required DateTime? initial}) async {
  final cs = Theme.of(context).colorScheme;
  final result = await showModalBottomSheet<DateTime?>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      Widget option({required String title, required String subtitle, required VoidCallback onTap, required IconData icon}) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
              child: Row(
                children: [
                  Icon(icon, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      DateTime withinYears(int years) {
        final now = DateTime.now();
        return DateTime(now.year + years, now.month, 1);
      }

      Future<void> chooseDate() async {
        Navigator.of(context).pop();
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial ?? now.add(const Duration(days: 365)),
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: DateTime(now.year + 10),
          helpText: 'Target Ready Date',
        );
        if (picked == null) return;
        if (!context.mounted) return;
        context.pop(DateTime(picked.year, picked.month, 1));
      }

      return Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('WHEN DO YOU WANT TO BE READY?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.xs),
            Text('Career readiness goal — not a promotion prediction.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: AppSpacing.md),
            option(
              title: 'No Target Date',
              subtitle: 'Timeline planning stays optional.',
              icon: Icons.do_not_disturb_on,
              onTap: () => context.pop(null),
            ),
            option(title: 'Within 1 Year', subtitle: 'Focused near-term readiness plan.', icon: Icons.looks_one, onTap: () => context.pop(withinYears(1))),
            option(title: 'Within 2 Years', subtitle: 'Balanced timeline with scheduling room.', icon: Icons.looks_two, onTap: () => context.pop(withinYears(2))),
            option(title: 'Within 3 Years', subtitle: 'Longer runway for experience + task books.', icon: Icons.looks_3, onTap: () => context.pop(withinYears(3))),
            option(title: 'Choose Date', subtitle: 'Pick a specific month/year.', icon: Icons.event, onTap: chooseDate),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
  return result;
}

Future<void> _maybeShowAggressiveTargetNotice(BuildContext context) async {
  final state = context.read<AppState>();
  final status = CareerTimelinePlanner.estimateStatus(state);
  if (status == TimelineStatus.onTrack || status == TimelineStatus.noTargetDate) return;

  final cs = Theme.of(context).colorScheme;
  final title = status == TimelineStatus.atRisk ? 'AT RISK' : 'NEEDS ATTENTION';
  final body = status == TimelineStatus.atRisk
      ? 'Your target ready date may be aggressive based on prerequisites, scheduled training, and remaining work. This is a planning estimate — not a guarantee.'
      : 'Some items may need to be started soon to comfortably reach your target ready date. This is a planning estimate — not a guarantee.';

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: status == TimelineStatus.atRisk ? FireOpsSemanticColors.expired : FireOpsSemanticColors.warning)),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
              child: const Text('Keep Target Date'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final picked = await _pickTargetReadyDate(context, initial: state.profile.careerPlan.targetDate);
                if (picked == null) return;
                await context.read<AppState>().setTargetReadyDate(picked);
              },
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
              child: const Text('Change Target Date'),
            ),
          ],
        ),
      );
    },
  );
}
