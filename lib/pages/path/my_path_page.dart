import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/career_path.dart';
import 'package:firepath/pages/path/timeline/career_timeline_tab.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/services/catalog.dart';

class MyPathPage extends StatelessWidget {
  const MyPathPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personal Roadmap'),
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
              PopupMenuButton<String>(
                tooltip: 'Personal Roadmap tools',
                onSelected: (value) {
                  if (value == 'change_goal') {
                    context.push(AppRoutes.goalSetup);
                  } else if (value == 'customize') {
                    _showCustomizeSheet(context, state, roadmap);
                  } else if (value == 'tools') {
                    _showRoadmapTools(context);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'change_goal',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz_rounded),
                      title: Text('Change end path'),
                      subtitle: Text('Keep your records and choose a new goal'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'customize',
                    child: ListTile(
                      leading: Icon(Icons.tune),
                      title: Text('Customize roadmap'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'tools',
                    child: ListTile(
                      leading: Icon(Icons.more_horiz_rounded),
                      title: Text('More roadmap tools'),
                    ),
                  ),
                ],
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
      ),
    );
  }

  static Future<void> _showRoadmapTools(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Career Intelligence'),
                subtitle: const Text('Deeper readiness and career analysis'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.careerIntelligence);
                },
              ),
              ListTile(
                leading: const Icon(Icons.hub_outlined),
                title: const Text('Competency Map'),
                subtitle: const Text('Review competency evidence and freshness'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.competencyMap);
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_up_rounded),
                title: const Text('Growth tools'),
                subtitle: const Text('Evidence, development, and longer-term planning'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.growthDetails);
                },
              ),
              ListTile(
                leading: const Icon(Icons.compare_arrows_rounded),
                title: const Text('Department transfer planning'),
                subtitle: const Text('Compare a prospective department without changing official records'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.departmentTransfer);
                },
              ),
            ],
          ),
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
              Text('Add Personal Roadmap Item', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Roadmap item name')),
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder<RequirementType>(
                valueListenable: type,
                builder: (context, value, _) {
                  return DropdownButtonFormField<RequirementType>(
                    initialValue: value,
                    decoration: const InputDecoration(labelText: 'Requirement type'),
                    items: const [
                      DropdownMenuItem(value: RequirementType.certification, child: Text('Certification')),
                      DropdownMenuItem(value: RequirementType.trainingCourse, child: Text('Course')),
                      DropdownMenuItem(value: RequirementType.taskBook, child: Text('Milestone / Task')),
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
                child: const Text('Add to Personal Roadmap'),
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
      category: 'Personal Roadmap',
      priority: RequirementPriority.development,
      description: 'User-added Personal Roadmap item. Edit it as your plan changes.',
      type: reqType,
      requirementSource: RequirementSource.recommended,
      defaultRequired: true,
      stateDependent: false,
      departmentDependent: false,
      completed: false,
      progressCurrent: reqType == RequirementType.numericProgress ? (current ?? 0) : null,
      progressRequired: reqType == RequirementType.numericProgress ? (required ?? 0) : null,
      progressUnit: reqType == RequirementType.numericProgress ? (unit ?? 'hours') : null,
      experienceValue: reqType == RequirementType.experience ? expValue : null,
      experienceUnit: reqType == RequirementType.experience ? (expUnit ?? 'years') : null,
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
      timelineCategory: TimelineCategory.development,
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

    final currentRole = state.profile.currentRoles.isEmpty
        ? 'Current role'
        : state.profile.currentRoles.first;
    final goalTitle = roadmap.goal.title;
    final percentReady = (roadmap.percentComplete * 100).round();
    final targetDate = state.profile.careerPlan.targetDate;

    final nextActions = _buildNextActions(roadmap);
    final stillNeeded = roadmap.missing
        .where((e) => nextActions.indexWhere((n) => n.requirement.id == e.requirement.id) == -1)
        .toList()
      ..sort((a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder));
    final completed = roadmap.completed
      ..sort((a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder));

    final grouped = <String, List<RoadmapRequirement>>{};
    for (final item in stillNeeded) {
      final key = _groupLabel(item.requirement);
      (grouped[key] ??= <RoadmapRequirement>[]).add(item);
    }
    final groupOrder = [
      'Certifications',
      'Training',
      'Experience',
      'Milestones & Tasks',
      'Personal Requirements',
      'Promotion Preparation',
      'Other',
    ];
    final orderedGroups = grouped.keys.toList()
      ..sort((a, b) {
        final ia = groupOrder.indexOf(a);
        final ib = groupOrder.indexOf(b);
        if (ia == -1 && ib == -1) return a.compareTo(b);
        if (ia == -1) return 1;
        if (ib == -1) return -1;
        return ia.compareTo(ib);
      });

    return SafeArea(
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          _RoadmapHeader(
            fromRole: currentRole,
            goalTitle: goalTitle,
            percentReady: percentReady,
            targetDate: targetDate,
          ),
          if (state.roadmapUpdateMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('Roadmap updated', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(state.roadmapUpdateMessage!),
                trailing: IconButton(
                  tooltip: 'Dismiss',
                  onPressed: state.clearRoadmapUpdateMessage,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.edit_road_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Your roadmap is editable', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                ]),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Open any item for its detailed plan, steps, notes and resources. Use Customize to add or remove personal items. Suggested items are guidance; official-source items should be checked against the current authority.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: 8, runSpacing: 8, children: const [
                  Chip(label: Text('Suggested')),
                  Chip(label: Text('Official Source · Verify')),
                  Chip(label: Text('User Added')),
                ]),
              ]),
            ),
          ),
          if (state.profile.effectiveCareerPath != CareerPath.ems) ...[
            const SizedBox(height: AppSpacing.lg),
            _CareerPathOverview(state: state, roadmap: roadmap),
            const SizedBox(height: AppSpacing.lg),
            _SpecialtyPathsSection(state: state),
          ],
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(label: 'NEXT'),
          const SizedBox(height: AppSpacing.sm),
          if (nextActions.isEmpty)
            Text(
              'You’re all caught up. Review Timeline or customize your path as needed.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            )
          else
            ...nextActions.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final emphasized = idx == 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _NextActionCard(
                  requirement: item.requirement,
                  emphasized: emphasized,
                  subtitle: MyPathPage._whyLabel(item.requirement),
                  primaryLabel: _primaryLabel(item.requirement),
                  onOpen: () => AppRouter.openRequirement(context, item.requirement, goalId: state.roadmap?.goal.id),
                  onPrimary: () => _primaryAction(context, state, item.requirement),
                ),
              );
            }),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(label: 'STILL NEEDED'),
          const SizedBox(height: AppSpacing.sm),
          if (orderedGroups.isEmpty)
            Text('Nothing remaining.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
          else
            ...orderedGroups.expand((group) {
              final items = grouped[group]!;
              return [
                _GroupHeading(title: group, count: items.length),
                const SizedBox(height: AppSpacing.sm),
                ...items.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ReqTile(
                        requirement: r.requirement,
                        statusIcon: Icons.circle_outlined,
                        statusColor: cs.onSurfaceVariant,
                        onTap: () => AppRouter.openRequirement(context, r.requirement, goalId: state.roadmap?.goal.id),
                        compactBadges: true,
                      ),
                    )),
                const SizedBox(height: AppSpacing.md),
              ];
            }),
          const SizedBox(height: AppSpacing.xl),
          ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'COMPLETED ${completed.isEmpty ? '' : '(${completed.length})'}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant),
            ),
            children: [
              if (completed.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text('Nothing completed yet.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                )
              else
                ...completed.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ReqTile(
                        requirement: r.requirement,
                        statusIcon: Icons.check_circle,
                        statusColor: FireOpsSemanticColors.completed,
                        onTap: () => AppRouter.openRequirement(context, r.requirement, goalId: state.roadmap?.goal.id),
                        compactBadges: true,
                      ),
                    )),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  static List<RoadmapRequirement> _buildNextActions(Roadmap roadmap) {
    final next = roadmap.nextStep;
    if (next == null) return const <RoadmapRequirement>[];
    final others = roadmap.missing
        .where((e) => e.requirement.id != next.requirement.id)
        .toList()
      ..sort((a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder));
    return [next, ...others.take(2)];
  }

  static String _primaryLabel(Requirement r) {
    return switch (r.type) {
      RequirementType.taskBook || RequirementType.numericProgress => 'Update',
      RequirementType.experience => 'Log',
      _ => 'Start',
    };
  }

  static void _primaryAction(BuildContext context, AppState state, Requirement r) {
    if (r.type == RequirementType.certification) {
      AppRouter.openRequirement(context, r, goalId: state.roadmap?.goal.id);
      return;
    }
    if (r.type == RequirementType.taskBook || r.type == RequirementType.numericProgress) {
      AppRouter.openRequirement(context, r, goalId: state.roadmap?.goal.id);
      return;
    }
    if (r.type == RequirementType.experience) {
      context.go(AppRoutes.personalLog);
      return;
    }
    context.push(AppRoutes.getStarted, extra: r);
  }

  static String _groupLabel(Requirement r) {
    if (r.type == RequirementType.certification) return 'Certifications';
    if (r.type == RequirementType.taskBook) return 'Task Books';
    if (r.type == RequirementType.experience || r.type == RequirementType.numericProgress) {
      return 'Experience';
    }
    if (r.requirementSource == RequirementSource.departmentRequirement) {
      return 'Department Requirements';
    }
    if (r.type == RequirementType.interview || r.type == RequirementType.promotionalTest) {
      return 'Promotion Preparation';
    }
    if (r.type == RequirementType.trainingCourse || r.type == RequirementType.course || r.type == RequirementType.education || r.type == RequirementType.practical) {
      return 'Training';
    }
    return 'Other';
  }
}

class _CareerPathOverview extends StatelessWidget {
  final AppState state;
  final Roadmap roadmap;

  const _CareerPathOverview({required this.state, required this.roadmap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stages = state.fireCareerStages;
    final currentRole = state.profile.currentRoles.isEmpty
        ? null
        : state.profile.currentRoles.first.trim().toLowerCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Career path',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _CustomizePathSheet._showCareerStagesEditor(context, state),
                  child: const Text('Customize'),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Recommended progression. Tap any stage to review it; skip, replace, add, or reorder stages to match your department.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stages.length,
                separatorBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                itemBuilder: (context, index) {
                  final stage = stages[index];
                  final progress = _stageProgress(stage, currentRole);
                  final completed = progress >= 100;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () => _showStage(context, stage, progress),
                    child: Container(
                      width: 132,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: completed
                              ? FireOpsSemanticColors.completed
                                  .withValues(alpha: 0.5)
                              : cs.outline.withValues(alpha: 0.25),
                        ),
                        color: completed
                            ? FireOpsSemanticColors.completed
                                .withValues(alpha: 0.08)
                            : cs.surface,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                completed
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 17,
                                color: completed
                                    ? FireOpsSemanticColors.completed
                                    : cs.onSurfaceVariant,
                              ),
                              const Spacer(),
                              Text(
                                completed ? 'Done' : '$progress%',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              stage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _stageProgress(String stage, String? currentRole) {
    final goalId = FireOpsCatalog.fireGoalIdForStageLabel(stage);
    if (goalId == null) return 0;

    if (currentRole != null && stage.trim().toLowerCase() == currentRole) {
      return 100;
    }

    final goalMatches =
        FireOpsCatalog.goals().where((goal) => goal.id == goalId);
    if (goalMatches.isEmpty) return 0;
    final goal = goalMatches.first;
    if (goal.requirements.isEmpty) return 0;

    final roadmapById = {
      for (final item in roadmap.all) item.requirement.id: item,
    };
    var found = 0;
    var done = 0;
    for (final requirement in goal.requirements) {
      final item = roadmapById[requirement.id];
      if (item == null) continue;
      found += 1;
      if (item.isComplete || item.isExcluded) done += 1;
    }
    if (found == 0) {
      final stageGoalIndex =
          FireOpsCatalog.fireOperationsLadder.indexOf(goalId);
      final targetIndex =
          FireOpsCatalog.fireOperationsLadder.indexOf(roadmap.goal.id);
      if (stageGoalIndex >= 0 && targetIndex >= 0 && stageGoalIndex < targetIndex) {
        return 100;
      }
      return 0;
    }
    return ((done / found) * 100).round();
  }

  Future<void> _showStage(
    BuildContext context,
    String stage,
    int progress,
  ) async {
    final goalId = FireOpsCatalog.fireGoalIdForStageLabel(stage);
    final matches = goalId == null
        ? const <CareerGoal>[]
        : FireOpsCatalog.goals().where((goal) => goal.id == goalId).toList();
    final goal = matches.isEmpty ? null : matches.first;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                stage,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                goal == null
                    ? 'Custom stage. Add the requirements that apply to your department.'
                    : '$progress% of the currently visible requirements for this stage are complete.',
              ),
              if (goal != null && goal.requirements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: goal.requirements
                        .map(
                          (requirement) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.checklist_rounded),
                            title: Text(requirement.name),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _CustomizePathSheet._showCareerStagesEditor(context, state);
                },
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Skip, replace, or customize stages'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialtyPathsSection extends StatelessWidget {
  final AppState state;

  const _SpecialtyPathsSection({required this.state});

  static const _specialties = <_SpecialtyDefinition>[
    _SpecialtyDefinition(
      id: 'wildland_fft2',
      title: 'Wildland Firefighter',
      description: 'NWCG-aligned FFT2 foundation and agency qualification path.',
      icon: Icons.local_fire_department_outlined,
    ),
    _SpecialtyDefinition(
      id: 'acting_officer',
      title: 'Acting Officer',
      description: 'Track preparation for department-approved acting assignments.',
      icon: Icons.supervisor_account_outlined,
    ),
    _SpecialtyDefinition(
      id: 'instructor',
      title: 'Instructor',
      description: 'Track teaching credentials, evaluations, and instructional experience.',
      icon: Icons.school_outlined,
    ),
    _SpecialtyDefinition(
      id: 'hazmat',
      title: 'HazMat',
      description: 'Track department or authority-defined hazardous materials development.',
      icon: Icons.warning_amber_rounded,
    ),
    _SpecialtyDefinition(
      id: 'technical_rescue',
      title: 'Technical Rescue',
      description: 'Track locally required rescue disciplines and team qualification steps.',
      icon: Icons.construction_outlined,
    ),
    _SpecialtyDefinition(
      id: 'medic',
      title: 'Medic',
      description: 'Track EMS credential and department-specific medic readiness separately from fire rank.',
      icon: Icons.medical_services_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specialty paths',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Optional development tracks that sit alongside your rank progression. Status here is personal tracking only; the appropriate department, state, NWCG, or other authority determines official qualification.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 8),
            ..._specialties.map(
              (specialty) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(specialty.icon),
                title: Text(
                  specialty.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${state.specialtyPathStatus(specialty.id)} · ${specialty.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openSpecialty(context, specialty),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSpecialty(
    BuildContext context,
    _SpecialtyDefinition specialty,
  ) async {
    const statuses = <String>[
      'Not Started',
      'In Progress',
      'Ready for Review',
      'Qualified',
    ];
    var selected = state.specialtyPathStatus(specialty.id);
    final goalMatches = FireOpsCatalog.goals()
        .where((goal) => goal.id == specialty.id)
        .toList();
    final goal = goalMatches.isEmpty ? null : goalMatches.first;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(specialty.icon),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        specialty.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(specialty.description),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  decoration:
                      const InputDecoration(labelText: 'Personal path status'),
                  items: statuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    selected = value;
                    await state.setSpecialtyPathStatus(specialty.id, value);
                    if (context.mounted) setModalState(() {});
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  selected == 'Qualified'
                      ? '“Qualified” records the status you selected. Responder Roadmap does not grant or authorize this qualification.'
                      : 'Responder Roadmap tracks your development; official authorization remains with the appropriate authority.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (goal != null && goal.requirements.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Path milestones',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: goal.requirements
                          .map(
                            (requirement) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.checklist_rounded),
                              title: Text(requirement.name),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialtyDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _SpecialtyDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _RoadmapHeader extends StatelessWidget {
  final String fromRole;
  final String goalTitle;
  final int percentReady;
  final DateTime? targetDate;

  const _RoadmapHeader({required this.fromRole, required this.goalTitle, required this.percentReady, required this.targetDate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fromRole, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Icon(Icons.arrow_downward, size: 18, color: cs.onSurfaceVariant),
          ),
          Text(goalTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$percentReady% Ready',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (targetDate != null)
                Text(
                  'Target: ${_fmtMonthYear(targetDate!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (percentReady / 100).clamp(0, 1),
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _GroupHeading extends StatelessWidget {
  final String title;
  final int count;
  const _GroupHeading({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
        Text('$count', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _NextActionCard extends StatelessWidget {
  final Requirement requirement;
  final bool emphasized;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onOpen;
  final VoidCallback onPrimary;

  const _NextActionCard({required this.requirement, required this.emphasized, required this.subtitle, required this.primaryLabel, required this.onOpen, required this.onPrimary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = emphasized ? cs.primaryContainer : cs.surface;
    final border = emphasized ? cs.primary.withValues(alpha: 0.18) : cs.outline.withValues(alpha: 0.14);
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(requirement.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimary,
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                child: Text(primaryLabel),
              ),
            ),
          ],
        ),
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
  final bool compactBadges;

  const _ReqTile({required this.requirement, required this.statusIcon, required this.statusColor, required this.onTap, this.compactBadges = false});

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
                        if (!compactBadges)
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
    final userAdded = r.id.contains('::dept_') || r.id.contains('::custom_');
    parts.add(userAdded
        ? 'User Added'
        : switch (r.requirementSource) {
            RequirementSource.commonlyRequired => 'Suggested',
            RequirementSource.recommended => 'Suggested',
            RequirementSource.stateRequirement => 'Official Source · Verify Current',
            RequirementSource.departmentRequirement => 'Department Source · Verify Current',
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
        'Requirements vary by state and department. Use this for planning—verify official requirements locally.',
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
          Text(roadmap.goal.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.xs),
          Text('$from → ${roadmap.goal.title}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.goalSetup),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Change end path'),
          ),
          const SizedBox(height: 4),
          Text(
            'Changing your end path keeps your credentials, career history, Quick Add records, and completed work. Only the future roadmap is rebuilt for the new goal.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
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
        Text('Edit Personal Roadmap', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: AppSpacing.xs),
        Text('Make this roadmap yours. Add, remove, or adjust personal milestones and requirements as your goal changes. Suggested items are planning guidance; Department Mode remains separate and official records are never changed here.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: AppSpacing.md),
        if (state.profile.effectiveCareerPath != CareerPath.ems) ...[
          OutlinedButton.icon(
            onPressed: () => _showCareerStagesEditor(context, state),
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('Customize career stages'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
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
                    label: const Text('Add roadmap item'),
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

  static Future<void> _showCareerStagesEditor(
    BuildContext context,
    AppState state,
  ) async {
    var stages = state.fireCareerStages;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> persist(List<String> next) async {
              stages = List<String>.from(next);
              await state.setFireCareerStages(stages);
              if (context.mounted) setModalState(() {});
            }

            Future<void> replaceStage(int index) async {
              final controller = TextEditingController(text: stages[index]);
              final replacement = await showDialog<String>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Replace career stage'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Your department’s stage or rank',
                      hintText: 'Example: Sergeant',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        controller.text.trim(),
                      ),
                      child: const Text('Replace'),
                    ),
                  ],
                ),
              );
              controller.dispose();
              if (replacement == null || replacement.trim().isEmpty) return;
              final next = List<String>.from(stages);
              next[index] = replacement.trim();
              await persist(next);
            }

            Future<void> addStage() async {
              final controller = TextEditingController();
              final value = await showDialog<String>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Add career stage'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Stage or rank',
                      hintText: 'Example: Senior Firefighter',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        controller.text.trim(),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
              controller.dispose();
              if (value == null || value.trim().isEmpty) return;
              await persist([...stages, value.trim()]);
            }

            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.82,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fire career progression',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This is a recommended path, not a rule. Skip stages your department does not use, replace a stage with your equivalent rank, or add another stage. Skipped default stages also remove that stage’s default requirement bundle from your Personal Roadmap. You can add your own requirements separately.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: stages.length,
                      onReorder: (oldIndex, newIndex) async {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final next = List<String>.from(stages);
                        final item = next.removeAt(oldIndex);
                        next.insert(newIndex, item);
                        await persist(next);
                      },
                      itemBuilder: (context, index) {
                        final label = stages[index];
                        return Card(
                          key: ValueKey('$index-$label'),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              label,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: const Text('Drag to reorder'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'replace') {
                                  await replaceStage(index);
                                } else if (value == 'skip') {
                                  final next = List<String>.from(stages)
                                    ..removeAt(index);
                                  await persist(next);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'replace',
                                  child: Text('Replace this stage'),
                                ),
                                PopupMenuItem(
                                  value: 'skip',
                                  child: Text('Skip this stage'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: addStage,
                            icon: const Icon(Icons.add),
                            label: const Text('Add stage'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              await state.resetFireCareerStages();
                              stages = state.fireCareerStages;
                              if (context.mounted) setModalState(() {});
                            },
                            child: const Text('Restore defaults'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
