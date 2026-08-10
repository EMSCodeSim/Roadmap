import 'package:flutter/foundation.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/local_store.dart';
import 'package:firepath/services/timeline_planner.dart';

class RoadmapRequirement {
  final Requirement requirement;
  final bool isComplete;
  final bool isExcluded;

  const RoadmapRequirement({required this.requirement, required this.isComplete, required this.isExcluded});
}

enum RequirementActivityStatus { notStarted, planning, scheduled, inProgress }

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
  }) {
    return PathRequirementOverride(
      goalId: goalId,
      requirementId: requirementId,
      excluded: excluded ?? this.excluded,
      completed: completed ?? this.completed,
      overrideExperienceValue: overrideExperienceValue ?? this.overrideExperienceValue,
      overrideProgressCurrent: overrideProgressCurrent ?? this.overrideProgressCurrent,
      overrideProgressRequired: overrideProgressRequired ?? this.overrideProgressRequired,
      overrideProgressUnit: overrideProgressUnit ?? this.overrideProgressUnit,
      activityStatus: activityStatus ?? this.activityStatus,
      schedule: clearSchedule ? null : (schedule ?? this.schedule),
      taskBookCompletedItems: taskBookCompletedItems ?? this.taskBookCompletedItems,
      taskBookTotalItems: taskBookTotalItems ?? this.taskBookTotalItems,
      suggestedStartDate: clearSuggestedDates ? null : (suggestedStartDate ?? this.suggestedStartDate),
      suggestedCompletionDate: clearSuggestedDates ? null : (suggestedCompletionDate ?? this.suggestedCompletionDate),
      removedFromTimeline: removedFromTimeline ?? this.removedFromTimeline,
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

    return PathRequirementOverride(
      goalId: (json['goalId'] as String?) ?? '',
      requirementId: (json['requirementId'] as String?) ?? '',
      excluded: (json['excluded'] as bool?) ?? false,
      completed: json['completed'] as bool?,
      overrideExperienceValue: (json['overrideExperienceValue'] as num?)?.toDouble(),
      overrideProgressCurrent: (json['overrideProgressCurrent'] as num?)?.toDouble(),
      overrideProgressRequired: (json['overrideProgressRequired'] as num?)?.toDouble(),
      overrideProgressUnit: json['overrideProgressUnit'] as String?,
      activityStatus: _status(json['activityStatus']),
      schedule: _schedule(json['schedule']),
      taskBookCompletedItems: (json['taskBookCompletedItems'] as num?)?.toInt(),
      taskBookTotalItems: (json['taskBookTotalItems'] as num?)?.toInt(),
      suggestedStartDate: _dt(json['suggestedStartDate']),
      suggestedCompletionDate: _dt(json['suggestedCompletionDate']),
      removedFromTimeline: (json['removedFromTimeline'] as bool?) ?? false,
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
  double get percentComplete => totalCount == 0 ? 0 : completedCount / totalCount;

  List<RoadmapRequirement> get included => all.where((e) => !e.isExcluded).toList();
  List<RoadmapRequirement> get completed => included.where((e) => e.isComplete).toList();
  List<RoadmapRequirement> get missing => included.where((e) => !e.isComplete).toList();

  List<RoadmapRequirement> get missingCore => missing.where((e) => e.requirement.priority == RequirementPriority.core).toList();
  List<RoadmapRequirement> get missingRecommended => missing.where((e) => e.requirement.priority == RequirementPriority.recommended).toList();

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
          final ref = (e.requirement.certificationReference ?? e.requirement.name).trim().toLowerCase();
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
    items.sort((a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder));
    return items;
  }

  static int _tierFor(Requirement r) {
    final isCoreLike = r.priority == RequirementPriority.core || r.priority == RequirementPriority.state;
    final isDept = r.priority == RequirementPriority.department || r.requirementSource == RequirementSource.departmentRequirement;

    if (isCoreLike) return 1;
    if (isDept) {
      if (r.type == RequirementType.experience || r.type == RequirementType.numericProgress) return 3;
      if (r.type == RequirementType.taskBook) return 4;
      return 2;
    }
    if (r.type == RequirementType.experience || r.type == RequirementType.numericProgress) return 3;
    if (r.type == RequirementType.taskBook) return 4;
    if (r.priority == RequirementPriority.recommended) return 5;
    return 6;
  }
}

class AppState extends ChangeNotifier {
  final LocalStore _store = LocalStore();

  bool _bootstrapped = false;
  bool _onboardingComplete = false;

  UserProfile _profile = UserProfile.empty();
  final Map<String, Certification> _certsById = {};
  final List<Requirement> _customRequirements = [];
  final List<PathRequirementOverride> _overrides = [];

  bool get bootstrapped => _bootstrapped;
  bool get onboardingComplete => _onboardingComplete;
  UserProfile get profile => _profile;
  List<Certification> get certifications => _certsById.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  List<Requirement> get customRequirements => List.unmodifiable(_customRequirements);
  List<PathRequirementOverride> get pathOverrides => List.unmodifiable(_overrides);

  List<CareerGoal> get availableGoals => FireOpsCatalog.goals();
  CareerGoal? get selectedGoal {
    final id = profile.primaryGoalId;
    if (id == null) return null;
    final existing = availableGoals.where((g) => g.id == id).cast<CareerGoal?>().firstOrNull;
    if (existing != null) return existing;
    if (id.startsWith('custom:')) {
      final name = id.substring('custom:'.length).trim();
      final now = DateTime.now();
      return CareerGoal(
        id: id,
        title: name.isEmpty ? 'Custom Goal' : name,
        category: 'Custom',
        description: 'A custom goal you created.',
        subtitle: null,
        typicalPrerequisiteRoles: const [],
        requirements: const [],
        recommendedExperience: const [],
        resourceIds: const [],
        nextRoles: const [],
        createdAt: now,
        updatedAt: now,
      );
    }
    return null;
  }

  Roadmap? get roadmap {
    final goal = selectedGoal;
    if (goal == null) return null;

    // Certification completion should consider expired credentials as NOT complete.
    final certStatusByName = {
      for (final c in certifications) c.name.trim().toLowerCase(): c.status,
    };
    final goalCustom = _customRequirements.where((r) => r.id.startsWith('${goal.id}::')).toList();
    final allReqsRaw = [...goal.requirements, ...goalCustom];

    final overrideByReqId = {
      for (final o in _overrides.where((o) => o.goalId == goal.id && o.requirementId.isNotEmpty)) o.requirementId: o,
    };

    final allReqs = allReqsRaw.map((r) {
      final o = overrideByReqId[r.id];
      if (o == null) return r;
      return r.copyWith(
        completed: o.completed ?? r.completed,
        experienceValue: o.overrideExperienceValue,
        progressCurrent: o.overrideProgressCurrent,
        progressRequired: o.overrideProgressRequired,
        progressUnit: o.overrideProgressUnit,
        updatedAt: DateTime.now(),
      );
    }).toList();

    bool completeFor(Requirement r) {
      if (r.type == RequirementType.certification) {
        final ref = (r.certificationReference ?? r.name).trim().toLowerCase();
        final status = certStatusByName[ref];
        if (status == null) return false;
        return status != CertificationStatus.expired;
      }
      if (r.type == RequirementType.experience) {
        final required = r.experienceValue;
        if (required == null) return false;
        final years = profile.yearsOfService;
        if (years == null) return false;
        return years.toDouble() >= required;
      }
      if (r.type == RequirementType.numericProgress) {
        if (r.progressCurrent == null || r.progressRequired == null) return false;
        return r.progressCurrent! >= r.progressRequired!;
      }
      return r.completed;
    }

    bool excludedFor(Requirement r) {
      final o = overrideByReqId[r.id];
      return o?.excluded ?? false;
    }

    final items = allReqs.map((r) => RoadmapRequirement(requirement: r, isComplete: completeFor(r), isExcluded: excludedFor(r))).toList();
    items.sort((a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder));
    return Roadmap(goal: goal, all: items);
  }

  Future<void> bootstrap() async {
    try {
      _onboardingComplete = await _store.getOnboardingComplete();

      final profileJson = await _store.loadProfile();
      _profile = profileJson == null ? UserProfile.empty() : UserProfile.fromJson(profileJson);

      final certJsonList = await _store.loadCertifications();
      _certsById.clear();
      for (final m in certJsonList) {
        try {
          final cert = Certification.fromJson(m);
          if (cert.id.isNotEmpty) _certsById[cert.id] = cert;
        } catch (e) {
          debugPrint('Skipping invalid certification entry: $e');
        }
      }

      final reqJsonList = await _store.loadCustomRequirements();
      _customRequirements
        ..clear()
        ..addAll(reqJsonList.map((e) {
          try {
            return Requirement.fromJson(e);
          } catch (_) {
            return null;
          }
        }).whereType<Requirement>());

      final overridesJson = await _store.loadPathOverrides();
      _overrides
        ..clear()
        ..addAll(overridesJson.map((e) {
          try {
            return PathRequirementOverride.fromJson(e);
          } catch (_) {
            return null;
          }
        }).whereType<PathRequirementOverride>().where((o) => o.goalId.isNotEmpty && o.requirementId.isNotEmpty));

      // Sanitize writes back to prevent repeated decode problems.
      await _persistAll();
    } catch (e) {
      debugPrint('AppState.bootstrap failed: $e');
    } finally {
      _bootstrapped = true;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding({required UserProfile profile, required List<Certification> certifications}) async {
    _profile = profile.copyWith(updatedAt: DateTime.now());
    _certsById
      ..clear()
      ..addEntries(certifications.where((c) => c.name.trim().isNotEmpty).map((c) => MapEntry(c.id, c.copyWith(updatedAt: DateTime.now()))));
    _onboardingComplete = true;
    await _store.setOnboardingComplete(true);
    await _persistAll();
    notifyListeners();
  }

  Future<void> setPrimaryGoal(String goalId) async {
    final now = DateTime.now();
    final existingPlan = _profile.careerPlan;
    final shouldResetStart = existingPlan.goalId != goalId;
    final plan = existingPlan.copyWith(
      goalId: goalId,
      startDate: shouldResetStart ? now : existingPlan.startDate,
      timelineEnabled: existingPlan.targetDate != null,
      timelineStatus: existingPlan.targetDate == null ? TimelineStatus.noTargetDate : existingPlan.timelineStatus,
    );
    _profile = _profile.copyWith(primaryGoalId: goalId, careerPlan: plan, updatedAt: now);
    await _persistAll();
    notifyListeners();
  }

  Future<void> setTargetReadyDate(DateTime? targetDate) async {
    final now = DateTime.now();
    final plan = _profile.careerPlan.copyWith(
      targetDate: targetDate,
      timelineEnabled: targetDate != null,
      timelineStatus: targetDate == null ? TimelineStatus.noTargetDate : _profile.careerPlan.timelineStatus,
      clearTargetDate: targetDate == null,
    );
    _profile = _profile.copyWith(careerPlan: plan, updatedAt: now);
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile.copyWith(updatedAt: DateTime.now());
    await _persistAll();
    notifyListeners();
  }

  Future<void> setCurrentRoles(List<String> roles) async {
    _profile = _profile.copyWith(currentRoles: roles, updatedAt: DateTime.now());
    await _persistAll();
    notifyListeners();
  }

  Certification? getCertificationById(String id) => _certsById[id];

  Future<void> upsertCertification(Certification cert) async {
    _certsById[cert.id] = cert.copyWith(updatedAt: DateTime.now());
    await _persistAll();
    notifyListeners();
  }

  Future<void> deleteCertification(String id) async {
    _certsById.remove(id);
    await _persistAll();
    notifyListeners();
  }

  Future<void> addDepartmentRequirement({required String goalId, required Requirement requirement}) async {
    final now = DateTime.now();
    final saved = requirement.copyWith(updatedAt: now);
    _customRequirements.add(saved);
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateCustomRequirement(Requirement requirement) async {
    final idx = _customRequirements.indexWhere((e) => e.id == requirement.id);
    if (idx < 0) return;
    _customRequirements[idx] = requirement.copyWith(updatedAt: DateTime.now());
    await _persistAll();
    notifyListeners();
  }

  Future<void> deleteCustomRequirement(String requirementId) async {
    _customRequirements.removeWhere((e) => e.id == requirementId);
    await _persistAll();
    notifyListeners();
  }

  PathRequirementOverride? getOverride(String goalId, String requirementId) {
    return _overrides.where((o) => o.goalId == goalId && o.requirementId == requirementId).firstOrNull;
  }

  RequirementActivityStatus activityStatusFor({required String goalId, required String requirementId}) {
    final o = getOverride(goalId, requirementId);
    return o?.activityStatus ?? RequirementActivityStatus.notStarted;
  }

  TrainingSchedule? scheduleFor({required String goalId, required String requirementId}) => getOverride(goalId, requirementId)?.schedule;

  (int completed, int total)? taskBookProgressFor({required String goalId, required String requirementId}) {
    final o = getOverride(goalId, requirementId);
    final c = o?.taskBookCompletedItems;
    final t = o?.taskBookTotalItems;
    if (c == null || t == null || t <= 0) return null;
    return (c, t);
  }

  Future<void> setRequirementActivityStatus({required String goalId, required String requirementId, required RequirementActivityStatus status}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(activityStatus: status);
    } else {
      _overrides.add(
        PathRequirementOverride(
          goalId: goalId,
          requirementId: requirementId,
          excluded: false,
          completed: null,
          overrideExperienceValue: null,
          overrideProgressCurrent: null,
          overrideProgressRequired: null,
          overrideProgressUnit: null,
          activityStatus: status,
          schedule: null,
          taskBookCompletedItems: null,
          taskBookTotalItems: null,
          suggestedStartDate: null,
          suggestedCompletionDate: null,
          removedFromTimeline: false,
        ),
      );
    }
    await _persistAll();
    notifyListeners();
  }

  Future<void> setRequirementSchedule({required String goalId, required String requirementId, required TrainingSchedule? schedule}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(schedule: schedule, clearSchedule: schedule == null);
    } else {
      _overrides.add(
        PathRequirementOverride(
          goalId: goalId,
          requirementId: requirementId,
          excluded: false,
          completed: null,
          overrideExperienceValue: null,
          overrideProgressCurrent: null,
          overrideProgressRequired: null,
          overrideProgressUnit: null,
          activityStatus: null,
          schedule: schedule,
          taskBookCompletedItems: null,
          taskBookTotalItems: null,
          suggestedStartDate: null,
          suggestedCompletionDate: null,
          removedFromTimeline: false,
        ),
      );
    }
    await _persistAll();
    notifyListeners();
  }

  Future<void> setTaskBookProgress({required String goalId, required String requirementId, required int completedItems, required int totalItems}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(taskBookCompletedItems: completedItems, taskBookTotalItems: totalItems);
    } else {
      _overrides.add(
        PathRequirementOverride(
          goalId: goalId,
          requirementId: requirementId,
          excluded: false,
          completed: null,
          overrideExperienceValue: null,
          overrideProgressCurrent: null,
          overrideProgressRequired: null,
          overrideProgressUnit: null,
          activityStatus: null,
          schedule: null,
          taskBookCompletedItems: completedItems,
          taskBookTotalItems: totalItems,
          suggestedStartDate: null,
          suggestedCompletionDate: null,
          removedFromTimeline: false,
        ),
      );
    }
    await _persistAll();
    notifyListeners();
  }

  Future<void> setRequirementExcluded({required String goalId, required String requirementId, required bool excluded}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(excluded: excluded);
    } else {
      _overrides.add(
        PathRequirementOverride(
          goalId: goalId,
          requirementId: requirementId,
          excluded: excluded,
          completed: null,
          overrideExperienceValue: null,
          overrideProgressCurrent: null,
          overrideProgressRequired: null,
          overrideProgressUnit: null,
          activityStatus: null,
          schedule: null,
          taskBookCompletedItems: null,
          taskBookTotalItems: null,
          suggestedStartDate: null,
          suggestedCompletionDate: null,
          removedFromTimeline: false,
        ),
      );
    }
    await _persistAll();
    notifyListeners();
  }

  Future<void> setExperienceMinimum({required String goalId, required String requirementId, required double years}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(overrideExperienceValue: years);
    } else {
      _overrides.add(
        PathRequirementOverride(
          goalId: goalId,
          requirementId: requirementId,
          excluded: false,
          completed: null,
          overrideExperienceValue: years,
          overrideProgressCurrent: null,
          overrideProgressRequired: null,
          overrideProgressUnit: null,
          activityStatus: null,
          schedule: null,
          taskBookCompletedItems: null,
          taskBookTotalItems: null,
          suggestedStartDate: null,
          suggestedCompletionDate: null,
          removedFromTimeline: false,
        ),
      );
    }
    await _persistAll();
    notifyListeners();
  }

  Future<void> setNumericRequired({required String goalId, required String requirementId, required double requiredValue}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(overrideProgressRequired: requiredValue);
    } else {
      _overrides.add(
        PathRequirementOverride(
          goalId: goalId,
          requirementId: requirementId,
          excluded: false,
          completed: null,
          overrideExperienceValue: null,
          overrideProgressCurrent: null,
          overrideProgressRequired: requiredValue,
          overrideProgressUnit: null,
          activityStatus: null,
          schedule: null,
          taskBookCompletedItems: null,
          taskBookTotalItems: null,
          suggestedStartDate: null,
          suggestedCompletionDate: null,
          removedFromTimeline: false,
        ),
      );
    }
    await _persistAll();
    notifyListeners();
  }

  Future<void> setRequirementCompleted({required String goalId, required String requirementId, required bool completed}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(completed: completed);
    } else {
      _overrides.add(
        PathRequirementOverride(
          goalId: goalId,
          requirementId: requirementId,
          excluded: false,
          completed: completed,
          overrideExperienceValue: null,
          overrideProgressCurrent: null,
          overrideProgressRequired: null,
          overrideProgressUnit: null,
          activityStatus: null,
          schedule: null,
          taskBookCompletedItems: null,
          taskBookTotalItems: null,
          suggestedStartDate: null,
          suggestedCompletionDate: null,
          removedFromTimeline: false,
        ),
      );
    }
    await _persistAll();
    notifyListeners();
  }

  Future<void> setNumericProgress({required String goalId, required String requirementId, required double current, required double required, String? unit}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(overrideProgressCurrent: current, overrideProgressRequired: required, overrideProgressUnit: unit);
    } else {
      _overrides.add(
        PathRequirementOverride(
          goalId: goalId,
          requirementId: requirementId,
          excluded: false,
          completed: null,
          overrideExperienceValue: null,
          overrideProgressCurrent: current,
          overrideProgressRequired: required,
          overrideProgressUnit: unit,
          activityStatus: null,
          schedule: null,
          taskBookCompletedItems: null,
          taskBookTotalItems: null,
          suggestedStartDate: null,
          suggestedCompletionDate: null,
          removedFromTimeline: false,
        ),
      );
    }
    await _persistAll();
    notifyListeners();
  }

  Future<void> moveTimelineEarlier({required String goalId, required String requirementId}) async {
    final now = DateTime.now();
    final existing = getOverride(goalId, requirementId);
    final base = existing?.suggestedStartDate ?? existing?.schedule?.startDate ?? now;
    final shifted = base.subtract(const Duration(days: 90));
    await _setTimelineOverride(goalId: goalId, requirementId: requirementId, suggestedStartDate: DateTime(shifted.year, shifted.month, 1), removed: false);
  }

  Future<void> moveTimelineLater({required String goalId, required String requirementId}) async {
    final now = DateTime.now();
    final existing = getOverride(goalId, requirementId);
    final base = existing?.suggestedStartDate ?? existing?.schedule?.startDate ?? now;
    final shifted = base.add(const Duration(days: 90));
    await _setTimelineOverride(goalId: goalId, requirementId: requirementId, suggestedStartDate: DateTime(shifted.year, shifted.month, 1), removed: false);
  }

  Future<void> removeFromTimeline({required String goalId, required String requirementId}) async {
    await _setTimelineOverride(goalId: goalId, requirementId: requirementId, suggestedStartDate: null, removed: true, clearSuggestedDates: true);
  }

  Future<void> clearTimelineOverride({required String goalId, required String requirementId}) async {
    await _setTimelineOverride(goalId: goalId, requirementId: requirementId, suggestedStartDate: null, removed: false, clearSuggestedDates: true);
  }

  Future<void> _setTimelineOverride({
    required String goalId,
    required String requirementId,
    required DateTime? suggestedStartDate,
    required bool removed,
    bool clearSuggestedDates = false,
  }) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(
        suggestedStartDate: suggestedStartDate,
        removedFromTimeline: removed,
        clearSuggestedDates: clearSuggestedDates,
      );
    } else {
      _overrides.add(
        PathRequirementOverride(
          goalId: goalId,
          requirementId: requirementId,
          excluded: false,
          completed: null,
          overrideExperienceValue: null,
          overrideProgressCurrent: null,
          overrideProgressRequired: null,
          overrideProgressUnit: null,
          activityStatus: null,
          schedule: null,
          taskBookCompletedItems: null,
          taskBookTotalItems: null,
          suggestedStartDate: suggestedStartDate,
          suggestedCompletionDate: null,
          removedFromTimeline: removed,
        ),
      );
    }
    await _persistAll();
    notifyListeners();
  }

  Future<void> toggleCustomRequirementComplete(String requirementId, bool complete) async {
    final idx = _customRequirements.indexWhere((e) => e.id == requirementId);
    if (idx < 0) return;
    _customRequirements[idx] = _customRequirements[idx].copyWith(completed: complete, updatedAt: DateTime.now());
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateNumericProgress(String requirementId, {required double current, required double required}) async {
    final idx = _customRequirements.indexWhere((e) => e.id == requirementId);
    if (idx < 0) return;
    _customRequirements[idx] = _customRequirements[idx].copyWith(progressCurrent: current, progressRequired: required, updatedAt: DateTime.now());
    await _persistAll();
    notifyListeners();
  }

  Future<void> _persistAll() async {
    try {
      final estimated = CareerTimelinePlanner.estimateStatus(this);
      if (_profile.careerPlan.timelineStatus != estimated) {
        _profile = _profile.copyWith(careerPlan: _profile.careerPlan.copyWith(timelineStatus: estimated), updatedAt: DateTime.now());
      }
    } catch (e) {
      debugPrint('Timeline status estimation failed: $e');
    }
    await _store.saveProfile(_profile.toJson());
    await _store.saveCertifications(_certsById.values.map((e) => e.toJson()).toList());
    await _store.saveCustomRequirements(_customRequirements.map((e) => e.toJson()).toList());
    await _store.savePathOverrides(_overrides.map((e) => e.toJson()).toList());
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
