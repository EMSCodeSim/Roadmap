import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/nav.dart';
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
        appBar: AppBar(title: Text(req.name)),
        body: Padding(
          padding: AppSpacing.paddingLg,
          child: _NoGoal(),
        ),
      );
    }

    final base = TaskBookLibrary.tasksForRequirement(req);
    final custom = state.customTasksFor(goalId: goalId, requirementId: req.id);
    final tasks = [...base, ...custom];
    final grouped = <String, List<TaskBookTaskDefinition>>{};
    for (final t in tasks) {
      (grouped[t.section] ??= <TaskBookTaskDefinition>[]).add(t);
    }
    final sectionOrder = ['KNOWLEDGE', 'APPARATUS OPERATIONS', 'PERFORMANCE'];
    final orderedSections = grouped.keys.toList()
      ..sort((a, b) {
        final ia = sectionOrder.indexOf(a);
        final ib = sectionOrder.indexOf(b);
        if (ia == -1 && ib == -1) return a.compareTo(b);
        if (ia == -1) return 1;
        if (ib == -1) return -1;
        return ia.compareTo(ib);
      });

    int completedCount() => tasks
        .where((t) =>
            state.taskStatusFor(
                goalId: goalId, requirementId: req.id, taskId: t.id) ==
            TaskBookTaskStatus.complete)
        .length;

    final completed = completedCount();
    final total = tasks.length;
    final pct =
        total <= 0 ? 0.0 : ((completed / total).clamp(0, 1) as num).toDouble();

    return Scaffold(
      appBar: AppBar(
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
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${(pct * 100).round()}% Complete',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      Text('$completed of $total tasks',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
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
                          Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...orderedSections.expand((section) {
              final items = grouped[section]!..sort((a, b) => a.title.compareTo(b.title));
              return [
                Text(section,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                ...items.map((t) => _TaskTile(goalId: goalId, requirementId: req.id, qualificationName: req.name, task: t)),
                const SizedBox(height: AppSpacing.lg),
              ];
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _addTask(BuildContext context,
      {required String goalId, required Requirement req}) async {
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
              bottom: insets.bottom + AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Task',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Task title')),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: sectionCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Section (e.g., KNOWLEDGE)')),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: objectiveCtrl,
                decoration: const InputDecoration(
                    labelText: 'Objective (optional)',
                    hintText: 'FireOps Preparation Task objective'),
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
                          borderRadius: BorderRadius.circular(AppRadius.lg))),
                  child: const Text('Add Task'),
                ),
              )
            ],
          ),
        );
      },
    );

    titleCtrl.dispose();
    sectionCtrl.dispose();
    objectiveCtrl.dispose();

    if (created == null) return;
    await context.read<AppState>().addCustomTask(created);
  }
}

class _TaskTile extends StatelessWidget {
  final String goalId;
  final String requirementId;
  final String qualificationName;
  final TaskBookTaskDefinition task;
  const _TaskTile(
      {required this.goalId,
      required this.requirementId,
      required this.qualificationName,
      required this.task});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final status = state.taskStatusFor(
        goalId: goalId, requirementId: requirementId, taskId: task.id);

    final (icon, color) = switch (status) {
      TaskBookTaskStatus.complete =>
        (Icons.check_circle, FireOpsSemanticColors.completed),
      TaskBookTaskStatus.readyForEvaluation => (Icons.verified_outlined, cs.primary),
      TaskBookTaskStatus.practicing => (Icons.play_circle_outline, cs.secondary),
      TaskBookTaskStatus.notStarted => (Icons.circle_outlined, cs.onSurfaceVariant),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.push(AppRoutes.taskDetail, extra: {
          'goalId': goalId,
          'requirementId': requirementId,
          'qualificationName': qualificationName,
          'task': task,
        }),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
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
                child: Text(task.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
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
    return Text('Choose a career goal to build a Task Book.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: cs.onSurfaceVariant));
  }
}
