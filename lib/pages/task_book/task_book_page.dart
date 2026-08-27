import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/custom_task_book.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/national_task_book_baseline.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/state_requirement_catalog.dart';
import 'package:firepath/services/requirement_source_presenter.dart';
import 'package:firepath/services/task_book_setup_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/status_pill.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/services/quick_log_path_suggester.dart';
import 'package:firepath/services/task_book_stage_planner.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';

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
    final activeCustom = state.activeCustomTaskBook;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: FirefighterRoadmapAppBar(
        subtitle: activeCustom == null
            ? 'Task Book · Career Road'
            : 'Task Book · ${activeCustom.name}',
        actions: [
          IconButton(
            tooltip: 'Switch Task Book',
            onPressed: () => _showSwitcher(context),
            icon: const Icon(Icons.swap_horiz),
          ),
          if (activeCustom == null && roadmap != null)
            PopupMenuButton<String>(
              tooltip: 'Task Book options',
              onSelected: (value) async {
                switch (value) {
                  case 'review':
                    context.push(AppRoutes.taskBookReview);
                    break;
                  case 'rebuild':
                    try {
                      await TaskBookSetupStore().setReviewPending(true);
                      await context.read<AppState>().rebuildTaskBookForCurrentState();
                      if (!context.mounted) return;
                      context.push(AppRoutes.taskBookReview);
                    } catch (e) {
                      debugPrint('TaskBookPage rebuild-from-menu failed: $e');
                    }
                    break;
                  case 'create_custom':
                    context.push(AppRoutes.customTaskBookCreate);
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'review', child: Text('Your Task Book is Ready')),
                PopupMenuItem(value: 'rebuild', child: Text('Rebuild from current info')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'create_custom', child: Text('Create department Task Book')),
              ],
              icon: const Icon(Icons.more_horiz),
            ),
          if (activeCustom == null && roadmap != null)
            IconButton(
              tooltip: 'Customize Career Road Task Book',
              onPressed: () => context.push(AppRoutes.myPathLegacy),
              icon: const Icon(Icons.tune),
            ),
        ],
      ),
      body: activeCustom != null
          ? _CustomTaskBookBody(book: activeCustom)
          : (roadmap == null
              ? Padding(
                  padding: AppSpacing.paddingLg,
                  child: _NoGoalEmpty(
                    onChooseGoal: () => context.go(AppRoutes.goalSetup),
                    onCreateCustom: () =>
                        context.push(AppRoutes.customTaskBookCreate),
                    customBooks: state.customTaskBooks,
                  ),
                )
              : _TaskBookBody(roadmapGoalId: roadmap.goal.id)),
    );
  }

  static Future<void> _showSwitcher(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surface,
      builder: (context) {
        return Consumer<AppState>(
          builder: (context, state, _) {
            final books = state.customTaskBooks;
            final activeId = state.activeTaskBookId;
            final activeCustom = state.activeCustomTaskBook;
            final activeLabel = activeCustom == null ? 'Career Road' : activeCustom.name;

            final visibleBooks = books.where((b) => !b.archived).toList();
            final archivedBooks = books.where((b) => b.archived).toList();

            Future<void> select(String? id) async {
              await state.taskBookController.setActiveTaskBook(id);
              if (context.mounted) context.pop();
            }

            Future<void> manage(CustomTaskBook book, String action) async {
              switch (action) {
                case 'rename':
                  final next = await _promptRenameBottomSheet(context, book.name);
                  if (next == null) return;
                  await state.taskBookController.renameCustomTaskBook(taskBookId: book.id, name: next);
                  break;
                case 'duplicate':
                  await state.taskBookController.duplicateCustomTaskBook(book.id);
                  break;
                case 'archive':
                  await state.taskBookController.archiveCustomTaskBook(taskBookId: book.id, archived: true);
                  break;
                case 'unarchive':
                  await state.taskBookController.archiveCustomTaskBook(taskBookId: book.id, archived: false);
                  break;
              }
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Task Books', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      'Active: $activeLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      selected: activeId == null,
                      icon: Icons.route_outlined,
                      title: 'Career Road',
                      subtitle: 'Built from your Next Level + certs. Use this as your main path.',
                      onTap: () => select(null),
                    ),
                    if (visibleBooks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('DEPARTMENT / CUSTOM', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      ...visibleBooks.map((b) {
                        return _SwitchTile(
                          selected: activeId == b.id,
                          icon: b.departmentSpecific ? Icons.apartment_outlined : Icons.book_outlined,
                          title: b.name,
                          subtitle: '${b.requirements.length} requirements',
                          onTap: () => select(b.id),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Manage',
                            onSelected: (v) => manage(b, v),
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'rename', child: Text('Rename')),
                              PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                              PopupMenuItem(value: 'archive', child: Text('Archive')),
                            ],
                            icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
                          ),
                        );
                      }),
                    ],
                    if (archivedBooks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        collapsedIconColor: cs.onSurfaceVariant,
                        iconColor: cs.onSurfaceVariant,
                        title: Text('ARCHIVED', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
                        children: archivedBooks
                            .map((b) => _SwitchTile(
                                  selected: activeId == b.id,
                                  icon: Icons.archive_outlined,
                                  title: b.name,
                                  subtitle: '${b.requirements.length} requirements',
                                  onTap: () => select(b.id),
                                  trailing: PopupMenuButton<String>(
                                    tooltip: 'Manage',
                                    onSelected: (v) => manage(b, v),
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                                      PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                                      PopupMenuItem(value: 'unarchive', child: Text('Unarchive')),
                                    ],
                                    icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.pop();
                          context.push(AppRoutes.customTaskBookCreate);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create department Task Book'),
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
  }

  static Future<String?> _promptRenameBottomSheet(BuildContext context, String current) async {
    final ctrl = TextEditingController(text: current);
    final cs = Theme.of(context).colorScheme;
    final next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      builder: (context) {
        final inset = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.only(bottom: inset.bottom),
          child: SafeArea(
            child: Padding(
               padding: const EdgeInsets.fromLTRB(
                 AppSpacing.md,
                 AppSpacing.sm,
                 AppSpacing.md,
                 AppSpacing.lg,
               ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Rename Task Book', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () => context.pop(ctrl.text.trim()),
                      child: const Text('Save Name'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    ctrl.dispose();
    return next?.trim().isEmpty == true ? null : next;
  }
}

class _SwitchTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  const _SwitchTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = selected ? cs.primary.withValues(alpha: 0.25) : cs.outline.withValues(alpha: 0.14);
    final bg = selected ? cs.primaryContainer.withValues(alpha: 0.55) : cs.surfaceContainerHighest.withValues(alpha: 0.22);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailing != null) trailing!,
            if (selected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: cs.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomTaskBookBody extends StatelessWidget {
  final CustomTaskBook book;
  const _CustomTaskBookBody({required this.book});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final goalId = book.pseudoGoalId;

    final list = [...book.requirements];
    bool completeFor(Requirement r) {
      final o = state.taskBookController.getOverride(goalId, r.id);
      return (o?.completed ?? r.completed) == true;
    }

    final plan = TaskBookStagePlanner.buildPlan<Requirement>(
      items: list,
      getRequirement: (r) => r,
      isComplete: (r) => completeFor(r),
      getId: (r) => r.id,
    );

    final pct = plan.total <= 0 ? 0.0 : (plan.completedTotal / plan.total).clamp(0, 1).toDouble();

    return SafeArea(
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUSTOM TASK BOOK',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(book.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text('${(pct * 100).round()}% complete', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    ),
                    Text('${plan.completedTotal}/${list.length}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.customTaskBookBuilder, extra: {'taskBookId': book.id}),
                          icon: const Icon(Icons.build_outlined),
                          label: const Text('Edit / Build'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => TaskBookPage._showSwitcher(context),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Switch'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...plan.sections.map((section) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _TaskBookStageSectionCard<Requirement>(
                section: section,
                goalId: goalId,
                suggestedNextRequirementId: plan.suggestedNext?.requirement.id,
                openRequirement: (r) => AppRouter.openRequirement(
                  context,
                  r,
                  goalId: goalId,
                ),
              ),
            );
          }),
          if (list.isEmpty)
            Text(
              'No requirements yet. Tap “Edit / Build Task Book” to add your first item.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
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

    final profileState = FireOpsCatalog.stateCodeFromLegacyValue(state.profile.state);
    final hasVerifiedStateData = profileState != null &&
        profileState.isNotEmpty &&
        profileState != FireOpsCatalog.otherStateCode &&
        StateRequirementCatalog.hasVerifiedDataForGoal(
          stateCode: profileState,
          careerGoalId: roadmap.goal.id,
        );

    final percent = (roadmap.percentComplete * 100).round();
    final target = state.profile.careerPlan.targetDate;

    final next = roadmap.nextStep?.requirement;

    final plan = TaskBookStagePlanner.buildPlan<RoadmapRequirement>(
      items: roadmap.included,
      getRequirement: (raw) => raw.requirement,
      isComplete: (raw) => raw.isComplete,
      getId: (raw) => raw.requirement.id,
    );

    return SafeArea(
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          if (_reviewPending)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _StateChangedCard(
                fromLabel:
                    FireOpsCatalog.stateNameForCode(state.profile.state) ??
                    'your state',
                onRebuild: () async {
                  try {
                      await _setupStore.setReviewPending(true);
                      await context.read<AppState>().rebuildTaskBookForCurrentState();
                      if (!mounted) return;
                      context.push(AppRoutes.taskBookReview);
                  } catch (e) {
                    debugPrint('TaskBook rebuild failed: $e');
                  }
                },
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
            stateCode: profileState,
            hasVerifiedStateData: hasVerifiedStateData,
          ),
          const SizedBox(height: AppSpacing.lg),
          _NextTaskCard(
            title: next?.name,
            onContinue: next == null
                ? null
                : () => AppRouter.openRequirement(
                    context,
                    next,
                    goalId: roadmap.goal.id,
                  ),
            onQuickLog: next == null
                ? null
                : () {
                    final suggestions = QuickLogPathSuggester.suggestionsFor(state);
                    if (suggestions.isNotEmpty) {
                      final suggestion = suggestions.first;
                      QuickLogLauncher.open(context, prefill: suggestion.prefill);
                      return;
                    }
                    QuickLogLauncher.open(
                      context,
                      prefill: LogPrefill(
                        title: next.name,
                        category: next.name,
                        relatedGoalId: roadmap.goal.id,
                        relatedRequirementId: next.id,
                        relatedTaskId: null,
                        tags: const ['task-book', 'next-step'],
                      ),
                    );
                  },
          ),
          const SizedBox(height: AppSpacing.lg),
          ...plan.sections.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _TaskBookStageSectionCard<RoadmapRequirement>(
                section: s,
                goalId: roadmap.goal.id,
                suggestedNextRequirementId: plan.suggestedNext?.requirement.id,
                openRequirement: (r) => AppRouter.openRequirement(
                  context,
                  r,
                  goalId: roadmap.goal.id,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Keep the custom/department Task Book entry point easy to find, but
          // visually secondary once the user is actively working their path.
          _DepartmentTaskBookEntryCard(
            customBooks: state.customTaskBooks,
            onCreate: () => context.push(AppRoutes.customTaskBookCreate),
            onSwitch: () => TaskBookPage._showSwitcher(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'FireOps preparation tasks are designed to help organize training and professional development. Always verify certification and performance requirements with your department, state authority, official task book, or certifying organization.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _GoalHeader extends StatelessWidget {
  final String goalTitle;
  final int percent;
  final int completed;
  final int total;
  final DateTime? targetDate;
  final String? stateCode;
  final bool hasVerifiedStateData;

  const _GoalHeader({
    required this.goalTitle,
    required this.percent,
    required this.completed,
    required this.total,
    required this.targetDate,
    required this.stateCode,
    required this.hasVerifiedStateData,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stateName = FireOpsCatalog.stateNameForCode(stateCode);
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
          Text(
            'CAREER TASK BOOK',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            goalTitle,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$percent% Ready',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (targetDate != null)
                Text(
                  'Target: ${_fmtMonthYear(targetDate!)}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$completed of $total requirements complete',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StateContextLine(
            stateName: stateName,
            hasVerifiedStateData: hasVerifiedStateData,
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              backgroundColor: cs.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
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
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _StateChangedCard extends StatelessWidget {
  final String fromLabel;
  final VoidCallback onRebuild;
  final VoidCallback onReview;
  final VoidCallback onNotNow;
  const _StateChangedCard({
    required this.fromLabel,
    required this.onRebuild,
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
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your profile state is now set to $fromLabel. Want to refresh your Task Book to match updated state requirements (while keeping your department/custom items)?',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: cs.onSurface, height: 1.45),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: onRebuild,
              child: const Text('Rebuild Task Book'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: onReview,
              child: const Text('Review Changes First'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: TextButton(
              onPressed: onNotNow,
              child: const Text('Not now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateContextLine extends StatelessWidget {
  final String? stateName;
  final bool hasVerifiedStateData;
  const _StateContextLine({required this.stateName, required this.hasVerifiedStateData});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = stateName;
    if (name == null || name.trim().isEmpty) {
      return Text(
        'Set your state to tailor requirements (and clearly label state-required items).',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
      );
    }

    if (hasVerifiedStateData) {
      return Text(
        'Based on verified $name requirements where available, plus common recommendations and department items.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Text(
        'No verified state-specific data for $name yet — showing common recommendations. Verify with your department and your state fire/EMS training authority.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
      ),
    );
  }
}

class _NextTaskCard extends StatelessWidget {
  final String? title;
  final VoidCallback? onContinue;
  final VoidCallback? onQuickLog;
  const _NextTaskCard({required this.title, required this.onContinue, required this.onQuickLog});

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
          Text(
            'NEXT BEST STEP',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title ?? 'You’re caught up',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                    ),
                    child: Text(title == null ? 'Review Task Book' : 'Open task'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 54,
                  height: 52,
                  child: FilledButton.tonalIcon(
                    onPressed: onQuickLog,
                    icon: const Icon(Icons.bolt_outlined),
                    label: const Text(''),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskBookStageSectionCard<T> extends StatelessWidget {
  final TaskBookStageSection<T> section;
  final String goalId;
  final String? suggestedNextRequirementId;
  final ValueChanged<Requirement> openRequirement;

  const _TaskBookStageSectionCard({
    required this.section,
    required this.goalId,
    required this.suggestedNextRequirementId,
    required this.openRequirement,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = section.completedCount;
    final total = section.totalCount;
    final pct = total <= 0 ? 0.0 : (completed / total).clamp(0, 1).toDouble();
    final defaultCollapsed = total > 0 && completed == total;

    final progressLabel = total <= 0 ? '—' : '$completed of $total';
    final isDone = total > 0 && completed >= total;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
          initiallyExpanded: !defaultCollapsed,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${section.meta.title} · $progressLabel',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (isDone) ...[
                    const SizedBox(width: 8),
                    StatusPill(
                      text: 'Done',
                      backgroundColor: FireOpsSemanticColors.completed.withValues(alpha: 0.14),
                      foregroundColor: FireOpsSemanticColors.completed,
                      maxWidth: 84,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                section.meta.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
          ),
          children: [
            if (section.items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'No items in this stage for your current Task Book.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < section.items.length; i++) ...[
                      _StagedRequirementRow(
                        requirement: section.items[i].requirement,
                        goalId: goalId,
                        isComplete: section.items[i].isComplete,
                        suggestedNext: suggestedNextRequirementId != null && suggestedNextRequirementId == section.items[i].requirement.id,
                        canStartNow: section.items[i].canStartNow,
                        unmetPrereqLabels: section.items[i].unmetPrerequisiteLabels,
                        showDivider: i != section.items.length - 1,
                        onOpen: () => openRequirement(section.items[i].requirement),
                        rowKey: Key(
                          'task-book-requirement-${section.items[i].requirement.id}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}

class _StagedRequirementRow extends StatelessWidget {
  final Requirement requirement;
  final String goalId;
  final bool isComplete;
  final bool suggestedNext;
  final bool canStartNow;
  final List<String> unmetPrereqLabels;
  final bool showDivider;
  final VoidCallback onOpen;
  final Key? rowKey;

  const _StagedRequirementRow({
    required this.requirement,
    required this.goalId,
    required this.isComplete,
    required this.suggestedNext,
    required this.canStartNow,
    required this.unmetPrereqLabels,
    required this.showDivider,
    required this.onOpen,
    this.rowKey,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final cs = Theme.of(context).colorScheme;
    final r = requirement;
    final profileState = FireOpsCatalog.stateCodeFromLegacyValue(state.profile.state);
    final icon = isComplete ? Icons.check_circle : (canStartNow ? Icons.circle_outlined : Icons.lock_outline);
    final iconColor = isComplete
        ? FireOpsSemanticColors.completed
        : (canStartNow ? cs.onSurfaceVariant : FireOpsSemanticColors.warning);

    final badge = RequirementSourcePresenter.badgeText(r, profileStateCode: profileState);
    final badgeColors = RequirementSourcePresenter.badgeColors(context, r);

    String? trailing;
    if (r.type == RequirementType.numericProgress && r.progressCurrent != null && r.progressRequired != null) {
      final unit = r.progressUnit;
      trailing = '${r.progressCurrent!.toStringAsFixed(0)} / ${r.progressRequired!.toStringAsFixed(0)}${unit == null ? '' : ' $unit'}';
    } else if (NationalTaskBookBaseline.standardFor(r) != null) {
      final subTasks = NationalTaskBookBaseline.effectiveSubTasks(
        r,
        state.subTasksFor(goalId: goalId, requirementId: r.id),
      );
      trailing = '${subTasks.where((item) => item.isDone).length} / ${subTasks.length} skills';
    }

    final prereqLine = unmetPrereqLabels.isEmpty ? null : 'Prerequisites: ${unmetPrereqLabels.take(2).join(', ')}${unmetPrereqLabels.length > 2 ? '…' : ''}';
    final dim = !isComplete && !canStartNow;

    final String statusLabel = isComplete
        ? 'Complete'
        : (canStartNow ? 'Ready' : 'Locked');
    final Color statusBg = isComplete
        ? FireOpsSemanticColors.completed.withValues(alpha: 0.14)
        : (canStartNow ? cs.surfaceContainerHighest.withValues(alpha: 0.7) : FireOpsSemanticColors.warning.withValues(alpha: 0.12));
    final Color statusFg = isComplete
        ? FireOpsSemanticColors.completed
        : (canStartNow ? cs.onSurfaceVariant : FireOpsSemanticColors.warning);

    return Opacity(
      opacity: dim ? 0.62 : 1,
      child: InkWell(
        key: rowKey,
        onTap: onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            color: suggestedNext ? cs.primaryContainer.withValues(alpha: 0.35) : cs.surface,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (suggestedNext) ...[
                              const SizedBox(width: 8),
                              StatusPill(
                                text: 'Next',
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                maxWidth: 70,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusPill(
                              text: statusLabel,
                              backgroundColor: statusBg,
                              foregroundColor: statusFg,
                              maxWidth: 96,
                            ),
                            StatusPill(
                              text: badge,
                              backgroundColor: badgeColors.bg,
                              foregroundColor: badgeColors.fg,
                              maxWidth: 210,
                            ),
                            if (trailing != null)
                              Text(
                                trailing,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                        if (prereqLine != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            prereqLine,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FireOpsSemanticColors.warning, height: 1.35),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'Quick Log progress',
                    onPressed: () => QuickLogLauncher.open(
                      context,
                      prefill: LogPrefill(
                        title: r.name,
                        category: r.name,
                        relatedGoalId: goalId,
                        relatedRequirementId: r.id,
                        relatedTaskId: null,
                        tags: const ['task-book', 'progress'],
                      ),
                    ),
                    icon: Icon(Icons.bolt_outlined, color: cs.primary),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
              if (showDivider)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Divider(height: 1, color: cs.outline.withValues(alpha: 0.10)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoGoalEmpty extends StatelessWidget {
  final VoidCallback onChooseGoal;
  final VoidCallback onCreateCustom;
  final List<CustomTaskBook> customBooks;
  const _NoGoalEmpty({required this.onChooseGoal, required this.onCreateCustom, required this.customBooks});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHOOSE YOUR NEXT LEVEL', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pick your Next Level and we’ll build your Task Book. Or create a department Task Book now.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(onPressed: onChooseGoal, child: const Text('Choose Next Level')),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCreateCustom,
                icon: const Icon(Icons.apartment_outlined),
                label: const Text('Create department Task Book'),
              ),
            ),
            if (customBooks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'YOUR CUSTOM TASK BOOKS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...customBooks.where((b) => !b.archived).take(3).map((b) => _CustomBookMiniCard(book: b)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DepartmentTaskBookEntryCard extends StatelessWidget {
  final List<CustomTaskBook> customBooks;
  final VoidCallback onCreate;
  final VoidCallback onSwitch;
  const _DepartmentTaskBookEntryCard({required this.customBooks, required this.onCreate, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = customBooks.where((b) => !b.archived).toList();
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apartment_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Department Task Books',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(onPressed: onSwitch, child: const Text('Switch')),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Track local SOPs and promo steps (keeps Career Road separate).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create department Task Book'),
            ),
          ),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('RECENT', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...active.take(2).map((b) => _CustomBookMiniCard(book: b)),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Tip: create one when your department’s requirements differ from the default path.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomBookMiniCard extends StatelessWidget {
  final CustomTaskBook book;
  const _CustomBookMiniCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: () async {
          await context.read<AppState>().taskBookController.setActiveTaskBook(book.id);
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(book.departmentSpecific ? Icons.apartment_outlined : Icons.book_outlined, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('${book.requirements.length} requirements', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
