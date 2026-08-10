import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/pages/path/timeline/career_timeline_tab.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class MyPathPage extends StatelessWidget {
  const MyPathPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Path'),
          centerTitle: false,
          bottom: roadmap == null
              ? null
              : const TabBar(
                  isScrollable: false,
                  tabs: [
                    Tab(text: 'Path'),
                    Tab(text: 'Timeline'),
                  ],
                ),
          actions: [
            if (roadmap != null)
              IconButton(
                tooltip: 'Customize My Path',
                onPressed: () => _showCustomizeSheet(context, state, roadmap),
                icon: const Icon(Icons.tune),
              ),
          ],
        ),
        body: roadmap == null
            ? Padding(
                padding: AppSpacing.paddingLg,
                child: _EmptyPath(onBuild: () => context.go(AppRoutes.onboarding)),
              )
            : TabBarView(
                children: [
                  _PathTab(roadmap: roadmap),
                  const CareerTimelineTab(),
                ],
              ),
        floatingActionButton: roadmap == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showCustomizeSheet(context, state, roadmap),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                icon: const Icon(Icons.tune),
                label: const Text('Customize'),
              ),
      ),
    );
  }

  static String _whyLabel(Requirement r) {
    switch (r.requirementSource) {
      case RequirementSource.commonlyRequired:
        return 'Commonly required for this role.';
      case RequirementSource.recommended:
        return 'Commonly recommended for readiness.';
      case RequirementSource.stateRequirement:
        return 'State dependent requirement.';
      case RequirementSource.departmentRequirement:
        return 'Department dependent requirement.';
    }
  }

  Future<void> _showCustomizeSheet(BuildContext context, AppState state, Roadmap roadmap) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final insets = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: insets.bottom + AppSpacing.lg, top: AppSpacing.sm),
          child: _CustomizePathSheet(
            state: state,
            roadmap: roadmap,
            onAddRequirement: () async {
              Navigator.of(context).pop();
              await _showAddDepartmentRequirementSheet(context, state, roadmap.goal.id);
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddDepartmentRequirementSheet(BuildContext context, AppState state, String goalId) async {
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController();
    final type = ValueNotifier<RequirementType>(RequirementType.trainingCourse);
    final progressCurrentCtrl = TextEditingController();
    final progressRequiredCtrl = TextEditingController();
    final progressUnitCtrl = TextEditingController(text: 'hours');
    final experienceValueCtrl = TextEditingController();
    final experienceUnitCtrl = TextEditingController(text: 'years');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final insets = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: insets.bottom + AppSpacing.lg, top: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Department Requirement', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Requirement name')),
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder<RequirementType>(
                valueListenable: type,
                builder: (context, value, _) {
                  return DropdownButtonFormField<RequirementType>(
                    value: value,
                    decoration: const InputDecoration(labelText: 'Requirement type'),
                    items: const [
                      DropdownMenuItem(value: RequirementType.certification, child: Text('Certification')),
                      DropdownMenuItem(value: RequirementType.trainingCourse, child: Text('Course')),
                      DropdownMenuItem(value: RequirementType.taskBook, child: Text('Task Book')),
                      DropdownMenuItem(value: RequirementType.experience, child: Text('Experience')),
                      DropdownMenuItem(value: RequirementType.numericProgress, child: Text('Numeric Progress')),
                      DropdownMenuItem(value: RequirementType.promotionalTest, child: Text('Promotional Test')),
                      DropdownMenuItem(value: RequirementType.practical, child: Text('Practical')),
                      DropdownMenuItem(value: RequirementType.interview, child: Text('Interview')),
                      DropdownMenuItem(value: RequirementType.education, child: Text('Education')),
                      DropdownMenuItem(value: RequirementType.custom, child: Text('Custom')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      type.value = v;
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder<RequirementType>(
                valueListenable: type,
                builder: (context, value, _) {
                  if (value == RequirementType.numericProgress) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextField(controller: progressCurrentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current'))),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: TextField(controller: progressRequiredCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Required'))),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(controller: progressUnitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g., hours)')),
                      ],
                    );
                  }
                  if (value == RequirementType.experience) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextField(controller: experienceValueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Required'))),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: TextField(controller: experienceUnitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g., years)'))),
                          ],
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
                child: const Text('Add Requirement'),
              ),
            ],
          ),
        );
      },
    );

    if (result != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final id = '$goalId::dept_${now.millisecondsSinceEpoch}';
    final reqType = type.value;

    final current = double.tryParse(progressCurrentCtrl.text.trim());
    final required = double.tryParse(progressRequiredCtrl.text.trim());
    final unit = progressUnitCtrl.text.trim().isEmpty ? null : progressUnitCtrl.text.trim();

    final expValue = double.tryParse(experienceValueCtrl.text.trim());
    final expUnit = experienceUnitCtrl.text.trim().isEmpty ? null : experienceUnitCtrl.text.trim();
    final requirement = Requirement(
      id: id,
      name: name,
      category: 'Department',
      priority: RequirementPriority.department,
      description: 'Custom department requirement you added.',
      type: reqType,
      requirementSource: RequirementSource.departmentRequirement,
      defaultRequired: true,
      stateDependent: false,
      departmentDependent: true,
      completed: false,
      progressCurrent: reqType == RequirementType.numericProgress ? (current ?? 0) : null,
      progressRequired: reqType == RequirementType.numericProgress ? (required ?? 0) : null,
      progressUnit: reqType == RequirementType.numericProgress ? (unit ?? 'hours') : null,
      experienceValue: reqType == RequirementType.experience ? expValue : null,
      experienceUnit: reqType == RequirementType.experience ? (expUnit ?? 'years') : null,
      certificationReference: null,
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

    await state.addDepartmentRequirement(goalId: goalId, requirement: requirement);
  }
}

class _PathTab extends StatelessWidget {
  final Roadmap roadmap;
  const _PathTab({required this.roadmap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          _PathHeader(roadmap: roadmap, currentRoles: state.profile.currentRoles),
          const SizedBox(height: AppSpacing.lg),
          _SafetyNotice(),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(label: 'WHAT I SHOULD DO NEXT'),
          const SizedBox(height: AppSpacing.sm),
          _NextStepPanel(
            title: roadmap.nextStep?.requirement.name ?? 'You’re all caught up!',
            subtitle: roadmap.nextStep == null ? null : MyPathPage._whyLabel(roadmap.nextStep!.requirement),
            onTap: roadmap.nextStep == null ? null : () => context.push(AppRoutes.getStarted, extra: roadmap.nextStep!.requirement),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(label: 'WHAT I ALREADY HAVE'),
          const SizedBox(height: AppSpacing.sm),
          if (roadmap.completed.isEmpty)
            Text('Nothing yet — start with your next step.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
          else
            ...roadmap.completed.map((r) => _ReqTile(
                  requirement: r.requirement,
                  statusIcon: Icons.check_circle,
                  statusColor: FireOpsSemanticColors.completed,
                  onTap: () => context.push(AppRoutes.requirementDetail, extra: r.requirement),
                )),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(label: 'WHAT I STILL NEED'),
          const SizedBox(height: AppSpacing.sm),
          ...roadmap.comingUp.where((r) => roadmap.nextStep == null || r.requirement.id != roadmap.nextStep!.requirement.id).map((r) => _ReqTile(
                requirement: r.requirement,
                statusIcon: Icons.circle_outlined,
                statusColor: cs.onSurfaceVariant,
                onTap: () => context.push(AppRoutes.requirementDetail, extra: r.requirement),
              )),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _EmptyPath extends StatelessWidget {
  final VoidCallback onBuild;
  const _EmptyPath({required this.onBuild});

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
          Text('Build your path', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          Text('Choose where you are, your goal, and what certs you already have.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(onPressed: onBuild, child: const Text('Start Setup')),
          ),
        ],
      ),
    );
  }
}

class _NextStepPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _NextStepPanel({required this.title, required this.subtitle, required this.onTap});

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReqTile extends StatelessWidget {
  final Requirement requirement;
  final IconData statusIcon;
  final Color statusColor;
  final VoidCallback onTap;

  const _ReqTile({required this.requirement, required this.statusIcon, required this.statusColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(requirement.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                        const SizedBox(width: AppSpacing.sm),
                        _RequirementBadges(requirement: requirement),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_subtitleFor(requirement), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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

  static String _subtitleFor(Requirement r) {
    final parts = <String>[];
    parts.add(switch (r.requirementSource) {
      RequirementSource.commonlyRequired => 'Commonly Required',
      RequirementSource.recommended => 'Commonly Recommended',
      RequirementSource.stateRequirement => 'State Dependent',
      RequirementSource.departmentRequirement => 'Department Dependent',
    });
    if (r.type == RequirementType.experience && r.experienceValue != null) {
      parts.add('${r.experienceValue!.toStringAsFixed(0)} ${r.experienceUnit ?? 'years'}');
    }
    if (r.type == RequirementType.numericProgress && r.progressRequired != null) {
      final unit = r.progressUnit;
      parts.add('Goal: ${r.progressRequired!.toStringAsFixed(0)}${unit == null ? '' : ' $unit'}');
    }
    return parts.join(' • ');
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant));
  }
}

class _SafetyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Text(
        'Fire service certification and promotional requirements vary by state, agency, and department. FireOps Path provides career planning guidance and should not replace official department or state requirements.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
      ),
    );
  }
}

class _PathHeader extends StatelessWidget {
  final Roadmap roadmap;
  final List<String> currentRoles;
  const _PathHeader({required this.roadmap, required this.currentRoles});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final from = currentRoles.isEmpty ? 'Current role' : currentRoles.first;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${roadmap.goal.category.toUpperCase()} GOAL', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.xs),
          Text('${roadmap.goal.title}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.xs),
          Text('$from → ${roadmap.goal.title}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          Text('${roadmap.completedCount} of ${roadmap.totalCount} complete', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: roadmap.percentComplete.clamp(0, 1),
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation(cs.primary),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementBadges extends StatelessWidget {
  final Requirement requirement;
  const _RequirementBadges({required this.requirement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pills = <Widget>[];

    Color pillBg(Color c) => c.withValues(alpha: 0.10);
    Color pillBd(Color c) => c.withValues(alpha: 0.18);

    void add(String text, Color color) {
      pills.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: pillBg(color), borderRadius: BorderRadius.circular(99), border: Border.all(color: pillBd(color))),
          child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900)),
        ),
      );
    }

    switch (requirement.priority) {
      case RequirementPriority.core:
        add('CORE', cs.primary);
      case RequirementPriority.recommended:
        add('RECOMMENDED', cs.secondary);
      case RequirementPriority.development:
        add('DEVELOPMENT', cs.tertiary);
      case RequirementPriority.department:
        add('DEPARTMENT', cs.onSurfaceVariant);
      case RequirementPriority.state:
        add('STATE', FireOpsSemanticColors.warning);
    }
    if (requirement.stateDependent && requirement.priority != RequirementPriority.state) add('STATE', FireOpsSemanticColors.warning);
    if (requirement.departmentDependent && requirement.priority != RequirementPriority.department) add('DEPT', cs.onSurfaceVariant);

    return Wrap(spacing: 6, runSpacing: 6, children: pills);
  }
}

class _CustomizePathSheet extends StatelessWidget {
  final AppState state;
  final Roadmap roadmap;
  final Future<void> Function() onAddRequirement;
  const _CustomizePathSheet({required this.state, required this.roadmap, required this.onAddRequirement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Customize My Path', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: AppSpacing.xs),
        Text('Turn requirements on/off for your department and edit experience minimums.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.62,
          child: ListView.builder(
            itemCount: roadmap.all.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: OutlinedButton.icon(
                    onPressed: onAddRequirement,
                    icon: const Icon(Icons.add),
                    label: const Text('Add a requirement'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                  ),
                );
              }

              final item = roadmap.all[index - 1];
              final req = item.requirement;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(req.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                          if (req.id.startsWith('${roadmap.goal.id}::'))
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => _confirmDelete(context, state, req.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          Switch(
                            value: !item.isExcluded,
                            onChanged: (v) => state.setRequirementExcluded(goalId: roadmap.goal.id, requirementId: req.id, excluded: !v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(_ReqTile._subtitleFor(req), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      if (req.type == RequirementType.experience) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _InlineNumberEditor(
                          label: 'Minimum years',
                          initial: req.experienceValue ?? 0,
                          onSave: (v) => state.setExperienceMinimum(goalId: roadmap.goal.id, requirementId: req.id, years: v),
                        ),
                      ],
                      if (req.type == RequirementType.numericProgress) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _InlineNumberEditor(
                          label: 'Required',
                          initial: req.progressRequired ?? 0,
                          onSave: (v) => state.setNumericRequired(goalId: roadmap.goal.id, requirementId: req.id, requiredValue: v),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
          child: const Text('Done'),
        ),
      ],
    );
  }

  static Future<void> _confirmDelete(BuildContext context, AppState state, String requirementId) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Delete requirement?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.sm),
              Text('This only removes it from your custom path.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ],
          ),
        );
      },
    );
    if (confirm == true) await state.deleteCustomRequirement(requirementId);
  }
}

class _InlineNumberEditor extends StatefulWidget {
  final String label;
  final double initial;
  final ValueChanged<double> onSave;
  const _InlineNumberEditor({required this.label, required this.initial, required this.onSave});

  @override
  State<_InlineNumberEditor> createState() => _InlineNumberEditorState();
}

class _InlineNumberEditorState extends State<_InlineNumberEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: TextField(controller: _ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: widget.label))),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          height: 44,
          child: FilledButton(
            onPressed: () {
              final v = double.tryParse(_ctrl.text.trim());
              if (v == null) return;
              widget.onSave(v);
            },
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
