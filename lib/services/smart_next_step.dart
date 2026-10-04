import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/services/task_book_checklist_hierarchy.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/services/certification_guide_library.dart';
import 'package:firepath/services/national_task_book_baseline.dart';
import 'package:firepath/services/task_book_stage_planner.dart';
import 'package:firepath/state/app_state.dart';

class SmartNextStepDecision {
  final Requirement requirement;
  final String focusTitle;
  final TaskBookStage stage;
  final RequirementActivityStatus activityStatus;
  final String reason;
  final String actionTitle;
  final String actionDetail;
  final String actionLabel;

  const SmartNextStepDecision({
    required this.requirement,
    required this.focusTitle,
    required this.stage,
    required this.activityStatus,
    required this.reason,
    required this.actionTitle,
    required this.actionDetail,
    required this.actionLabel,
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
    final options = alternatives(state, now: now, limit: 1);
    return options.isEmpty ? null : options.first;
  }

  static List<SmartNextStepDecision> alternatives(
    AppState state, {
    DateTime? now,
    int limit = 3,
  }) {
    final roadmap = state.roadmap;
    if (roadmap == null || limit <= 0) return const [];
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

    final decisions = <SmartNextStepDecision>[];
    var unfinishedStageCount = 0;

    for (final section in plan.sections) {
      final candidates = section.items
          .where((item) => !item.isComplete && item.canStartNow)
          .toList();
      if (candidates.isEmpty) continue;

      unfinishedStageCount += 1;
      candidates.sort((a, b) {
        final ar = _careerActionScore(
          state,
          roadmap.goal.id,
          a.requirement,
          clock,
        );
        final br = _careerActionScore(
          state,
          roadmap.goal.id,
          b.requirement,
          clock,
        );
        final score = ar.compareTo(br);
        if (score != 0) return score;
        final priority = _priorityRank(a.requirement.priority)
            .compareTo(_priorityRank(b.requirement.priority));
        if (priority != 0) return priority;
        return a.originalIndex.compareTo(b.originalIndex);
      });

      for (final picked in candidates) {
        final requirement = picked.requirement;
        final activity = state.activityStatusFor(
          goalId: roadmap.goal.id,
          requirementId: requirement.id,
        );
        final focusTitle = deepestIncompleteTitle(
          state,
          goalId: roadmap.goal.id,
          requirement: requirement,
        );
        final today = _todayAction(
          state,
          roadmap.goal.id,
          requirement,
          focusTitle,
          clock,
        );
        decisions.add(
          SmartNextStepDecision(
            requirement: requirement,
            focusTitle: focusTitle,
            stage: section.meta.stage,
            activityStatus: activity,
            reason: _reasonFor(
              state,
              roadmap.goal.id,
              requirement,
              clock,
            ),
            actionTitle: today.$1,
            actionDetail: today.$2,
            actionLabel: today.$3,
          ),
        );
        if (decisions.length >= limit) return decisions;
      }

      // Keep recommendations close to the user's current stage. One later
      // stage may provide a useful alternative, but we do not jump far ahead.
      if (unfinishedStageCount >= 2) break;
    }

    return decisions;
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

    final steps = NationalTaskBookBaseline.effectiveSteps(
      requirement,
      state.planStepsFor(
        goalId: goalId,
        requirementId: requirement.id,
      ),
    );
    final subTasks = NationalTaskBookBaseline.effectiveSubTasks(
      requirement,
      state.subTasksFor(
        goalId: goalId,
        requirementId: requirement.id,
      ),
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

    final steps = NationalTaskBookBaseline.effectiveSteps(
      r,
      state.planStepsFor(goalId: goalId, requirementId: r.id),
    );
    final subTasks = NationalTaskBookBaseline.effectiveSubTasks(
      r,
      state.subTasksFor(goalId: goalId, requirementId: r.id),
    );
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
    final steps = NationalTaskBookBaseline.effectiveSteps(
      requirement,
      state.planStepsFor(
        goalId: goalId,
        requirementId: requirement.id,
      ),
    );
    final subTasks = NationalTaskBookBaseline.effectiveSubTasks(
      requirement,
      state.subTasksFor(
        goalId: goalId,
        requirementId: requirement.id,
      ),
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

    final guide =
        CertificationGuideLibrary.guideForRequirement(requirement);
    final tasks = <TaskBookTaskDefinition>[
      ...TaskBookLibrary.tasksForRequirement(requirement),
      ...?guide?.tasks,
      ...TaskBookLibrary.certificationCompletionGates(requirement),
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
  ) =>
      _careerActionScore(state, goalId, requirement, now);

  static int _careerActionScore(
    AppState state,
    String goalId,
    Requirement requirement,
    DateTime now,
  ) {
    var score = 100;

    // Momentum: finish active work before creating new open loops.
    final activity = state.activityStatusFor(
      goalId: goalId,
      requirementId: requirement.id,
    );
    if (activity == RequirementActivityStatus.inProgress) score -= 35;
    if (activity == RequirementActivityStatus.planning) score -= 12;

    final roadmapItem = state.roadmap?.included
        .where((item) => item.requirement.id == requirement.id)
        .firstOrNull;
    if (roadmapItem != null) {
      final progress = requirementProgress(
        state,
        goalId: goalId,
        item: roadmapItem,
      );
      if (progress > 0 && progress < 1) score -= 25;
      if (progress >= 0.75 && progress < 1) score -= 8;
    }

    // Urgency: scheduled work and near-term dates rise quickly.
    final schedule = state.scheduleFor(
      goalId: goalId,
      requirementId: requirement.id,
    );
    final start = schedule?.startDate;
    if (start != null) {
      final days = start.difference(now).inDays;
      if (days <= 0) {
        score -= 35;
      } else if (days <= 7) {
        score -= 28;
      } else if (days <= 14) {
        score -= 20;
      } else if (days <= 30) {
        score -= 8;
      }
    } else if (activity == RequirementActivityStatus.scheduled) {
      score -= 18;
    }

    // Career impact: work that unlocks later requirements is more valuable.
    final normalizedIds = <String>{
      requirement.id.trim().toLowerCase(),
      requirement.name.trim().toLowerCase(),
      (requirement.certificationReference ?? '').trim().toLowerCase(),
    }..remove('');
    final unlockCount = state.roadmap?.included.where((item) {
          return item.requirement.prerequisiteRequirementIds.any(
            (id) => normalizedIds.contains(id.trim().toLowerCase()),
          );
        }).length ??
        0;
    score -= (unlockCount.clamp(0, 4) * 6);

    // Competency / evaluation opportunity: once a skill is ready for an
    // evaluator, doing that evaluation is usually more valuable than more
    // generic preparation.
    final guide = CertificationGuideLibrary.guideForRequirement(requirement);
    final tasks = <TaskBookTaskDefinition>[
      ...TaskBookLibrary.tasksForRequirement(requirement),
      ...?guide?.tasks,
      ...TaskBookLibrary.certificationCompletionGates(requirement),
      ...state.customTasksFor(
        goalId: goalId,
        requirementId: requirement.id,
      ),
    ];
    var hasReadyEvaluation = false;
    var hasActivePractice = false;
    for (final task in tasks) {
      final taskStatus = state.taskStatusFor(
        goalId: goalId,
        requirementId: requirement.id,
        taskId: task.id,
      );
      if (taskStatus == TaskBookTaskStatus.readyForEvaluation) {
        hasReadyEvaluation = true;
      } else if (taskStatus == TaskBookTaskStatus.practicing ||
          taskStatus == TaskBookTaskStatus.learning) {
        hasActivePractice = true;
      }
    }
    if (hasReadyEvaluation) score -= 26;
    if (hasActivePractice) score -= 12;

    // Effort: give a small advantage to useful actions that can realistically
    // be moved today without letting quick wins outrank true gates.
    score += switch (requirement.type) {
      RequirementType.custom => -5,
      RequirementType.interview => -4,
      RequirementType.promotionalTest => -3,
      RequirementType.practical => -2,
      RequirementType.trainingCourse || RequirementType.course => 0,
      RequirementType.taskBook => 0,
      RequirementType.certification => 2,
      RequirementType.numericProgress => 3,
      RequirementType.experience => 5,
      RequirementType.education => 4,
    };

    return score;
  }

  static (String, String, String) todayActionFor(
    AppState state, {
    required String goalId,
    required Requirement requirement,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final focusTitle = deepestIncompleteTitle(
      state,
      goalId: goalId,
      requirement: requirement,
    );
    return _todayAction(
      state,
      goalId,
      requirement,
      focusTitle,
      clock,
    );
  }

  static (String, String, String) _todayAction(
    AppState state,
    String goalId,
    Requirement requirement,
    String focusTitle,
    DateTime now,
  ) {
    final status = state.activityStatusFor(
      goalId: goalId,
      requirementId: requirement.id,
    );
    final schedule = state.scheduleFor(
      goalId: goalId,
      requirementId: requirement.id,
    );

    if (status == RequirementActivityStatus.inProgress) {
      return (
        focusTitle,
        'Continue the work you already started. Finishing active work usually moves your roadmap faster than opening another requirement.',
        'Continue'
      );
    }

    if (schedule?.startDate != null &&
        !schedule!.startDate!.isAfter(now.add(const Duration(days: 14)))) {
      return (
        'Prepare for ${requirement.name}',
        'Your scheduled date is coming up. Review the requirement, gather what you need, and complete the next preparation step today.',
        'Prepare now'
      );
    }

    if (requirement.requirementSource ==
            RequirementSource.departmentRequirement ||
        requirement.departmentDependent) {
      if (requirement.type == RequirementType.promotionalTest) {
        return (
          'Prepare for ${requirement.name}',
          'Confirm the department announcement, eligibility rules, test format, references, deadlines, and passing/selection process. Then complete the next preparation step.',
          'Open promotion step'
        );
      }
      if (requirement.type == RequirementType.practical) {
        return (
          'Prepare for ${requirement.name}',
          'Confirm the department assessment format, scoring areas, date, and required materials. Use your documented experience to prepare for the exercise.',
          'Open assessment'
        );
      }
      if (requirement.type == RequirementType.interview) {
        return (
          'Prepare for ${requirement.name}',
          'Review the department process and build examples from your record that demonstrate leadership, judgment, accountability, and readiness for the role.',
          'Prepare interview'
        );
      }
      return (
        requirement.name,
        'Confirm the exact department requirement, who approves it, and what evidence or minimum experience is required. Record the local rule in your roadmap before marking it complete.',
        'Confirm department rule'
      );
    }

    switch (requirement.type) {
      case RequirementType.promotionalTest:
        return (
          'Find the next test date and register',
          'Check the official testing source for ${requirement.name}, confirm eligibility and deadlines, then register or add the registration deadline to your plan.',
          'Plan test'
        );
      case RequirementType.practical:
        return (
          'Schedule the practical evaluation',
          'Identify the approved evaluator or testing site for ${requirement.name} and get the practical/JPR evaluation on your calendar.',
          'Plan evaluation'
        );
      case RequirementType.certification:
        return (
          'Find the official path for ${requirement.name}',
          'Confirm the certifying authority, approved course or testing center, prerequisites, application steps, and the next available date. Then complete the first registration step.',
          'Find next step'
        );
      case RequirementType.trainingCourse:
      case RequirementType.course:
        return (
          'Find and enroll in ${requirement.name}',
          'Locate an approved upcoming class, confirm prerequisites and cost, then register or save the next enrollment deadline.',
          'Find a class'
        );
      case RequirementType.interview:
        return (
          'Prepare for ${requirement.name}',
          'Build one focused preparation block today: review likely questions, write examples from your experience, and schedule a practice interview.',
          'Start prep'
        );
      case RequirementType.education:
        return (
          'Take the next enrollment step for ${requirement.name}',
          'Identify the program or provider, verify admission requirements and deadlines, and complete one concrete application or enrollment step.',
          'Plan enrollment'
        );
      case RequirementType.taskBook:
        return (
          focusTitle,
          'Complete the next unfinished Task Book item that advances ${requirement.name}. If it requires an evaluator, get the practice or evaluation scheduled.',
          'Open Task Book'
        );
      case RequirementType.experience:
        return (
          'Create an opportunity to build ${requirement.name}',
          'Choose one realistic shift, drill, assignment, ride-along, or supervised opportunity that adds meaningful experience toward this requirement.',
          'Plan experience'
        );
      case RequirementType.numericProgress:
        return (
          'Add progress toward ${requirement.name}',
          'Pick one measurable action today that moves this requirement forward and record the result when you finish.',
          'Log progress'
        );
      case RequirementType.custom:
        return (
          focusTitle,
          'Complete the smallest meaningful action that moves this roadmap requirement forward today.',
          'Open next step'
        );
    }
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
