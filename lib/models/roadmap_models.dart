import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/requirement.dart';

class RoadmapRequirement {
  final Requirement requirement;
  final bool isComplete;
  final bool isExcluded;

  const RoadmapRequirement(
      {required this.requirement,
      required this.isComplete,
      required this.isExcluded});
}

enum RequirementActivityStatus { notStarted, planning, scheduled, inProgress }

/// A concrete, user-actionable step for completing a requirement.
///
/// Stored inside [PathRequirementOverride] so it can apply to both catalog and
/// user-customized requirements.
class RequirementPlanStep {
  final String id;
  final String title;
  final bool isDone;
  final String? notes;
  final String? url;
  final int? estimatedMinutes;

  const RequirementPlanStep({
    required this.id,
    required this.title,
    required this.isDone,
    required this.notes,
    required this.url,
    required this.estimatedMinutes,
  });

  RequirementPlanStep copyWith({
    String? title,
    bool? isDone,
    String? notes,
    String? url,
    int? estimatedMinutes,
    bool clearNotes = false,
    bool clearUrl = false,
    bool clearEstimatedMinutes = false,
  }) {
    return RequirementPlanStep(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      notes: clearNotes ? null : (notes ?? this.notes),
      url: clearUrl ? null : (url ?? this.url),
      estimatedMinutes: clearEstimatedMinutes
          ? null
          : (estimatedMinutes ?? this.estimatedMinutes),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'notes': notes,
        'url': url,
        'estimatedMinutes': estimatedMinutes,
      };

  factory RequirementPlanStep.fromJson(Map<String, dynamic> json) {
    return RequirementPlanStep(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      isDone: (json['isDone'] as bool?) ?? false,
      notes: json['notes'] as String?,
      url: json['url'] as String?,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
    );
  }
}

/// A smaller checklist item that rolls up into requirement progress.
class RequirementSubTask {
  final String id;
  final String title;
  final bool isDone;
  final String? notes;

  const RequirementSubTask({
    required this.id,
    required this.title,
    required this.isDone,
    required this.notes,
  });

  RequirementSubTask copyWith({
    String? title,
    bool? isDone,
    String? notes,
    bool clearNotes = false,
  }) {
    return RequirementSubTask(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'notes': notes,
      };

  factory RequirementSubTask.fromJson(Map<String, dynamic> json) {
    return RequirementSubTask(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      isDone: (json['isDone'] as bool?) ?? false,
      notes: json['notes'] as String?,
    );
  }
}

class TrainingSchedule {
  final String? courseName;
  final String? provider;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final String? notes;

  const TrainingSchedule({
    required this.courseName,
    required this.provider,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'courseName': courseName,
        'provider': provider,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'location': location,
        'notes': notes,
      };

  factory TrainingSchedule.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    return TrainingSchedule(
      courseName: json['courseName'] as String?,
      provider: json['provider'] as String?,
      startDate: _dt(json['startDate']),
      endDate: _dt(json['endDate']),
      location: json['location'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class PathRequirementOverride {
  final String goalId;
  final String requirementId;
  final bool excluded;
  final bool? completed;
  final double? overrideExperienceValue;
  final double? overrideProgressCurrent;
  final double? overrideProgressRequired;
  final String? overrideProgressUnit;
  final RequirementActivityStatus? activityStatus;
  final TrainingSchedule? schedule;
  final int? taskBookCompletedItems;
  final int? taskBookTotalItems;
  final DateTime? suggestedStartDate;
  final DateTime? suggestedCompletionDate;
  final bool removedFromTimeline;
  final List<ResourceLink> userResourceLinks;
  final List<RequirementPlanStep> planSteps;
  final List<RequirementSubTask> subTasks;

  const PathRequirementOverride({
    required this.goalId,
    required this.requirementId,
    required this.excluded,
    required this.completed,
    required this.overrideExperienceValue,
    required this.overrideProgressCurrent,
    required this.overrideProgressRequired,
    required this.overrideProgressUnit,
    required this.activityStatus,
    required this.schedule,
    required this.taskBookCompletedItems,
    required this.taskBookTotalItems,
    required this.suggestedStartDate,
    required this.suggestedCompletionDate,
    required this.removedFromTimeline,
    this.userResourceLinks = const <ResourceLink>[],
    this.planSteps = const <RequirementPlanStep>[],
    this.subTasks = const <RequirementSubTask>[],
  });

  PathRequirementOverride copyWith({
    bool? excluded,
    bool? completed,
    double? overrideExperienceValue,
    double? overrideProgressCurrent,
    double? overrideProgressRequired,
    String? overrideProgressUnit,
    RequirementActivityStatus? activityStatus,
    TrainingSchedule? schedule,
    bool clearSchedule = false,
    int? taskBookCompletedItems,
    int? taskBookTotalItems,
    DateTime? suggestedStartDate,
    DateTime? suggestedCompletionDate,
    bool? removedFromTimeline,
    bool clearSuggestedDates = false,
    List<ResourceLink>? userResourceLinks,
    List<RequirementPlanStep>? planSteps,
    List<RequirementSubTask>? subTasks,
  }) {
    return PathRequirementOverride(
      goalId: goalId,
      requirementId: requirementId,
      excluded: excluded ?? this.excluded,
      completed: completed ?? this.completed,
      overrideExperienceValue:
          overrideExperienceValue ?? this.overrideExperienceValue,
      overrideProgressCurrent:
          overrideProgressCurrent ?? this.overrideProgressCurrent,
      overrideProgressRequired:
          overrideProgressRequired ?? this.overrideProgressRequired,
      overrideProgressUnit: overrideProgressUnit ?? this.overrideProgressUnit,
      activityStatus: activityStatus ?? this.activityStatus,
      schedule: clearSchedule ? null : (schedule ?? this.schedule),
      taskBookCompletedItems:
          taskBookCompletedItems ?? this.taskBookCompletedItems,
      taskBookTotalItems: taskBookTotalItems ?? this.taskBookTotalItems,
      suggestedStartDate: clearSuggestedDates
          ? null
          : (suggestedStartDate ?? this.suggestedStartDate),
      suggestedCompletionDate: clearSuggestedDates
          ? null
          : (suggestedCompletionDate ?? this.suggestedCompletionDate),
      removedFromTimeline: removedFromTimeline ?? this.removedFromTimeline,
      userResourceLinks: userResourceLinks ?? this.userResourceLinks,
      planSteps: planSteps ?? this.planSteps,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'goalId': goalId,
        'requirementId': requirementId,
        'excluded': excluded,
        'completed': completed,
        'overrideExperienceValue': overrideExperienceValue,
        'overrideProgressCurrent': overrideProgressCurrent,
        'overrideProgressRequired': overrideProgressRequired,
        'overrideProgressUnit': overrideProgressUnit,
        'activityStatus': activityStatus?.name,
        'schedule': schedule?.toJson(),
        'taskBookCompletedItems': taskBookCompletedItems,
        'taskBookTotalItems': taskBookTotalItems,
        'suggestedStartDate': suggestedStartDate?.toIso8601String(),
        'suggestedCompletionDate': suggestedCompletionDate?.toIso8601String(),
        'removedFromTimeline': removedFromTimeline,
        'userResourceLinks': userResourceLinks.map((e) => e.toJson()).toList(),
        'planSteps': planSteps.map((e) => e.toJson()).toList(),
        'subTasks': subTasks.map((e) => e.toJson()).toList(),
      };

  factory PathRequirementOverride.fromJson(Map<String, dynamic> json) {
    RequirementActivityStatus? _status(dynamic v) {
      if (v is! String) return null;
      try {
        return RequirementActivityStatus.values.byName(v);
      } catch (_) {
        return null;
      }
    }

    TrainingSchedule? _schedule(dynamic v) {
      if (v is! Map) return null;
      return TrainingSchedule.fromJson(Map<String, dynamic>.from(v));
    }

    DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;

    List<ResourceLink> _links(dynamic v) {
      if (v is! List) return const <ResourceLink>[];
      return v
          .whereType<Map>()
          .map((e) {
            try {
              return ResourceLink.fromJson(Map<String, dynamic>.from(e));
            } catch (_) {
              return null;
            }
          })
          .whereType<ResourceLink>()
          .toList();
    }

    List<RequirementPlanStep> _planSteps(dynamic v) {
      if (v is! List) return const <RequirementPlanStep>[];
      return v
          .whereType<Map>()
          .map((e) {
            try {
              return RequirementPlanStep.fromJson(
                Map<String, dynamic>.from(e),
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<RequirementPlanStep>()
          .where((e) => e.id.trim().isNotEmpty && e.title.trim().isNotEmpty)
          .toList();
    }

    List<RequirementSubTask> _subTasks(dynamic v) {
      if (v is! List) return const <RequirementSubTask>[];
      return v
          .whereType<Map>()
          .map((e) {
            try {
              return RequirementSubTask.fromJson(Map<String, dynamic>.from(e));
            } catch (_) {
              return null;
            }
          })
          .whereType<RequirementSubTask>()
          .where((e) => e.id.trim().isNotEmpty && e.title.trim().isNotEmpty)
          .toList();
    }

    return PathRequirementOverride(
      goalId: (json['goalId'] as String?) ?? '',
      requirementId: (json['requirementId'] as String?) ?? '',
      excluded: (json['excluded'] as bool?) ?? false,
      completed: json['completed'] as bool?,
      overrideExperienceValue:
          (json['overrideExperienceValue'] as num?)?.toDouble(),
      overrideProgressCurrent:
          (json['overrideProgressCurrent'] as num?)?.toDouble(),
      overrideProgressRequired:
          (json['overrideProgressRequired'] as num?)?.toDouble(),
      overrideProgressUnit: json['overrideProgressUnit'] as String?,
      activityStatus: _status(json['activityStatus']),
      schedule: _schedule(json['schedule']),
      taskBookCompletedItems: (json['taskBookCompletedItems'] as num?)?.toInt(),
      taskBookTotalItems: (json['taskBookTotalItems'] as num?)?.toInt(),
      suggestedStartDate: _dt(json['suggestedStartDate']),
      suggestedCompletionDate: _dt(json['suggestedCompletionDate']),
      removedFromTimeline: (json['removedFromTimeline'] as bool?) ?? false,
      userResourceLinks: _links(json['userResourceLinks']),
      planSteps: _planSteps(json['planSteps']),
      subTasks: _subTasks(json['subTasks']),
    );
  }
}

class Roadmap {
  final CareerGoal goal;
  final List<RoadmapRequirement> all;

  const Roadmap({required this.goal, required this.all});

  // Progress only counts requirements that are included (not excluded by the user).
  int get completedCount => included.where((e) => e.isComplete).length;
  int get totalCount => included.length;
  double get percentComplete =>
      totalCount == 0 ? 0 : completedCount / totalCount;

  List<RoadmapRequirement> get included =>
      all.where((e) => !e.isExcluded).toList();
  List<RoadmapRequirement> get completed =>
      included.where((e) => e.isComplete).toList();
  List<RoadmapRequirement> get missing =>
      included.where((e) => !e.isComplete).toList();

  List<RoadmapRequirement> get missingCore => missing
      .where((e) => e.requirement.priority == RequirementPriority.core)
      .toList();
  List<RoadmapRequirement> get missingRecommended => missing
      .where((e) => e.requirement.priority == RequirementPriority.recommended)
      .toList();

  RoadmapRequirement? get nextStep {
    // Explicit priority order (matches product spec):
    // 1) Missing prerequisite
    // 2) Missing CORE/STATE certification
    // 3) Required DEPARTMENT requirement
    // 4) Required experience / numeric progress
    // 5) Task book
    // 6) Recommended
    // 7) Development
    final candidates = missing;
    if (candidates.isEmpty) return null;

    RoadmapRequirement? best;
    int bestTier = 1 << 30;
    int bestSort = 1 << 30;

    for (final item in candidates) {
      final req = item.requirement;

      // Prereq gating: recommend the earliest unmet prereq first (if it's part of the roadmap).
      for (final prereqKey in req.prerequisiteRequirementIds) {
        final prereqReq = included.where((e) {
          final ref =
              (e.requirement.certificationReference ?? e.requirement.name)
                  .trim()
                  .toLowerCase();
          return ref == prereqKey.trim().toLowerCase();
        }).firstOrNull;
        if (prereqReq != null && !prereqReq.isComplete) {
          final tier = 0;
          final sort = prereqReq.requirement.sortOrder;
          if (tier < bestTier || (tier == bestTier && sort < bestSort)) {
            bestTier = tier;
            bestSort = sort;
            best = prereqReq;
          }
        }
      }

      final tier = _tierFor(req);
      final sort = req.sortOrder;
      if (tier < bestTier || (tier == bestTier && sort < bestSort)) {
        bestTier = tier;
        bestSort = sort;
        best = item;
      }
    }

    return best ?? candidates.first;
  }

  List<RoadmapRequirement> get comingUp {
    final items = missing.toList();
    items.sort(
        (a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder));
    return items;
  }

  static int _tierFor(Requirement r) {
    final isCoreLike = r.priority == RequirementPriority.core ||
        r.priority == RequirementPriority.state;
    final isDept = r.priority == RequirementPriority.department ||
        r.requirementSource == RequirementSource.departmentRequirement;

    if (isCoreLike) return 1;
    if (isDept) {
      if (r.type == RequirementType.experience ||
          r.type == RequirementType.numericProgress) return 3;
      if (r.type == RequirementType.taskBook) return 4;
      return 2;
    }
    if (r.type == RequirementType.experience ||
        r.type == RequirementType.numericProgress) return 3;
    if (r.type == RequirementType.taskBook) return 4;
    if (r.priority == RequirementPriority.recommended) return 5;
    return 6;
  }
}

class PendingCertMatch {
  final String certId;
  final String userText;
  final String suggestedDefinitionId;

  const PendingCertMatch(
      {required this.certId,
      required this.userText,
      required this.suggestedDefinitionId});
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
