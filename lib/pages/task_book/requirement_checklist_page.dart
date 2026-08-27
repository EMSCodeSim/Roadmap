import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/national_task_book_baseline.dart';
import 'package:firepath/services/task_book_checklist_hierarchy.dart';
import 'package:firepath/services/task_book_navigation.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';

/// A requirement-level checklist that can expand one level deeper.
///
/// Task Book -> Requirement -> Checklist item -> Substeps.
class RequirementChecklistPage extends StatelessWidget {
  final String? goalId;
  final Requirement requirement;

  const RequirementChecklistPage({
    super.key,
    required this.goalId,
    required this.requirement,
  });

  String? _effectiveGoalId(AppState state) {
    final explicit = goalId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return state.roadmap?.goal.id;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final resolvedGoalId = _effectiveGoalId(state);
    if (resolvedGoalId == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton.toTaskBook(),
          title: const Text('Skills Checklist'),
        ),
        body: const Center(child: Text('Select a career goal to use this checklist.')),
      );
    }
    final controller = state.taskBookController;
    final savedSteps = controller.planStepsFor(
      goalId: resolvedGoalId,
      requirementId: requirement.id,
    );
    final savedSubTasks = controller.subTasksFor(
      goalId: resolvedGoalId,
      requirementId: requirement.id,
    );
    final standard = NationalTaskBookBaseline.standardFor(requirement);
    final steps = NationalTaskBookBaseline.effectiveSteps(
      requirement,
      savedSteps,
    );
    final subTasks = NationalTaskBookBaseline.effectiveSubTasks(
      requirement,
      savedSubTasks,
    );
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toTaskBook(),
        title: const Text('Skills Checklist'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addStep(context, state, resolvedGoalId),
        icon: const Icon(Icons.add),
        label: const Text('Local item'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            Text(
              requirement.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              standard == null
                  ? _sourceText(state)
                  : '${standard.citation} • national professional-qualification baseline',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                standard == null
                    ? 'No built-in national checklist is mapped to this requirement yet. Add state, department, academy, or promotional steps here.'
                    : 'This checklist starts with a paraphrased ${standard.citation} national baseline. National items remain intact while state, AHJ, department, academy, and promotional requirements can be added on top. Verify the official certification process for your jurisdiction.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
            ),
            if (TaskBookNavigation.hasPreparationTasks(requirement)) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('checklist-open-preparation-tasks'),
                onPressed: () =>
                    context.push(
                      AppRoutes.qualificationTaskBook,
                      extra: <String, dynamic>{'requirement': requirement},
                    ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Open preparation tasks'),
              ),
            ],
            const SizedBox(height: 16),
            if (steps.isEmpty)
              _EmptyChecklist(onAdd: () => _addStep(context, state, resolvedGoalId))
            else
              ...steps.map(
                (step) => _StepCard(
                  step: step,
                  children: TaskBookChecklistHierarchy.childrenFor(
                    step.id,
                    subTasks,
                  ),
                  onToggle: (done) => _toggleStep(
                    state,
                    resolvedGoalId,
                    step,
                    subTasks,
                    done,
                  ),
                  onAddChild: () =>
                      _addSubStep(context, state, resolvedGoalId, step),
                  onToggleChild: (child, done) => _toggleSubStep(
                    state,
                    resolvedGoalId,
                    step,
                    child,
                    done,
                  ),
                  isNational: NationalTaskBookBaseline.isNationalItem(step.id),
                  onDelete: () => controller.deletePlanStep(
                    goalId: resolvedGoalId,
                    requirementId: requirement.id,
                    stepId: step.id,
                  ),
                ),
              ),
            if (TaskBookChecklistHierarchy.unassigned(subTasks).isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'OLDER CHECKLIST ITEMS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ...TaskBookChecklistHierarchy.unassigned(subTasks).map(
                (item) => CheckboxListTile(
                  value: item.isDone,
                  title: Text(item.title),
                  subtitle: TaskBookChecklistHierarchy.visibleNotes(item) == null
                      ? null
                      : Text(TaskBookChecklistHierarchy.visibleNotes(item)!),
                  onChanged: (value) => controller.setSubTaskDone(
                    goalId: resolvedGoalId,
                    requirementId: requirement.id,
                    subTaskId: item.id,
                    done: value ?? false,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _sourceText(AppState state) {
    final stateName = FireOpsCatalog.stateNameForCode(state.profile.state);
    return switch (requirement.requirementSource) {
      RequirementSource.commonlyRequired =>
        'National/common baseline • verify ${stateName ?? 'state'} and department requirements',
      RequirementSource.stateRequirement =>
        '${stateName ?? 'State'} requirement • verify the official state source',
      RequirementSource.departmentRequirement =>
        'Local/department requirement • user or department supplied',
      RequirementSource.recommended =>
        'Recommended development • not automatically treated as a universal requirement',
    };
  }

  Future<void> _addStep(
    BuildContext context,
    AppState state,
    String resolvedGoalId,
  ) async {
    final title = await _textPrompt(
      context,
      title: 'Add local checklist item',
      label: 'Checklist item',
      hint: 'Example: Department acting officer evaluation',
    );
    if (title == null) return;
    final now = DateTime.now();
    await state.taskBookController.upsertPlanStep(
      goalId: resolvedGoalId,
      requirementId: requirement.id,
      step: RequirementPlanStep(
        id: 'step_${now.microsecondsSinceEpoch}',
        title: title,
        isDone: false,
        notes: null,
        url: null,
        estimatedMinutes: null,
      ),
    );
  }

  Future<void> _addSubStep(
    BuildContext context,
    AppState state,
    String resolvedGoalId,
    RequirementPlanStep parent,
  ) async {
    final title = await _textPrompt(
      context,
      title: 'Add local substep',
      label: 'Substep',
      hint: 'Example: Evaluator initials required',
    );
    if (title == null) return;
    final now = DateTime.now();
    var subTask = RequirementSubTask(
      id: 'sub_${now.microsecondsSinceEpoch}',
      title: title,
      isDone: false,
      notes: null,
    );
    subTask = TaskBookChecklistHierarchy.attachToStep(subTask, parent.id);
    await state.taskBookController.upsertSubTask(
      goalId: resolvedGoalId,
      requirementId: requirement.id,
      subTask: subTask,
    );
  }

  Future<void> _toggleStep(
    AppState state,
    String resolvedGoalId,
    RequirementPlanStep step,
    List<RequirementSubTask> allSubTasks,
    bool done,
  ) async {
    final controller = state.taskBookController;
    await controller.upsertPlanStep(
      goalId: resolvedGoalId,
      requirementId: requirement.id,
      step: step.copyWith(isDone: done),
    );
    for (final child in TaskBookChecklistHierarchy.childrenFor(
      step.id,
      allSubTasks,
    )) {
      if (child.isDone == done) continue;
      await controller.upsertSubTask(
        goalId: resolvedGoalId,
        requirementId: requirement.id,
        subTask: child.copyWith(isDone: done),
      );
    }
  }

  Future<void> _toggleSubStep(
    AppState state,
    String resolvedGoalId,
    RequirementPlanStep parent,
    RequirementSubTask child,
    bool done,
  ) async {
    final controller = state.taskBookController;
    await controller.upsertSubTask(
      goalId: resolvedGoalId,
      requirementId: requirement.id,
      subTask: child.copyWith(isDone: done),
    );
    final updated = NationalTaskBookBaseline.effectiveSubTasks(
      requirement,
      controller.subTasksFor(
        goalId: resolvedGoalId,
        requirementId: requirement.id,
      ),
    );
    final parentDone = TaskBookChecklistHierarchy.stepCompleteFromChildren(
      parent.id,
      updated,
    );
    if (parentDone != parent.isDone) {
      await controller.upsertPlanStep(
        goalId: resolvedGoalId,
        requirementId: requirement.id,
        step: parent.copyWith(isDone: parentDone),
      );
    }
  }

  static Future<String?> _textPrompt(
    BuildContext context, {
    required String title,
    required String label,
    required String hint,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final clean = controller.text.trim();
              if (clean.isEmpty) return;
              Navigator.pop(dialogContext, clean);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class _StepCard extends StatelessWidget {
  final RequirementPlanStep step;
  final List<RequirementSubTask> children;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAddChild;
  final void Function(RequirementSubTask, bool) onToggleChild;
  final bool isNational;
  final VoidCallback onDelete;

  const _StepCard({
    required this.step,
    required this.children,
    required this.onToggle,
    required this.onAddChild,
    required this.onToggleChild,
    required this.isNational,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doneCount = children.where((e) => e.isDone).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Checkbox(
          value: step.isDone,
          onChanged: (value) => onToggle(value ?? false),
        ),
        title: Text(
          step.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          isNational
              ? 'National baseline • $doneCount of ${children.length} objectives complete'
              : (children.isEmpty
                  ? 'Local/custom item • tap to add deeper checklist steps'
                  : '$doneCount of ${children.length} substeps complete'),
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.expand_more),
        children: [
          if (children.isNotEmpty)
            ...children.map(
              (child) => CheckboxListTile(
                value: child.isDone,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(child.title),
                subtitle: TaskBookChecklistHierarchy.visibleNotes(child) == null
                    ? null
                    : Text(TaskBookChecklistHierarchy.visibleNotes(child)!),
                onChanged: (value) => onToggleChild(child, value ?? false),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onAddChild,
                  icon: const Icon(Icons.add),
                  label: Text(isNational ? 'Add local substep' : 'Add substep'),
                ),
                const Spacer(),
                if (!isNational)
                  IconButton(
                    tooltip: 'Delete checklist item',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  )
                else
                  const Chip(
                    avatar: Icon(Icons.verified_outlined, size: 16),
                    label: Text('National'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChecklist extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyChecklist({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            const Icon(Icons.account_tree_outlined, size: 38),
            const SizedBox(height: 10),
            Text(
              'Add local requirements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No national baseline is mapped to this requirement yet. Add state, department, academy, or promotional checklist items here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add local item'),
            ),
          ],
        ),
      ),
    );
  }
}
