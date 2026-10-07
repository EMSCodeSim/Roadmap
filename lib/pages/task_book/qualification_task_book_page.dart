import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/advanced_certification_guide_data.dart';
import 'package:firepath/services/certification_guide_library.dart';
import 'package:firepath/services/national_task_book_baseline.dart';
import 'package:firepath/services/task_book_checklist_hierarchy.dart';
import 'package:firepath/services/state_fire_authority_catalog.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';

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
    final completionGates =
        TaskBookLibrary.certificationCompletionGates(req);
    final custom = state.customTasksFor(goalId: goalId, requirementId: req.id);
    final tasks = [
      ...base,
      ...guideTasks,
      ...completionGates,
      ...custom,
    ];
    final grouped = <String, List<TaskBookTaskDefinition>>{};
    for (final t in tasks) {
      (grouped[t.section] ??= <TaskBookTaskDefinition>[]).add(t);
    }
    const sectionOrder = [
      'PLAN THE CERTIFICATION',
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
        : ((completed / total).clamp(0, 1)).toDouble();

    final currentPhaseIndex = orderedSections.indexWhere((section) {
      final items = grouped[section] ?? const <TaskBookTaskDefinition>[];
      return items.any((task) => statusFor(task) != TaskBookTaskStatus.complete);
    });
    final resolvedPhaseIndex =
        currentPhaseIndex < 0 ? orderedSections.length - 1 : currentPhaseIndex;

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
            _BuildTaskBookCard(
              requirement: req,
              goalId: goalId,
              authority: authority,
              customTasks: custom,
              savedLinks: state.userResourceLinksFor(
                goalId: goalId,
                requirementId: req.id,
              ),
              onAddRequirement: () => _addPresetTask(
                context,
                goalId: goalId,
                req: req,
                section: 'PLAN THE CERTIFICATION',
                titlePrompt: 'Missing requirement',
                titleHint: 'Example: Complete department prerequisite course',
                objective:
                    'Add a requirement you found in the current official state, academy, testing-provider, or department process.',
              ),
              onAddJpr: () => _addPresetTask(
                context,
                goalId: goalId,
                req: req,
                section: 'PRACTICAL / JPR PREPARATION',
                titlePrompt: 'Official JPR / practical station',
                titleHint: 'Example: Master JPR — vehicle extrication',
                objective:
                    'Practice this official JPR or practical station using the current evaluator criteria until performance is consistent.',
                performanceTasks: const [
                  'Review the current official JPR / evaluator criteria.',
                  'Practice the station with the required equipment and conditions.',
                  'Repeat weak steps until performance is consistent.',
                  'Move to Ready for Evaluation when prepared for formal evaluation.',
                ],
              ),
              onAddReading: () => _addPresetTask(
                context,
                goalId: goalId,
                req: req,
                section: 'TRAINING',
                titlePrompt: 'Required reading',
                titleHint: 'Example: Read Chapter 3 — fire attack',
                objective:
                    'Track required reading from the current course, academy, candidate handbook, textbook, or authority.',
                performanceTasks: const [
                  'Complete the assigned reading.',
                  'Note weak topics or material that needs review.',
                ],
              ),
              onAddTestingStep: () => _addPresetTask(
                context,
                goalId: goalId,
                req: req,
                section: 'TESTING',
                titlePrompt: 'Testing / registration step',
                titleHint: 'Example: Register for written test',
                objective:
                    'Track a testing, application, registration, deadline, fee, or scheduling step required by your actual certification pathway.',
              ),
              onAddLink: () => _addUsefulLink(
                context,
                goalId: goalId,
                req: req,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (orderedSections.isNotEmpty) ...[
              _CertificationPhaseRail(
                sections: orderedSections,
                grouped: grouped,
                statusFor: statusFor,
                currentIndex: resolvedPhaseIndex,
              ),
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
                if (section == 'TESTING' &&
                    NationalTaskBookBaseline.standardFor(req) != null) ...[
                  _NationalBaselineSection(
                    goalId: goalId,
                    requirement: req,
                    state: state,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
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
            }),
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

  Future<void> _addPresetTask(
    BuildContext context, {
    required String goalId,
    required Requirement req,
    required String section,
    required String titlePrompt,
    required String titleHint,
    required String objective,
    List<String> performanceTasks = const [],
  }) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titlePrompt),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Task',
            hintText: titleHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Add to Task Book'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || !context.mounted) return;

    final now = DateTime.now();
    await context.read<AppState>().addCustomTask(
      TaskBookTaskDefinition(
        id: 'custom_${now.microsecondsSinceEpoch.toRadixString(36)}',
        title: title,
        section: section,
        goalId: goalId,
        requirementId: req.id,
        isCustom: true,
        fireOpsObjective: objective,
        whatToKnow: const [],
        performanceTasks: performanceTasks,
        safetyPoints: const [],
        commonMistakes: const [],
        practiceTools: const [],
        resources: const [],
      ),
    );
  }

  Future<void> _addUsefulLink(
    BuildContext context, {
    required String goalId,
    required Requirement req,
  }) async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final result = await showDialog<ResourceLink>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add official or useful link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Link name',
                hintText: 'Example: Firefighter II JPR packet',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final url = urlController.text.trim();
              final uri = Uri.tryParse(url);
              if (title.isEmpty || uri == null || !uri.hasScheme) return;
              Navigator.pop(
                dialogContext,
                ResourceLink(title: title, url: url),
              );
            },
            child: const Text('Save link'),
          ),
        ],
      ),
    );
    titleController.dispose();
    urlController.dispose();
    if (result == null || !context.mounted) return;
    await context.read<AppState>().addUserResourceLink(
      goalId: goalId,
      requirementId: req.id,
      link: result,
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

class _BuildTaskBookCard extends StatelessWidget {
  const _BuildTaskBookCard({
    required this.requirement,
    required this.goalId,
    required this.authority,
    required this.customTasks,
    required this.savedLinks,
    required this.onAddRequirement,
    required this.onAddJpr,
    required this.onAddReading,
    required this.onAddTestingStep,
    required this.onAddLink,
  });

  final Requirement requirement;
  final String goalId;
  final StateFireAuthority? authority;
  final List<TaskBookTaskDefinition> customTasks;
  final List<ResourceLink> savedLinks;
  final VoidCallback onAddRequirement;
  final VoidCallback onAddJpr;
  final VoidCallback onAddReading;
  final VoidCallback onAddTestingStep;
  final VoidCallback onAddLink;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final jprs = customTasks
        .where((task) => task.section == 'PRACTICAL / JPR PREPARATION')
        .length;
    final reading =
        customTasks.where((task) => task.section == 'TRAINING').length;
    final localRequirements = customTasks
        .where((task) => task.section == 'PLAN THE CERTIFICATION')
        .length;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.build_outlined, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUILD THIS TASK BOOK',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                    ),
                    Text(
                      'Make the starter book match your real requirements',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The premade book is a starting point. Use the current official state/certifying source, your academy or testing provider, and your department requirements to add anything missing. Keep this book updated as the process changes.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 12),
          _BuilderAction(
            icon: Icons.public_outlined,
            title: '1. Look up official requirements',
            detail: authority == null
                ? 'Set your state in Profile, then open the official source.'
                : authority!.sourceTitle,
            action: authority == null ? null : 'Open',
            onTap: authority == null
                ? null
                : () async {
                    final uri = Uri.tryParse(authority!.sourceUrl);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
          ),
          _BuilderAction(
            icon: Icons.add_task_outlined,
            title: '2. Add missing requirements',
            detail: localRequirements == 0
                ? 'Add prerequisites, academy steps, department rules, or paperwork the starter book does not know about.'
                : '$localRequirements local requirement${localRequirements == 1 ? '' : 's'} added',
            action: 'Add',
            onTap: onAddRequirement,
          ),
          _BuilderAction(
            icon: Icons.fact_check_outlined,
            title: '3. Add every official JPR / practical station',
            detail: jprs == 0
                ? 'Use the official JPR/evaluator packet. Add one task per station so each can be practiced and evaluated.'
                : '$jprs local JPR/practical task${jprs == 1 ? '' : 's'} added',
            action: 'Add JPR',
            onTap: onAddJpr,
          ),
          _BuilderAction(
            icon: Icons.menu_book_outlined,
            title: '4. Add required reading',
            detail: reading == 0
                ? 'Add assigned chapters, candidate-handbook sections, protocols, standards, or academy modules.'
                : '$reading local reading/training item${reading == 1 ? '' : 's'} added',
            action: 'Add reading',
            onTap: onAddReading,
          ),
          _BuilderAction(
            icon: Icons.event_available_outlined,
            title: '5. Add testing and registration steps',
            detail:
                'Add your real written/practical registration, deadlines, fees, test dates, retest rules, and issuance steps.',
            action: 'Add step',
            onTap: onAddTestingStep,
          ),
          _BuilderAction(
            icon: Icons.link_outlined,
            title: '6. Save the links you actually use',
            detail: savedLinks.isEmpty
                ? 'Save the JPR packet, candidate handbook, testing portal, course page, or department reference inside the book.'
                : '${savedLinks.length} saved link${savedLinks.length == 1 ? '' : 's'}',
            action: 'Add link',
            onTap: onAddLink,
          ),
          if (savedLinks.isNotEmpty) ...[
            const Divider(height: 22),
            ...savedLinks.take(5).map(
                  (link) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.open_in_new, size: 18),
                    title: Text(link.title),
                    subtitle: link.url == null ? null : Text(link.url!),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: link.url == null
                        ? null
                        : () async {
                            final uri = Uri.tryParse(link.url!);
                            if (uri != null) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _BuilderAction extends StatelessWidget {
  const _BuilderAction({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: cs.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        detail,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      trailing: action == null
          ? null
          : TextButton(
              onPressed: onTap,
              child: Text(action!),
            ),
      onTap: onTap,
    );
  }
}

class _NationalBaselineSection extends StatelessWidget {
  const _NationalBaselineSection({
    required this.goalId,
    required this.requirement,
    required this.state,
  });

  final String goalId;
  final Requirement requirement;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final standard = NationalTaskBookBaseline.standardFor(requirement);
    if (standard == null) return const SizedBox.shrink();

    final controller = state.taskBookController;
    final steps = NationalTaskBookBaseline.effectiveSteps(
      requirement,
      controller.planStepsFor(
        goalId: goalId,
        requirementId: requirement.id,
      ),
    );
    final subTasks = NationalTaskBookBaseline.effectiveSubTasks(
      requirement,
      controller.subTasksFor(
        goalId: goalId,
        requirementId: requirement.id,
      ),
    );

    final total = subTasks.length;
    final done = subTasks.where((item) => item.isDone).length;
    final cs = Theme.of(context).colorScheme;

    Future<void> toggleChild(
      RequirementPlanStep parent,
      RequirementSubTask child,
      bool value,
    ) async {
      await controller.upsertSubTask(
        goalId: goalId,
        requirementId: requirement.id,
        subTask: child.copyWith(isDone: value),
      );
      final updated = NationalTaskBookBaseline.effectiveSubTasks(
        requirement,
        controller.subTasksFor(
          goalId: goalId,
          requirementId: requirement.id,
        ),
      );
      final parentDone = TaskBookChecklistHierarchy.stepCompleteFromChildren(
        parent.id,
        updated,
      );
      if (parentDone != parent.isDone) {
        await controller.upsertPlanStep(
          goalId: goalId,
          requirementId: requirement.id,
          step: parent.copyWith(isDone: parentDone),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'SKILLS / JPR MASTERY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ),
            Text(
              '$done/$total',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${standard.citation} national baseline • complete these alongside your official state, academy, and department JPRs.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...steps.map((step) {
          final children =
              TaskBookChecklistHierarchy.childrenFor(step.id, subTasks);
          final childDone = children.where((item) => item.isDone).length;
          final complete = children.isNotEmpty
              ? childDone == children.length
              : step.isDone;

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: Icon(
                complete
                    ? Icons.check_circle_rounded
                    : Icons.fact_check_outlined,
                color: complete
                    ? FireOpsSemanticColors.completed
                    : cs.primary,
              ),
              title: Text(
                step.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '$childDone of ${children.length} objectives complete',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              children: [
                ...children.map(
                  (child) => CheckboxListTile(
                    value: child.isDone,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(child.title),
                    subtitle: TaskBookChecklistHierarchy.visibleNotes(child) ==
                            null
                        ? null
                        : Text(
                            TaskBookChecklistHierarchy.visibleNotes(child)!,
                          ),
                    onChanged: (value) =>
                        toggleChild(step, child, value ?? false),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Use the current official evaluator/JPR packet for exact testing criteria.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _CertificationPhaseRail extends StatelessWidget {
  const _CertificationPhaseRail({
    required this.sections,
    required this.grouped,
    required this.statusFor,
    required this.currentIndex,
  });

  final List<String> sections;
  final Map<String, List<TaskBookTaskDefinition>> grouped;
  final TaskBookTaskStatus Function(TaskBookTaskDefinition) statusFor;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CERTIFICATION PHASES',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sections.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ),
              itemBuilder: (context, index) {
                final section = sections[index];
                final tasks =
                    grouped[section] ?? const <TaskBookTaskDefinition>[];
                final done = tasks
                    .where((task) =>
                        statusFor(task) == TaskBookTaskStatus.complete)
                    .length;
                final complete = tasks.isNotEmpty && done == tasks.length;
                final current = index == currentIndex && !complete;
                final label = _phaseLabel(section);
                return Container(
                  width: 128,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: complete
                          ? FireOpsSemanticColors.completed.withValues(alpha: 0.5)
                          : current
                              ? cs.primary.withValues(alpha: 0.65)
                              : cs.outline.withValues(alpha: 0.18),
                    ),
                    color: complete
                        ? FireOpsSemanticColors.completed.withValues(alpha: 0.08)
                        : current
                            ? cs.primaryContainer.withValues(alpha: 0.35)
                            : cs.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        complete
                            ? Icons.check_circle_rounded
                            : current
                                ? Icons.radio_button_checked_rounded
                                : Icons.circle_outlined,
                        size: 17,
                        color: complete
                            ? FireOpsSemanticColors.completed
                            : current
                                ? cs.primary
                                : cs.onSurfaceVariant,
                      ),
                      const Spacer(),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        complete
                            ? 'Complete'
                            : current
                                ? 'Do this now'
                                : '$done/${tasks.length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Work left to right. Later phases stay visible so you can plan ahead, but Today guidance will favor the earliest incomplete phase.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  static String _phaseLabel(String section) => switch (section) {
        'PLAN THE CERTIFICATION' => 'Plan',
        'GETTING STARTED' => 'Start',
        'TRAINING' => 'Learn',
        'PRACTICAL / JPR PREPARATION' => 'Practice / Master',
        'TESTING' => 'Test',
        'CERTIFICATION' => 'Credential',
        'KNOWLEDGE' => 'Knowledge',
        'APPARATUS OPERATIONS' => 'Operations',
        'PERFORMANCE' => 'Performance',
        _ => section,
      };
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Use this screen as your working guide. The steps below should answer what applies, what to study, which JPRs to practice, how to prepare for testing, and what to save when you earn the credential.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHAT THIS ROADMAP SHOULD HELP YOU CONFIRM',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                const Text('• Eligibility and prerequisite credentials'),
                const Text('• Current state / certifying-authority requirements'),
                const Text('• Applicable standard and official JPR / practical packet'),
                const Text('• Required course, academy, or department training'),
                const Text('• Required textbook, edition, chapters, and candidate handbook'),
                const Text('• Written and practical test eligibility and registration'),
                const Text('• Application, fees, deadlines, and credential submission'),
                const SizedBox(height: 8),
                Text(
                  'If an exact book, chapter, JPR, fee, or deadline is not published by the applicable authority/provider, add it after you confirm it. Responder Roadmap should never guess an official requirement.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
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
            label: Text(
              authority.stateCode == 'CO'
                  ? 'Open current DFPC certification manual'
                  : 'Open official requirements',
            ),
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

    final (icon, color, label) = switch (status) {
      TaskBookTaskStatus.complete => (
          Icons.check_circle,
          FireOpsSemanticColors.completed,
          'Complete',
        ),
      TaskBookTaskStatus.readyForEvaluation => (
          Icons.verified_outlined,
          FireOpsSemanticColors.blue,
          'Ready for evaluation',
        ),
      TaskBookTaskStatus.learning => (
          Icons.menu_book_outlined,
          FireOpsSemanticColors.blue,
          'Learning',
        ),
      TaskBookTaskStatus.practicing => (
          Icons.play_circle_outline,
          FireOpsSemanticColors.amber,
          'Practicing',
        ),
      TaskBookTaskStatus.notStarted => (
          Icons.circle_outlined,
          FireOpsSemanticColors.gray,
          'Not started',
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
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: color.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        if ((task.fireOpsObjective ?? '').trim().isNotEmpty)
                          Text(
                            task.fireOpsObjective!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (task.isCustom)
                PopupMenuButton<String>(
                  tooltip: 'Edit Task Book item',
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _editCustomTask(context);
                    } else if (value == 'delete') {
                      await context.read<AppState>().deleteCustomTask(
                            goalId: goalId,
                            requirementId: requirementId,
                            taskId: task.id,
                          );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit item'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete item'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                )
              else
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editCustomTask(BuildContext context) async {
    final titleController = TextEditingController(text: task.title);
    final sectionController = TextEditingController(text: task.section);
    final objectiveController =
        TextEditingController(text: task.fireOpsObjective ?? '');

    final updated = await showDialog<TaskBookTaskDefinition>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Task Book item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Task'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: sectionController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  hintText: 'TESTING',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: objectiveController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Directions / objective',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(
                dialogContext,
                TaskBookTaskDefinition(
                  id: task.id,
                  title: title,
                  section: sectionController.text.trim().isEmpty
                      ? task.section
                      : sectionController.text.trim().toUpperCase(),
                  goalId: task.goalId,
                  requirementId: task.requirementId,
                  isCustom: true,
                  fireOpsObjective:
                      objectiveController.text.trim().isEmpty
                          ? null
                          : objectiveController.text.trim(),
                  whatToKnow: task.whatToKnow,
                  performanceTasks: task.performanceTasks,
                  safetyPoints: task.safetyPoints,
                  commonMistakes: task.commonMistakes,
                  practiceTools: task.practiceTools,
                  resources: task.resources,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    titleController.dispose();
    sectionController.dispose();
    objectiveController.dispose();

    if (updated == null || !context.mounted) return;
    await context.read<AppState>().updateCustomTask(updated);
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
