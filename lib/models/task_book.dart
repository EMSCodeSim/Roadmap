/// Task Book models.
///
/// These are designed to be stored locally today, but structured so they can
/// later be synced/managed by a department (Department Pro).

enum TaskBookTaskStatus { notStarted, practicing, readyForEvaluation, complete }

enum TaskBookCompletionSource {
  selfVerified,
  documentVerified,
  supervisorVerified,
  certificationVerified,
}

enum TaskBookTaskResourceType {
  skillSheet,
  trainingGuide,
  departmentSop,
  officialResource,
  video,
  stateInfo,
  fireOpsGuide,
  other,
}

class TaskBookResourceLink {
  final String title;
  final String? url;
  final TaskBookTaskResourceType type;
  final String? issuingSource;
  final String? notes;
  final String? fileRef;

  const TaskBookResourceLink({
    required this.title,
    required this.url,
    required this.type,
    required this.issuingSource,
    required this.notes,
    required this.fileRef,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'type': type.name,
        'issuingSource': issuingSource,
        'notes': notes,
        'fileRef': fileRef,
      };

  factory TaskBookResourceLink.fromJson(Map<String, dynamic> json) {
    TaskBookTaskResourceType parseType(dynamic value) {
      if (value is! String) return TaskBookTaskResourceType.other;
      try {
        return TaskBookTaskResourceType.values.byName(value);
      } catch (_) {
        return TaskBookTaskResourceType.other;
      }
    }

    return TaskBookResourceLink(
      title: (json['title'] as String?) ?? '',
      url: json['url'] as String?,
      type: parseType(json['type']),
      issuingSource: json['issuingSource'] as String?,
      notes: json['notes'] as String?,
      fileRef: json['fileRef'] as String?,
    );
  }
}

class TaskBookPracticeToolLink {
  final String title;
  final String route;
  final String? subtitle;

  const TaskBookPracticeToolLink({
    required this.title,
    required this.route,
    required this.subtitle,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'route': route,
        'subtitle': subtitle,
      };

  factory TaskBookPracticeToolLink.fromJson(Map<String, dynamic> json) =>
      TaskBookPracticeToolLink(
        title: (json['title'] as String?) ?? '',
        route: (json['route'] as String?) ?? '',
        subtitle: json['subtitle'] as String?,
      );
}

class TaskBookTaskDefinition {
  final String id;
  final String title;
  final String section;

  /// Optional scoping for user-created custom tasks.
  final String? goalId;
  final String? requirementId;
  final bool isCustom;

  /// FireOps-created helper content. This is not an official skill sheet.
  final String? fireOpsObjective;
  final List<String> whatToKnow;
  final List<String> performanceTasks;
  final List<String> safetyPoints;
  final List<String> commonMistakes;
  final List<TaskBookPracticeToolLink> practiceTools;
  final List<TaskBookResourceLink> resources;

  const TaskBookTaskDefinition({
    required this.id,
    required this.title,
    required this.section,
    required this.goalId,
    required this.requirementId,
    required this.isCustom,
    required this.fireOpsObjective,
    required this.whatToKnow,
    required this.performanceTasks,
    required this.safetyPoints,
    required this.commonMistakes,
    required this.practiceTools,
    required this.resources,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'section': section,
        'goalId': goalId,
        'requirementId': requirementId,
        'isCustom': isCustom,
        'fireOpsObjective': fireOpsObjective,
        'whatToKnow': whatToKnow,
        'performanceTasks': performanceTasks,
        'safetyPoints': safetyPoints,
        'commonMistakes': commonMistakes,
        'practiceTools': practiceTools.map((e) => e.toJson()).toList(),
        'resources': resources.map((e) => e.toJson()).toList(),
      };

  factory TaskBookTaskDefinition.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic value) =>
        value is List ? value.whereType<String>().toList() : const <String>[];
    List<TaskBookPracticeToolLink> tools(dynamic value) => value is List
        ? value
            .whereType<Map>()
            .map((e) => TaskBookPracticeToolLink.fromJson(
                Map<String, dynamic>.from(e)))
            .toList()
        : const <TaskBookPracticeToolLink>[];
    List<TaskBookResourceLink> resources(dynamic value) => value is List
        ? value
            .whereType<Map>()
            .map((e) =>
                TaskBookResourceLink.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <TaskBookResourceLink>[];

    return TaskBookTaskDefinition(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      section: (json['section'] as String?) ?? 'General',
      goalId: json['goalId'] as String?,
      requirementId: json['requirementId'] as String?,
      isCustom: (json['isCustom'] as bool?) ?? false,
      fireOpsObjective: json['fireOpsObjective'] as String?,
      whatToKnow: strings(json['whatToKnow']),
      performanceTasks: strings(json['performanceTasks']),
      safetyPoints: strings(json['safetyPoints']),
      commonMistakes: strings(json['commonMistakes']),
      practiceTools: tools(json['practiceTools']),
      resources: resources(json['resources']),
    );
  }
}

class TaskBookTaskProgress {
  final String goalId;
  final String requirementId;
  final String taskId;
  final TaskBookTaskStatus status;
  final TaskBookCompletionSource? completionSource;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskBookTaskProgress({
    required this.goalId,
    required this.requirementId,
    required this.taskId,
    required this.status,
    required this.completionSource,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskBookTaskProgress copyWith({
    TaskBookTaskStatus? status,
    TaskBookCompletionSource? completionSource,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    final nextStatus = status ?? this.status;
    final isComplete = nextStatus == TaskBookTaskStatus.complete;
    return TaskBookTaskProgress(
      goalId: goalId,
      requirementId: requirementId,
      taskId: taskId,
      status: nextStatus,
      // Completion metadata must never survive after a task is moved back to a
      // non-complete state. This keeps self/supervisor verification truthful.
      completionSource:
          isComplete ? (completionSource ?? this.completionSource) : null,
      completedAt: isComplete ? (completedAt ?? this.completedAt) : null,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'goalId': goalId,
        'requirementId': requirementId,
        'taskId': taskId,
        'status': status.name,
        'completionSource': completionSource?.name,
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TaskBookTaskProgress.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value is String ? DateTime.tryParse(value) : null;
    TaskBookTaskStatus parseStatus(dynamic value) {
      if (value is! String) return TaskBookTaskStatus.notStarted;
      try {
        return TaskBookTaskStatus.values.byName(value);
      } catch (_) {
        return TaskBookTaskStatus.notStarted;
      }
    }

    TaskBookCompletionSource? parseSource(dynamic value) {
      if (value is! String) return null;
      try {
        return TaskBookCompletionSource.values.byName(value);
      } catch (_) {
        return null;
      }
    }

    final now = DateTime.now();
    final created = parseDate(json['createdAt']) ?? now;
    final updated = parseDate(json['updatedAt']) ?? created;
    final status = parseStatus(json['status']);
    return TaskBookTaskProgress(
      goalId: (json['goalId'] as String?) ?? '',
      requirementId: (json['requirementId'] as String?) ?? '',
      taskId: (json['taskId'] as String?) ?? '',
      status: status,
      completionSource: status == TaskBookTaskStatus.complete
          ? parseSource(json['completionSource'])
          : null,
      completedAt: status == TaskBookTaskStatus.complete
          ? parseDate(json['completedAt'])
          : null,
      createdAt: created,
      updatedAt: updated,
    );
  }
}

class TaskBookKey {
  final String goalId;
  final String requirementId;

  const TaskBookKey({required this.goalId, required this.requirementId});

  String toStorageKey() => '${goalId}::${requirementId}'.toLowerCase();
}
