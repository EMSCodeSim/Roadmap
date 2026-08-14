import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/ecosystem_recommendations.dart';
import 'package:firepath/widgets/ecosystem_recommendation_card.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

enum DailyFocusMode { fifteen, thirty, sixty, crew }

extension DailyFocusModeX on DailyFocusMode {
  String get label => switch (this) {
    DailyFocusMode.fifteen => '15 min',
    DailyFocusMode.thirty => '30 min',
    DailyFocusMode.sixty => '1 hour',
    DailyFocusMode.crew => 'Crew drill',
  };

  IconData get icon => switch (this) {
    DailyFocusMode.fifteen => Icons.timer_outlined,
    DailyFocusMode.thirty => Icons.schedule_outlined,
    DailyFocusMode.sixty => Icons.hourglass_bottom_outlined,
    DailyFocusMode.crew => Icons.groups_2_outlined,
  };
}

class DailyFocusPage extends StatefulWidget {
  const DailyFocusPage({super.key});

  @override
  State<DailyFocusPage> createState() => _DailyFocusPageState();
}

class _DailyFocusPageState extends State<DailyFocusPage> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = const [];
  DailyFocusMode _mode = DailyFocusMode.fifteen;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _store.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roadmap = app.roadmap;
    final next = roadmap?.nextStep?.requirement;
    final goalId = roadmap?.goal.id;
    final task = next == null || goalId == null
        ? null
        : _nextPreparationTask(app, goalId, next);
    final recent = _records.where((record) {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      return !record.date.isBefore(cutoff);
    }).toList();
    final recentHours = recent.fold<double>(
      0,
      (sum, record) => sum + (record.hours ?? 0),
    );
    final ecosystemRecommendation = EcosystemRecommendations.forTopic(
      [task?.title, next?.name].whereType<String>().join(' '),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Focus')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                _Hero(
                  goal: roadmap?.goal.title,
                  recentCount: recent.length,
                  recentHours: recentHours,
                ),
                const SizedBox(height: 18),
                Text(
                  'HOW MUCH TIME DO YOU HAVE?',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DailyFocusMode.values
                      .map(
                        (mode) => ChoiceChip(
                          avatar: Icon(mode.icon, size: 18),
                          label: Text(mode.label),
                          selected: _mode == mode,
                          onSelected: (_) => setState(() => _mode = mode),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                if (next == null)
                  _EmptyFocus(onChooseGoal: () => context.go(AppRoutes.myPath))
                else
                  _FocusPlan(
                    mode: _mode,
                    goalId: goalId!,
                    requirement: next,
                    task: task,
                    onOpenTask: task == null
                        ? () => context.go(AppRoutes.myPath)
                        : () => context.push(
                            AppRoutes.taskDetail,
                            extra: {
                              'goalId': goalId,
                              'requirementId': next.id,
                              'qualificationName': next.name,
                              'task': task,
                            },
                          ),
                    onRecord: () => QuickLogLauncher.open(
                      context,
                      prefill: LogPrefill(
                        title: task?.title ?? next.name,
                        category: 'Daily Focus',
                        relatedGoalId: goalId,
                        relatedRequirementId: next.id,
                        relatedTaskId: task?.id,
                        tags: const ['daily-focus'],
                      ),
                    ),
                  ),
                if (ecosystemRecommendation != null) ...[
                  const SizedBox(height: 12),
                  EcosystemRecommendationCard(
                    recommendation: ecosystemRecommendation,
                    compact: true,
                  ),
                ],
              ],
            ),
    );
  }

  static TaskBookTaskDefinition? _nextPreparationTask(
    AppState app,
    String goalId,
    Requirement requirement,
  ) {
    final tasks = <TaskBookTaskDefinition>[
      ...TaskBookLibrary.tasksForRequirement(requirement),
      ...app.customTasksFor(goalId: goalId, requirementId: requirement.id),
    ];
    for (final task in tasks) {
      final status = app.taskStatusFor(
        goalId: goalId,
        requirementId: requirement.id,
        taskId: task.id,
      );
      if (status != TaskBookTaskStatus.complete) return task;
    }
    return tasks.isEmpty ? null : tasks.first;
  }
}

class _Hero extends StatelessWidget {
  final String? goal;
  final int recentCount;
  final double recentHours;

  const _Hero({
    required this.goal,
    required this.recentCount,
    required this.recentHours,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Make today count.',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            goal == null
                ? 'Choose a career goal and FireOps will turn spare time into focused career progress.'
                : 'Focused on $goal. Pick the time you have and work the next meaningful step.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniMetric(value: '$recentCount', label: 'last 7 days'),
              const SizedBox(width: 12),
              _MiniMetric(
                value: recentHours.toStringAsFixed(1),
                label: 'hours logged',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String value;
  final String label;
  const _MiniMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _FocusPlan extends StatelessWidget {
  final DailyFocusMode mode;
  final String goalId;
  final Requirement requirement;
  final TaskBookTaskDefinition? task;
  final VoidCallback onOpenTask;
  final VoidCallback onRecord;

  const _FocusPlan({
    required this.mode,
    required this.goalId,
    required this.requirement,
    required this.task,
    required this.onOpenTask,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = _steps();
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY’S FOCUS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            task?.title ?? requirement.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Moves you toward ${requirement.name}.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ...steps.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      '${entry.$1 + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.$2,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onOpenTask,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                task == null ? 'Open Task Book' : 'Start Focus Session',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onRecord,
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Record What I Did'),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _steps() {
    final know = task?.whatToKnow ?? const <String>[];
    final perform = task?.performanceTasks ?? const <String>[];
    final safety = task?.safetyPoints ?? const <String>[];
    String first(List<String> items, String fallback) =>
        items.isEmpty ? fallback : items.first;
    String second(List<String> items, String fallback) =>
        items.length < 2 ? fallback : items[1];

    return switch (mode) {
      DailyFocusMode.fifteen => [
        'Learn: ${first(know, 'Review the requirement and identify the key knowledge you need next.')}',
        'Recall: explain the key point without looking at the reference.',
        'Record: log the session while it is fresh.',
      ],
      DailyFocusMode.thirty => [
        'Learn: ${first(know, 'Review the next requirement and its success criteria.')}',
        'Practice: ${first(perform, 'Perform a focused practice repetition or scenario.')}',
        'Debrief one thing that went well and one thing to improve.',
        'Record the practice in Career Road.',
      ],
      DailyFocusMode.sixty => [
        'Learn: ${first(know, 'Review the knowledge behind this requirement.')}',
        'Practice: ${first(perform, 'Complete a deliberate practice repetition.')}',
        'Advance: ${second(perform, 'Repeat the skill with a harder condition or less prompting.')}',
        'Debrief and capture evidence, hours, repetitions, or a career highlight.',
      ],
      DailyFocusMode.crew => [
        'Brief the crew on the objective: ${task?.fireOpsObjective ?? requirement.name}.',
        'Run: ${first(perform, 'Build a short scenario around the requirement and rotate roles.')}',
        'Safety focus: ${first(safety, 'Use department SOPs and an appropriate safety briefing.')}',
        'Crew debrief: identify one strength, one gap, and the next repetition.',
        'Record the drill and link it to this Task Book requirement.',
      ],
    };
  }
}

class _EmptyFocus extends StatelessWidget {
  final VoidCallback onChooseGoal;
  const _EmptyFocus({required this.onChooseGoal});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose a career direction',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Daily Focus uses your active Career Road to recommend work that actually moves you forward.',
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onChooseGoal,
            child: const Text('Open Task Book'),
          ),
        ],
      ),
    ),
  );
}
