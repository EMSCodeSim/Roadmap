import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class TaskBookRequirementsEditorPage extends StatelessWidget {
  const TaskBookRequirementsEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    final cs = Theme.of(context).colorScheme;

    if (roadmap == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customize Task Book')),
        body: const Center(child: Text('Choose a career goal first.')),
      );
    }

    final goalId = roadmap.goal.id;
    final items = [...roadmap.all]
      ..sort((a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder));

    return Scaffold(
      appBar: AppBar(title: const Text('Customize Task Book')),
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
                    'Make this book match your department',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Turn off items your department does not require and add local requirements before you begin using the Task Book.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: () => _showAddRequirement(context, state, goalId),
                icon: const Icon(Icons.add),
                label: const Text('Add Department Requirement'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'REQUIREMENTS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) {
              final requirement = item.requirement;
              final custom = requirement.id.startsWith('$goalId::');
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: item.isExcluded
                        ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
                        : cs.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              requirement.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _sourceLabel(requirement),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (custom)
                        IconButton(
                          tooltip: 'Delete custom requirement',
                          onPressed: () => _confirmDelete(
                            context,
                            state,
                            requirement.id,
                            requirement.name,
                          ),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      Switch(
                        value: !item.isExcluded,
                        onChanged: (enabled) => state.setRequirementExcluded(
                          goalId: goalId,
                          requirementId: requirement.id,
                          excluded: !enabled,
                        ),
                      ),
                    ],
                  ),
                ),
              );
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done Reviewing Requirements'),
            ),
          ),
        ),
      ),
    );
  }

  static String _sourceLabel(Requirement requirement) {
    final source = switch (requirement.requirementSource) {
      RequirementSource.commonlyRequired => 'Commonly required',
      RequirementSource.recommended => 'Recommended',
      RequirementSource.stateRequirement => 'State dependent',
      RequirementSource.departmentRequirement => 'Department requirement',
    };
    final detail = switch (requirement.type) {
      RequirementType.numericProgress when requirement.progressRequired != null =>
        '${requirement.progressRequired!.toStringAsFixed(0)} ${requirement.progressUnit ?? ''}'.trim(),
      RequirementType.experience when requirement.experienceValue != null =>
        '${requirement.experienceValue!.toStringAsFixed(0)} ${requirement.experienceUnit ?? 'years'}',
      _ => requirement.type.name,
    };
    return '$source • $detail';
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    String requirementId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete requirement?'),
        content: Text('$name will be removed from this custom Task Book.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.deleteCustomRequirement(requirementId);
    }
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
      builder: (sheetContext) {
        return StatefulBuilder(
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
                      'Add Department Requirement',
                      style: Theme.of(sheetContext)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: name,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Requirement name',
                        hintText: 'Example: 100 hours apparatus driving',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<RequirementType>(
                      initialValue: type,
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
                          child: Text('Department Task Book'),
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
        );
      },
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
      id: '$goalId::dept_${now.millisecondsSinceEpoch}',
      name: name.text.trim(),
      category: 'Department',
      priority: RequirementPriority.department,
      description: 'Custom department requirement added by the user.',
      type: type,
      requirementSource: RequirementSource.departmentRequirement,
      defaultRequired: true,
      stateDependent: false,
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
      certificationReference: null,
      certificationDefinitionId: null,
      allowExpiredCertification: false,
      prerequisiteRequirementIds: const [],
      resourceIds: const [],
      resourceLinks: const [],
      sortOrder: 999,
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
