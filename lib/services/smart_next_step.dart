import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/services/task_book_checklist_hierarchy.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/services/task_book_stage_planner.dart';
import 'package:firepath/state/app_state.dart';

class SmartNextStepDecision {
  final Requirement requirement;
  final String focusTitle;
  final TaskBookStage stage;
  final RequirementActivityStatus activityStatus;
  final String reason;

  const SmartNextStepDecision({
    required this.requirement,
    required this.focusTitle,
    required this.stage,
    required this.activityStatus,
    required this.reason,
  });
}

class SmartStageProgress {
  final TaskBookStage stage;
  final String title;
  final int completed;
  final int total;

  const SmartStageProgress({
    required this.stage,
    required this.title,
    required this.completed,
    required this.total,
  });

  double get fraction => total <= 0 ? 0 : completed / total;
  bool get complete => total > 0 && completed >= total;
}

class SmartProgressRollup {
  final int completedRequirements;
  final int totalRequirements;
  final List<SmartStageProgress> stages;

  const SmartProgressRollup({
    required this.completedRequirements,
    required this.totalRequirements,
    required this.stages,
  });

  double get fraction =>
      totalRequirements <= 0 ? 0 : completedRequirements / totalRequirements;
}

/// Resolves the user's actual next actionable work rather than simply taking
/// the first incomplete catalog requirement.
///
/// Order of operations:
/// 1. A held/current certification remains authoritative for certification
///    completion through AppState. This engine never replaces that rule.
/// 2. Child checklist work rolls up for non-certification requirements.
/// 3. Unmet prerequisites lock later items and keep them visible but ineligible.
/// 4. Work already underway is favored inside the user's current Task Book
///    stage, followed by near-term scheduled work, planning, then untouched work.
/// 5. The deepest incomplete checklist/task title becomes the focus label while
///    the parent requirement remains the official Roadmap requirement.
class SmartNextStepEngine {
  SmartNextStepEngine._();

  static SmartNextStepDecision? resolve(AppState state, {DateTime? now}) {
    final roadmap = state.roadmap;
    if (roadmap == null) return null;
    final clock = now ?? DateTime.now();

    final completion = <String, bool>{
      for (final item in roadmap.included)
        item.requirement.id: effectiveRequirementComplete(
          state,
          goalId: roadmap.goal.id,
          item: item,
        ),
    };

    final plan = TaskBookStagePlanner.buildPlan<RoadmapRequirement>(
      items: roadmap.included,
      getRequirement: (raw) => raw.requirement,
      isComplete: (raw) => completion[raw.requirement.id] ?? raw.isComplete,
      getId: (raw) => raw.requirement.id,
    );

    for (final section in plan.sections) {
      final candidates = section.items
          .where((item) => !item.isComplete && item.canStartNow)
          .toList();
      if (candidates.isEmpty) continue;

      candidates.sort((a, b) {
        final ar = _workRank(state, roadmap.goal.id, a.requirement, clock);
        final br = _workRank(state, roadmap.goal.id, b.requirement, clock);
        final rank = ar.compareTo(br);
        if (rank != 0) return rank;
        final priority = _priorityRank(a.requirement.priority)
            .compareTo(_priorityRank(b.requirement.priority));
        if (priority != 0) return priority;
        return a.originalIndex.compareTo(b.originalIndex);
      });

      final picked = candidates.first;
      final requirement = picked.requirement;
      final activity = state.activityStatusFor(
        goalId: roadmap.goal.id,
        requirementId: requirement.id,
      );
      return SmartNextStepDecision(
        requirement: requirement,
        focusTitle: deepestIncompleteTitle(
          state,
          goalId: roadmap.goal.id,
          requirement: requirement,
        ),
        stage: section.meta.stage,
        activityStatus: activity,
        reason: _reasonFor(state, roadmap.goal.id, requirement, clock),
      );
    }
    return null;
  }

  static SmartProgressRollup rollup(AppState state) {
    final roadmap = state.roadmap;
    if (roadmap == null) {
      return const SmartProgressRollup(
        completedRequirements: 0,
        totalRequirements: 0,
        stages: <SmartStageProgress>[],
      );
    }

    final completion = <String, bool>{
      for (final item in roadmap.included)
        item.requirement.id: effectiveRequirementComplete(
          state,
          goalId: roadmap.goal.id,
          item: item,
        ),
    };

    final plan = TaskBookStagePlanner.buildPlan<RoadmapRequirement>(
      items: roadmap.included,
      getRequirement: (raw) => raw.requirement,
      isComplete: (raw) => completion[raw.requirement.id] ?? raw.isComplete,
      getId: (raw) => raw.requirement.id,
    );

    return SmartProgressRollup(
      completedRequirements: plan.completedTotal,
      totalRequirements: plan.total,
      stages: plan.sections
          .map(
            (section) => SmartStageProgress(
              stage: section.meta.stage,
              title: section.meta.title,
              completed: section.completedCount,
              total: section.totalCount,
            ),
          )
          .toList(),
    );
  }

  static bool effectiveRequirementComplete(
    AppState state, {
    required String goalId,
    required RoadmapRequirement item,
  }) {
    if (item.isComplete) return true;
    final requirement = item.requirement;

    // A checklist must never manufacture a certification, years of service, or
    // numeric requirement. Those continue to use their authoritative sources.
    if (requirement.type == RequirementType.certification ||
        requirement.type == RequirementType.experience ||
        requirement.type == RequirementType.numericProgress) {
      return false;
    }

    final steps = state.planStepsFor(
      goalId: goalId,
      requirementId: requirement.id,
    );
    final subTasks = state.subTasksFor(
      goalId: goalId,
      requirementId: requirement.id,
    );

    if (steps.isNotEmpty) {
      return steps.every((step) => effectiveStepComplete(step, subTasks));
    }

    // Backward compatibility for older requirement checklists that only had
    // unassigned subtasks.
    final unassigned = TaskBookChecklistHierarchy.unassigned(subTasks);
    return unassigned.isNotEmpty && unassigned.every((task) => task.isDone);
  }

  static bool effectiveStepComplete(
    RequirementPlanStep step,
    Iterable<RequirementSubTask> subTasks,
  ) {
    final children = TaskBookChecklistHierarchy.childrenFor(step.id, subTasks);
    if (children.isEmpty) return step.isDone;
    return children.every((child) => child.isDone);
  }

  static double requirementProgress(
    AppState state, {
    required String goalId,
    required RoadmapRequirement item,
  }) {
    if (item.isComplete) return 1;
    final r = item.requirement;
    if (r.type == RequirementType.numericProgress &&
        r.progressCurrent != null &&
        r.progressRequired != null &&
        r.progressRequired! > 0) {
      return (r.progressCurrent! / r.progressRequired!).clamp(0, 1).toDouble();
    }

    final steps = state.planStepsFor(goalId: goalId, requirementId: r.id);
    final subTasks = state.subTasksFor(goalId: goalId, requirementId: r.id);
    if (steps.isNotEmpty) {
      var done = 0;
      for (final step in steps) {
        if (effectiveStepComplete(step, subTasks)) done++;
      }
      return done / steps.length;
    }

    final unassigned = TaskBookChecklistHierarchy.unassigned(subTasks);
    if (unassigned.isNotEmpty) {
      return unassigned.where((task) => task.isDone).length / unassigned.length;
    }
    return 0;
  }

  static String deepestIncompleteTitle(
    AppState state, {
    required String goalId,
    required Requirement requirement,
  }) {
    final steps = state.planStepsFor(
      goalId: goalId,
      requirementId: requirement.id,
    );
    final subTasks = state.subTasksFor(
      goalId: goalId,
      requirementId: requirement.id,
    );

    for (final step in steps) {
      final children = TaskBookChecklistHierarchy.childrenFor(step.id, subTasks);
      for (final child in children) {
        if (!child.isDone) return child.title;
      }
      if (!effectiveStepComplete(step, subTasks)) return step.title;
    }

    for (final child in TaskBookChecklistHierarchy.unassigned(subTasks)) {
      if (!child.isDone) return child.title;
    }

    final tasks = <TaskBookTaskDefinition>[
      ...TaskBookLibrary.tasksForRequirement(requirement),
      ...state.customTasksFor(goalId: goalId, requirementId: requirement.id),
    ];
    for (final task in tasks) {
      final status = state.taskStatusFor(
        goalId: goalId,
        requirementId: requirement.id,
        taskId: task.id,
      );
      if (status != TaskBookTaskStatus.complete) return task.title;
    }

    return requirement.name;
  }

  static int _workRank(
    AppState state,
    String goalId,
    Requirement requirement,
    DateTime now,
  ) {
    final status = state.activityStatusFor(
      goalId: goalId,
      requirementId: requirement.id,
    );
    if (status == RequirementActivityStatus.inProgress) return 0;

    final roadmapItem = state.roadmap?.included
        .where((item) => item.requirement.id == requirement.id)
        .firstOrNull;
    if (roadmapItem != null &&
        requirementProgress(
              state,
              goalId: goalId,
              item: roadmapItem,
            ) >
            0) {
      return 0;
    }

    final schedule = state.scheduleFor(
      goalId: goalId,
      requirementId: requirement.id,
    );
    if (schedule != null || status == RequirementActivityStatus.scheduled) {
      final start = schedule?.startDate;
      if (start == null || !start.isAfter(now.add(const Duration(days: 14)))) {
        return 1;
      }
      return 4;
    }
    if (status == RequirementActivityStatus.planning) return 2;
    return 3;
  }

  static String _reasonFor(
    AppState state,
    String goalId,
    Requirement requirement,
    DateTime now,
  ) {
    final status = state.activityStatusFor(
      goalId: goalId,
      requirementId: requirement.id,
    );
    if (status == RequirementActivityStatus.inProgress) {
      return 'Continue work already in progress';
    }
    final schedule = state.scheduleFor(
      goalId: goalId,
      requirementId: requirement.id,
    );
    if (schedule?.startDate != null &&
        !schedule!.startDate!.isAfter(now.add(const Duration(days: 14)))) {
      return 'Scheduled training is coming up';
    }
    if (status == RequirementActivityStatus.scheduled) {
      return 'Continue your scheduled requirement';
    }
    if (status == RequirementActivityStatus.planning) {
      return 'Continue the requirement you are planning';
    }
    return 'First actionable item in your current Task Book stage';
  }

  static int _priorityRank(RequirementPriority priority) => switch (priority) {
        RequirementPriority.state => 0,
        RequirementPriority.core => 1,
        RequirementPriority.department => 2,
        RequirementPriority.recommended => 3,
        RequirementPriority.development => 4,
      };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
