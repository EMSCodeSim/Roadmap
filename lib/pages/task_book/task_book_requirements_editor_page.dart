import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/pages/task_book/requirement_checklist_page.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/national_task_book_baseline.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';

class TaskBookRequirementsEditorPage extends StatelessWidget {
  const TaskBookRequirementsEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    final cs = Theme.of(context).colorScheme;

    if (roadmap == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton.toTaskBook(),
          title: const Text('Customize Task Book'),
        ),
        body: const Center(child: Text('Choose a career goal first.')),
      );
    }

    final goalId = roadmap.goal.id;
    final items = [...roadmap.all]
      ..sort(
        (a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder),
      );

    List<RoadmapRequirement> bySource(RequirementSource src) =>
        items.where((e) => e.requirement.requirementSource == src).toList();

    final national = bySource(RequirementSource.commonlyRequired);
    final stateReqs = bySource(RequirementSource.stateRequirement);
    final local = bySource(RequirementSource.departmentRequirement);
    final recommended = bySource(RequirementSource.recommended);

    final groups = <(String, String, List<RoadmapRequirement>)>[
      if (national.isNotEmpty)
        (
          'NATIONAL BASELINE',
          'Start here, then verify state and department requirements.',
          national,
        ),
      if (stateReqs.isNotEmpty)
        (
          'STATE',
          'Verified state-specific requirements available to this profile.',
          stateReqs,
        ),
      if (local.isNotEmpty)
        (
          'LOCAL / DEPARTMENT',
          'Items added for your department, AHJ, or personal career path.',
          local,
        ),
      if (recommended.isNotEmpty)
        (
          'RECOMMENDED',
          'Development that may improve readiness but is not universal.',
          recommended,
        ),
    ];

    final stateName = FireOpsCatalog.stateNameForCode(state.profile.state);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toTaskBook(),
        title: const Text('Customize Task Book'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'National baseline + your local reality',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Career Road starts with a national/common framework. Verify ${stateName ?? 'your state'}, your AHJ, department job description, and promotional process. Add anything local that is missing.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'A national baseline is a planning starting point, not proof that a certification is required by every department.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: () => _showAddRequirement(context, state, goalId),
                icon: const Icon(Icons.add),
                label: const Text('Add Local Requirement'),
              ),
            ),
            const SizedBox(height: 18),
            ...groups.expand((group) sync* {
              yield Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.$1,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      group.$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );

              for (final item in group.$3) {
                yield _RequirementCard(
                  goalId: goalId,
                  item: item,
                  state: state,
                );
              }
            }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Done Reviewing Requirements'),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _showAddRequirement(
    BuildContext context,
    AppState state,
    String goalId,
  ) async {
    final name = TextEditingController();
    final required = TextEditingController();
    final unit = TextEditingController(text: 'hours');
    var type = RequirementType.trainingCourse;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final insets = MediaQuery.viewInsetsOf(sheetContext);
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 20 + insets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Local Requirement',
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Use this for a state, AHJ, department, union, academy, or promotional requirement that is not already in the baseline.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Requirement name',
                      hintText: 'Example: Department acting officer task book',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<RequirementType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(
                        value: RequirementType.certification,
                        child: Text('Certification'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.trainingCourse,
                        child: Text('Training / Course'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.taskBook,
                        child: Text('Task Book'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.experience,
                        child: Text('Experience'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.numericProgress,
                        child: Text('Hours / Repetitions / Numeric Goal'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.promotionalTest,
                        child: Text('Written / Promotional Test'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.practical,
                        child: Text('Practical Evaluation'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.interview,
                        child: Text('Interview'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.custom,
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => type = value);
                    },
                  ),
                  if (type == RequirementType.numericProgress ||
                      type == RequirementType.experience) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: required,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Required amount',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: unit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              hintText: type == RequirementType.experience
                                  ? 'years'
                                  : 'hours',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () {
                        if (name.text.trim().isEmpty) return;
                        Navigator.pop(sheetContext, true);
                      },
                      child: const Text('Add Requirement'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result != true) {
      name.dispose();
      required.dispose();
      unit.dispose();
      return;
    }

    final now = DateTime.now();
    final amount = double.tryParse(required.text.trim());
    final cleanUnit = unit.text.trim();
    final requirement = Requirement(
      id: '$goalId::local_${now.millisecondsSinceEpoch}',
      name: name.text.trim(),
      category: 'Local',
      priority: RequirementPriority.department,
      description: 'Local requirement added by the user. Verify against the official source.',
      type: type,
      requirementSource: RequirementSource.departmentRequirement,
      defaultRequired: true,
      stateDependent: true,
      departmentDependent: true,
      completed: false,
      progressCurrent: type == RequirementType.numericProgress ? 0 : null,
      progressRequired:
          type == RequirementType.numericProgress ? (amount ?? 0) : null,
      progressUnit: type == RequirementType.numericProgress
          ? (cleanUnit.isEmpty ? 'hours' : cleanUnit)
          : null,
      experienceValue: type == RequirementType.experience ? amount : null,
      experienceUnit: type == RequirementType.experience
          ? (cleanUnit.isEmpty ? 'years' : cleanUnit)
          : null,
      certificationReference: type == RequirementType.certification
          ? name.text.trim()
          : null,
      certificationDefinitionId: type == RequirementType.certification
          ? FireOpsCatalog.matchCertificationDefinitionId(name.text.trim())
          : null,
      allowExpiredCertification: false,
      prerequisiteRequirementIds: const [],
      resourceIds: const [],
      resourceLinks: const [],
      sortOrder: 999,
      sourceNotes: 'User-added local requirement; confirm with the responsible authority.',
      estimatedDurationDays: null,
      recommendedLeadTimeDays: null,
      canRunConcurrent: true,
      timelineCategory: TimelineCategory.departmentRequirement,
      suggestedStartDate: null,
      suggestedCompletionDate: null,
      createdAt: now,
      updatedAt: now,
    );

    await state.addDepartmentRequirement(
      goalId: goalId,
      requirement: requirement,
    );

    name.dispose();
    required.dispose();
    unit.dispose();
  }
}

class _RequirementCard extends StatelessWidget {
  final String goalId;
  final RoadmapRequirement item;
  final AppState state;

  const _RequirementCard({
    required this.goalId,
    required this.item,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final requirement = item.requirement;
    final cs = Theme.of(context).colorScheme;
    final custom = requirement.id.startsWith('$goalId::');
    final override = state.taskBookController.getOverride(goalId, requirement.id);
    final savedSteps = override?.planSteps ?? const <RequirementPlanStep>[];
    final savedSubTasks = override?.subTasks ?? const <RequirementSubTask>[];
    final steps = NationalTaskBookBaseline.effectiveSteps(
      requirement,
      savedSteps,
    );
    final subTasks = NationalTaskBookBaseline.effectiveSubTasks(
      requirement,
      savedSubTasks,
    );
    final done = steps.where((e) => e.isDone).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: item.isExcluded
              ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
              : cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requirement.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _sourceLabel(requirement, state.profile.state),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  if (steps.isNotEmpty || subTasks.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${steps.length} checklist items • $done complete${subTasks.isEmpty ? '' : ' • ${subTasks.length} deeper steps'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Open checklist',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RequirementChecklistPage(
                    goalId: goalId,
                    requirement: requirement,
                  ),
                ),
              ),
              icon: const Icon(Icons.account_tree_outlined),
            ),
            if (custom)
              IconButton(
                tooltip: 'Delete local requirement',
                onPressed: () => _confirmDelete(context, requirement),
                icon: const Icon(Icons.delete_outline),
              ),
            Switch(
              value: !item.isExcluded,
              onChanged: (enabled) async {
                await state.setRequirementExcluded(
                  goalId: goalId,
                  requirementId: requirement.id,
                  excluded: !enabled,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Requirement req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete local requirement?'),
        content: Text('${req.name} will be removed from this Task Book.'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => dialogContext.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.deleteCustomRequirement(req.id);
  }

  static String _sourceLabel(Requirement requirement, String? stateCode) {
    final stateName = FireOpsCatalog.stateNameForCode(stateCode);
    final source = switch (requirement.requirementSource) {
      RequirementSource.commonlyRequired => 'National/common baseline',
      RequirementSource.recommended => 'Recommended development',
      RequirementSource.stateRequirement =>
        '${stateName ?? 'State'} requirement',
      RequirementSource.departmentRequirement => 'Local / department',
    };
    return '$source • ${requirement.type.name}';
  }
}
