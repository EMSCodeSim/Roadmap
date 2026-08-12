import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/task_book_setup_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

/// Career Task Book (goal-level) view.
///
/// This is the replacement for the old "Roadmap" UI. It still uses the
/// existing roadmap computation internally, but presents it as an actionable
/// Task Book.
class TaskBookPage extends StatelessWidget {
  const TaskBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Book'),
        centerTitle: false,
        actions: [
          if (roadmap != null)
            IconButton(
              tooltip: 'Customize Task Book',
              onPressed: () => context.push(AppRoutes.myPathLegacy),
              icon: const Icon(Icons.tune),
            ),
        ],
      ),
      body: roadmap == null
          ? Padding(
              padding: AppSpacing.paddingLg,
              child: _NoGoalEmpty(
                  onChooseGoal: () => context.go(AppRoutes.goalSetup)),
            )
          : _TaskBookBody(roadmapGoalId: roadmap.goal.id),
    );
  }
}

class _TaskBookBody extends StatefulWidget {
  final String roadmapGoalId;
  const _TaskBookBody({required this.roadmapGoalId});

  @override
  State<_TaskBookBody> createState() => _TaskBookBodyState();
}

class _TaskBookBodyState extends State<_TaskBookBody> {
  final TaskBookSetupStore _setupStore = TaskBookSetupStore();
  bool _reviewPending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pending = await _setupStore.isReviewPending();
    if (!mounted) return;
    setState(() => _reviewPending = pending);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap!;
    final cs = Theme.of(context).colorScheme;

    final percent = (roadmap.percentComplete * 100).round();
    final target = state.profile.careerPlan.targetDate;

    final next = roadmap.nextStep?.requirement;

    final sections = _buildSections(roadmap.included);

    return SafeArea(
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          if (_reviewPending)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _StateChangedCard(
                fromLabel: FireOpsCatalog.stateNameForCode(state.profile.state) ?? 'your state',
                onReview: () => context.push(AppRoutes.taskBookReview),
                onNotNow: () async {
                  await _setupStore.setReviewPending(false);
                  if (!mounted) return;
                  setState(() => _reviewPending = false);
                },
              ),
            ),
          _GoalHeader(
            goalTitle: roadmap.goal.title,
            percent: percent,
            completed: roadmap.completedCount,
            total: roadmap.totalCount,
            targetDate: target,
          ),
          const SizedBox(height: AppSpacing.lg),
          _NextTaskCard(
            title: next?.name,
            onContinue: next == null
                ? null
                : () => _openRequirement(context, state, next),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _TaskBookSectionCard(
                  title: s.title,
                  items: s.items,
                  goalId: roadmap.goal.id,
                  defaultCollapsed: s.completedCount == s.items.length &&
                      s.items.isNotEmpty,
                  subtitle: s.subtitle,
                ),
              )),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'FireOps preparation tasks are designed to help organize training and professional development. Always verify certification and performance requirements with your department, state authority, official task book, or certifying organization.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  static void _openRequirement(
      BuildContext context, AppState state, Requirement r) {
    if (TaskBookLibrary.hasTasksForRequirement(r)) {
      context.push(AppRoutes.qualificationTaskBook,
          extra: {'requirement': r});
      return;
    }
    context.push(AppRoutes.requirementDetail, extra: r);
  }

  static List<_SectionDef> _buildSections(List<RoadmapRequirement> included) {
    final quals = <RoadmapRequirement>[];
    final experience = <RoadmapRequirement>[];
    final dept = <RoadmapRequirement>[];
    final promo = <RoadmapRequirement>[];

    for (final item in included) {
      final r = item.requirement;
      final isPromo = r.type == RequirementType.promotionalTest ||
          r.type == RequirementType.interview ||
          r.type == RequirementType.practical;
      final isExperience =
          r.type == RequirementType.experience || r.type == RequirementType.numericProgress;
      final isDept = r.requirementSource == RequirementSource.departmentRequirement ||
          r.priority == RequirementPriority.department;
      final isQualification = r.type == RequirementType.certification ||
          r.type == RequirementType.trainingCourse ||
          r.type == RequirementType.course ||
          r.type == RequirementType.education;

      if (isPromo) {
        promo.add(item);
      } else if (isExperience) {
        experience.add(item);
      } else if (isDept) {
        dept.add(item);
      } else if (isQualification) {
        quals.add(item);
      } else {
        // Default fallback: treat as qualification-like.
        quals.add(item);
      }
    }

    int completedCount(List<RoadmapRequirement> items) =>
        items.where((e) => e.isComplete).length;

    return [
      _SectionDef(
          title: 'QUALIFICATIONS',
          subtitle: 'Certifications, courses, and key credentials',
          items: quals,
          completedCount: completedCount(quals)),
      _SectionDef(
          title: 'EXPERIENCE',
          subtitle: 'Time-in-role, hours, and measurable progress',
          items: experience,
          completedCount: completedCount(experience)),
      _SectionDef(
          title: 'DEPARTMENT REQUIREMENTS',
          subtitle: 'Local SOP, department task books, and internal steps',
          items: dept,
          completedCount: completedCount(dept)),
      _SectionDef(
          title: 'PROMOTION PROCESS',
          subtitle: 'Written tests, practicals, interview prep',
          items: promo,
          completedCount: completedCount(promo)),
    ];
  }
}

class _SectionDef {
  final String title;
  final String subtitle;
  final List<RoadmapRequirement> items;
  final int completedCount;
  const _SectionDef(
      {required this.title,
      required this.subtitle,
      required this.items,
      required this.completedCount});
}

class _GoalHeader extends StatelessWidget {
  final String goalTitle;
  final int percent;
  final int completed;
  final int total;
  final DateTime? targetDate;

  const _GoalHeader(
      {required this.goalTitle,
      required this.percent,
      required this.completed,
      required this.total,
      required this.targetDate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CAREER TASK BOOK',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.xs),
          Text(goalTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text('$percent% Ready',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              if (targetDate != null)
                Text('Target: ${_fmtMonthYear(targetDate!)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          Text('$completed of $total requirements complete',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation(cs.primary),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtMonthYear(DateTime d) {
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
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _StateChangedCard extends StatelessWidget {
  final String fromLabel;
  final VoidCallback onReview;
  final VoidCallback onNotNow;
  const _StateChangedCard({
    required this.fromLabel,
    required this.onReview,
    required this.onNotNow,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: cs.tertiary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'STATE CHANGED',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your profile is now set to $fromLabel. State requirements may be different. Would you like Fire Career Roadmap to review your current Task Book?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurface, height: 1.45),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: onReview,
              child: const Text('Review Task Book'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: onNotNow,
              child: const Text('Not Now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextTaskCard extends StatelessWidget {
  final String? title;
  final VoidCallback? onContinue;
  const _NextTaskCard({required this.title, required this.onContinue});

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
          Text('NEXT TASK',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.xs),
          Text(title ?? 'You’re caught up',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg))),
              child: Text(title == null ? 'Review Task Book' : 'Continue Task'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskBookSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<RoadmapRequirement> items;
  final String goalId;
  final bool defaultCollapsed;

  const _TaskBookSectionCard(
      {required this.title,
      required this.subtitle,
      required this.items,
      required this.goalId,
      required this.defaultCollapsed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = items.where((e) => e.isComplete).length;
    final total = items.length;
    final pct =
        total <= 0 ? 0.0 : ((completed / total).clamp(0, 1) as num).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: !defaultCollapsed,
          tilePadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('$completed/$total',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurfaceVariant)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor:
                    cs.surfaceContainerHighest.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
          ),
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text('No items yet.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              )
            else
              ...items.map((item) => _RequirementRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final RoadmapRequirement item;
  const _RequirementRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final cs = Theme.of(context).colorScheme;
    final r = item.requirement;
    final icon = item.isComplete ? Icons.check_circle : Icons.circle_outlined;
    final color =
        item.isComplete ? FireOpsSemanticColors.completed : cs.onSurfaceVariant;

    String? trailing;
    if (r.type == RequirementType.numericProgress &&
        r.progressCurrent != null &&
        r.progressRequired != null) {
      final unit = r.progressUnit;
      trailing =
          '${r.progressCurrent!.toStringAsFixed(0)} / ${r.progressRequired!.toStringAsFixed(0)}${unit == null ? '' : ' $unit'}';
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: InkWell(
        onTap: () => _open(context, state, r),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      _sourceLine(context, r, state.profile.state),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 2),
                      Text(trailing,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
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
  }

  static void _open(BuildContext context, AppState state, Requirement r) {
    if (TaskBookLibrary.hasTasksForRequirement(r)) {
      context.push(AppRoutes.qualificationTaskBook,
          extra: {'requirement': r});
      return;
    }
    context.push(AppRoutes.requirementDetail, extra: r);
  }

  static String _sourceLine(BuildContext context, Requirement r, String? profileStateCode) {
    final stateName = FireOpsCatalog.stateNameForCode(r.sourceStateCode ?? profileStateCode);
    return switch (r.requirementSource) {
      RequirementSource.stateRequirement => stateName == null ? 'State requirement' : '$stateName requirement',
      RequirementSource.departmentRequirement => 'Department requirement',
      RequirementSource.commonlyRequired => r.stateDependent ? 'Commonly required • Verify with state/department' : 'Commonly required',
      RequirementSource.recommended => 'Recommended',
    };
  }
}

class _NoGoalEmpty extends StatelessWidget {
  final VoidCallback onChooseGoal;
  const _NoGoalEmpty({required this.onChooseGoal});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHOOSE YOUR NEXT CAREER GOAL',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'FireOps will build a Career Task Book showing the qualifications, experience, tasks, and development steps that can help you prepare.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
                onPressed: onChooseGoal, child: const Text('Choose Goal')),
          ),
        ],
      ),
    );
  }
}
