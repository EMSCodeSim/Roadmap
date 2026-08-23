import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/services/certification_urgency.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/state/app_state.dart';

enum CareerInboxKind {
  chooseGoal,
  certification,
  undocumentedCompletion,
  stalledTask,
}

class CareerInboxItem {
  final String id;
  final CareerInboxKind kind;
  final int priority;
  final String title;
  final String detail;
  final String actionLabel;
  final String? certificationId;
  final String? goalId;
  final String? requirementId;
  final String? qualificationName;
  final TaskBookTaskDefinition? task;

  const CareerInboxItem({
    required this.id,
    required this.kind,
    required this.priority,
    required this.title,
    required this.detail,
    required this.actionLabel,
    this.certificationId,
    this.goalId,
    this.requirementId,
    this.qualificationName,
    this.task,
  });
}

class CareerInbox {
  const CareerInbox._();

  static List<CareerInboxItem> build({
    required AppState app,
    required List<CareerRecord> records,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final items = <CareerInboxItem>[];

    for (final urgent in CertificationUrgency.urgent(
      app.certifications,
      withinDays: 90,
    )) {
      final name = app.certificationDisplayName(urgent.cert);
      final expired = urgent.isExpired;
      final days = urgent.daysRemaining;
      final detail = expired
          ? 'This credential is expired. Confirm renewal or reinstatement requirements and update the record.'
          : days == null
              ? 'This credential needs renewal attention.'
              : 'Expires in $days day${days == 1 ? '' : 's'}. Start renewal work before it becomes urgent.';
      items.add(
        CareerInboxItem(
          id: 'cert:${urgent.cert.id}',
          kind: CareerInboxKind.certification,
          priority: expired ? 0 : (days != null && days <= 30 ? 1 : 2),
          title: expired ? '$name is expired' : '$name renewal is coming up',
          detail: detail,
          actionLabel: 'Open certification',
          certificationId: urgent.cert.id,
        ),
      );
    }

    final roadmap = app.roadmap;
    if (roadmap == null) {
      items.add(
        const CareerInboxItem(
          id: 'career-goal',
          kind: CareerInboxKind.chooseGoal,
          priority: 2,
          title: 'Choose what you are working toward',
          detail:
              'Set an active career goal so Roadmap can identify stalled work, missing evidence, and the next best step.',
          actionLabel: 'Build my Task Book',
        ),
      );
      return _sorted(items);
    }

    final recordsByTask = <String, List<CareerRecord>>{};
    for (final record in records) {
      final taskId = record.relatedTaskId;
      if (taskId == null || taskId.isEmpty) continue;
      (recordsByTask[taskId] ??= <CareerRecord>[]).add(record);
    }

    final requirements = {
      for (final item in roadmap.all) item.requirement.id: item.requirement,
    };

    for (final progress in app.taskBookProgressByKey.values) {
      if (progress.goalId != roadmap.goal.id) continue;
      final requirement = requirements[progress.requirementId];
      if (requirement == null) continue;

      final task = _findTask(
        app: app,
        goalId: roadmap.goal.id,
        requirementId: progress.requirementId,
        taskId: progress.taskId,
        requirement: requirement,
      );
      if (task == null) continue;

      final linkedRecords = recordsByTask[progress.taskId] ?? const <CareerRecord>[];
      final hasLinkedCareerRecord = linkedRecords.any(
        (record) =>
            record.relatedGoalId == progress.goalId &&
            record.relatedRequirementId == progress.requirementId,
      );

      if (progress.status == TaskBookTaskStatus.complete &&
          !hasLinkedCareerRecord) {
        items.add(
          CareerInboxItem(
            id:
                'record:${progress.goalId}:${progress.requirementId}:${progress.taskId}',
            kind: CareerInboxKind.undocumentedCompletion,
            priority: 2,
            title: 'Save ${task.title} to your career record',
            detail:
                '${requirement.name} is marked complete, but this accomplishment is not yet preserved in your long-term career history.',
            actionLabel: 'Add to Career Record',
            goalId: progress.goalId,
            requirementId: progress.requirementId,
            qualificationName: requirement.name,
            task: task,
          ),
        );
        continue;
      }

      if (progress.status == TaskBookTaskStatus.practicing ||
          progress.status == TaskBookTaskStatus.readyForEvaluation) {
        final idleDays = today.difference(progress.updatedAt).inDays;
        if (idleDays < 30) continue;
        final ready = progress.status == TaskBookTaskStatus.readyForEvaluation;
        items.add(
          CareerInboxItem(
            id:
                'stalled:${progress.goalId}:${progress.requirementId}:${progress.taskId}',
            kind: CareerInboxKind.stalledTask,
            priority: ready ? 2 : 3,
            title: ready
                ? 'Move ${task.title} to evaluation'
                : 'Continue ${task.title}',
            detail: ready
                ? 'This task has been ready for evaluation for $idleDays days. Open it and plan the sign-off.'
                : 'No Task Book activity has been recorded on this task for $idleDays days.',
            actionLabel: 'Open task',
            goalId: progress.goalId,
            requirementId: progress.requirementId,
            qualificationName: requirement.name,
            task: task,
          ),
        );
      }
    }

    return _sorted(items);
  }

  static TaskBookTaskDefinition? _findTask({
    required AppState app,
    required String goalId,
    required String requirementId,
    required String taskId,
    required dynamic requirement,
  }) {
    final tasks = <TaskBookTaskDefinition>[
      ...TaskBookLibrary.tasksForRequirement(requirement),
      ...app.customTasksFor(
        goalId: goalId,
        requirementId: requirementId,
      ),
    ];
    for (final task in tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  static List<CareerInboxItem> _sorted(List<CareerInboxItem> items) {
    items.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      if (priority != 0) return priority;
      return a.title.compareTo(b.title);
    });
    return items.take(20).toList(growable: false);
  }
}
