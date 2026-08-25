import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/advanced_certification_guide_data.dart';
import 'package:firepath/services/certification_guide_library.dart';
import 'package:firepath/services/state_fire_authority_catalog.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class QualificationTaskBookPage extends StatelessWidget {
  final Object? requirement;
  const QualificationTaskBookPage({super.key, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final req = requirement is Requirement ? requirement as Requirement : null;
    if (req == null) {
      return const Scaffold(body: Center(child: Text('Task book not found.')));
    }
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    final goalId = roadmap?.goal.id;
    if (goalId == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton.toTaskBook(),
          title: Text(req.name),
        ),
        body: Padding(padding: AppSpacing.paddingLg, child: _NoGoal()),
      );
    }

    final advancedGuide = AdvancedCertificationGuideData.forRequirement(req);
    final guide = CertificationGuideLibrary.guideForRequirement(req) ??
        (advancedGuide == null
            ? null
            : CertificationPathwayGuide(
                certificationId: advancedGuide.certificationId,
                title: advancedGuide.title,
                summary: advancedGuide.summary,
                pathwaySteps: advancedGuide.pathwaySteps,
                officialSourceNote: advancedGuide.officialSourceNote,
                tasks: advancedGuide.tasks,
              ));
    final base = TaskBookLibrary.tasksForRequirement(req);
    final guideTasks = guide?.tasks ?? const <TaskBookTaskDefinition>[];
    final custom = state.customTasksFor(goalId: goalId, requirementId: req.id);
    final tasks = [...base, ...guideTasks, ...custom];
    final grouped = <String, List<TaskBookTaskDefinition>>{};
    for (final t in tasks) {
      (grouped[t.section] ??= <TaskBookTaskDefinition>[]).add(t);
    }
    const sectionOrder = [
      'GETTING STARTED',
      'TRAINING',
      'PRACTICAL / JPR PREPARATION',
      'TESTING',
      'CERTIFICATION',
      'KNOWLEDGE',
      'APPARATUS OPERATIONS',
      'PERFORMANCE',
    ];
    final orderedSections = grouped.keys.toList()
      ..sort((a, b) {
        final ia = sectionOrder.indexOf(a);
        final ib = sectionOrder.indexOf(b);
        if (ia == -1 && ib == -1) return a.compareTo(b);
        if (ia == -1) return 1;
        if (ib == -1) return -1;
        return ia.compareTo(ib);
      });

    TaskBookTaskStatus statusFor(TaskBookTaskDefinition task) =>
        state.taskStatusFor(
          goalId: goalId,
          requirementId: req.id,
          taskId: task.id,
        );

    final completed = tasks
        .where((t) => statusFor(t) == TaskBookTaskStatus.complete)
        .length;
    final total = tasks.length;
    final pct = total <= 0
        ? 0.0
        : ((completed / total).clamp(0, 1) as num).toDouble();

    final stateCode = state.profile.state?.trim().toUpperCase();
    final authority = StateFireAuthorityCatalog.forState(stateCode);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toTaskBook(),
        title: Text(req.name.toUpperCase()),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Add task',
            onPressed: () => _addTask(context, goalId: goalId, req: req),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            if (guide != null) ...[
              _CertificationGuideCard(guide: guide),
              const SizedBox(height: AppSpacing.md),
            ],
            if (guide != null && authority != null) ...[
              _OfficialSourceCard(authority: authority),
              const SizedBox(height: AppSpacing.md),
            ],
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          guide == null
                              ? 'PREPARATION TASKS  •  ${(pct * 100).round()}% Complete'
                              : 'GET CERTIFIED  •  ${(pct * 100).round()}% Complete',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '$completed of $total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 10,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (guide != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Complete these preparation steps as you work through your official ${guide.title} process. Career Road progress is personal tracking, not certification approval.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...orderedSections.expand((section) {
              final items = grouped[section]!;
              final sectionComplete = items
                  .where((task) =>
                      statusFor(task) == TaskBookTaskStatus.complete)
                  .length;
              return [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        section,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    Text(
                      '$sectionComplete/${items.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...items.map(
                  (t) => _TaskTile(
                    goalId: goalId,
                    requirementId: req.id,
                    qualificationName: req.name,
                    task: t,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ];
            }).toList(),
            if (guide != null) ...[
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  guide.officialSourceNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.45,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addTask(
    BuildContext context, {
    required String goalId,
    required Requirement req,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final titleCtrl = TextEditingController();
    final sectionCtrl = TextEditingController(text: 'PERFORMANCE');
    final objectiveCtrl = TextEditingController();

    final created = await showModalBottomSheet<TaskBookTaskDefinition>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final insets = MediaQuery.viewInsetsOf(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.sm,
            bottom: insets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Task',
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Task title'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: sectionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Section (e.g., KNOWLEDGE)',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: objectiveCtrl,
                decoration: const InputDecoration(
                  labelText: 'Objective (optional)',
                  hintText: 'FireOps Preparation Task objective',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) {
                      sheetContext.pop();
                      return;
                    }
                    final now = DateTime.now();
                    final id =
                        'custom_${now.microsecondsSinceEpoch.toRadixString(36)}';
                    sheetContext.pop(
                      TaskBookTaskDefinition(
                        id: id,
                        title: title,
                        section: sectionCtrl.text.trim().isEmpty
                            ? 'PERFORMANCE'
                            : sectionCtrl.text.trim().toUpperCase(),
                        goalId: goalId,
                        requirementId: req.id,
                        isCustom: true,
                        fireOpsObjective: objectiveCtrl.text.trim().isEmpty
                            ? null
                            : objectiveCtrl.text.trim(),
                        whatToKnow: const [],
                        performanceTasks: const [],
                        safetyPoints: const [],
                        commonMistakes: const [],
                        practiceTools: const [],
                        resources: const [],
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
        );
      },
    );

    titleCtrl.dispose();
    sectionCtrl.dispose();
    objectiveCtrl.dispose();

    if (created == null) return;
    if (!context.mounted) return;
    await context.read<AppState>().addCustomTask(created);
  }
}

class _CertificationGuideCard extends StatelessWidget {
  final CertificationPathwayGuide guide;
  const _CertificationGuideCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, color: cs.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'HOW TO GET CERTIFIED',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            guide.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          ...guide.pathwaySteps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
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

class _OfficialSourceCard extends StatelessWidget {
  final StateFireAuthority authority;
  const _OfficialSourceCard({required this.authority});

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
          Text(
            'OFFICIAL ${authority.stateCode} SOURCE',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            authority.sourceTitle,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            authority.guidance,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(authority.sourceUrl);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open official certification source'),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String goalId;
  final String requirementId;
  final String qualificationName;
  final TaskBookTaskDefinition task;
  const _TaskTile({
    required this.goalId,
    required this.requirementId,
    required this.qualificationName,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final status = state.taskStatusFor(
      goalId: goalId,
      requirementId: requirementId,
      taskId: task.id,
    );

    final (icon, color) = switch (status) {
      TaskBookTaskStatus.complete => (
          Icons.check_circle,
          FireOpsSemanticColors.completed,
        ),
      TaskBookTaskStatus.readyForEvaluation => (
          Icons.verified_outlined,
          cs.primary,
        ),
      TaskBookTaskStatus.practicing => (
          Icons.play_circle_outline,
          cs.secondary,
        ),
      TaskBookTaskStatus.notStarted => (
          Icons.circle_outlined,
          cs.onSurfaceVariant,
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.taskDetail,
          extra: {
            'goalId': goalId,
            'requirementId': requirementId,
            'qualificationName': qualificationName,
            'task': task,
          },
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
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
                    Text(
                      task.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if ((task.fireOpsObjective ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.fireOpsObjective!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoGoal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      'Choose a career goal to build a Task Book.',
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: cs.onSurfaceVariant),
    );
  }
}
