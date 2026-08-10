import 'package:flutter/foundation.dart';

enum TimelineStatus { onTrack, needsAttention, atRisk, noTargetDate }

/// Career readiness planning metadata for the user's primary goal.
///
/// IMPORTANT: This is a planning aid only — it does not predict promotions.
class CareerPlan {
  final String? goalId;
  final DateTime startDate;
  final DateTime? targetDate;
  final bool timelineEnabled;
  final TimelineStatus timelineStatus;

  const CareerPlan({
    required this.goalId,
    required this.startDate,
    required this.targetDate,
    required this.timelineEnabled,
    required this.timelineStatus,
  });

  factory CareerPlan.empty() {
    final now = DateTime.now();
    return CareerPlan(goalId: null, startDate: now, targetDate: null, timelineEnabled: false, timelineStatus: TimelineStatus.noTargetDate);
  }

  CareerPlan copyWith({
    String? goalId,
    DateTime? startDate,
    DateTime? targetDate,
    bool? timelineEnabled,
    TimelineStatus? timelineStatus,
    bool clearTargetDate = false,
  }) {
    return CareerPlan(
      goalId: goalId ?? this.goalId,
      startDate: startDate ?? this.startDate,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      timelineEnabled: timelineEnabled ?? this.timelineEnabled,
      timelineStatus: timelineStatus ?? this.timelineStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'goalId': goalId,
    'startDate': startDate.toIso8601String(),
    'targetDate': targetDate?.toIso8601String(),
    'timelineEnabled': timelineEnabled,
    'timelineStatus': timelineStatus.name,
  };

  factory CareerPlan.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    TimelineStatus _status(dynamic v) {
      if (v is! String) return TimelineStatus.noTargetDate;
      try {
        return TimelineStatus.values.byName(v);
      } catch (_) {
        return TimelineStatus.noTargetDate;
      }
    }

    final start = _dt(json['startDate']) ?? DateTime.now();
    final target = _dt(json['targetDate']);
    final enabled = (json['timelineEnabled'] as bool?) ?? (target != null);
    final status = _status(json['timelineStatus']);
    return CareerPlan(
      goalId: json['goalId'] is String ? json['goalId'] as String : null,
      startDate: start,
      targetDate: target,
      timelineEnabled: enabled,
      timelineStatus: target == null ? TimelineStatus.noTargetDate : status,
    );
  }
}

class UserProfile {
  final List<String> currentRoles;
  final String? primaryGoalId;
  /// Back-compat: older profiles stored target date here.
  final DateTime? targetDate;
  final CareerPlan careerPlan;
  final int? yearsOfService;
  final String? serviceType;
  final String? departmentName;
  final String? state;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.currentRoles,
    required this.primaryGoalId,
    required this.targetDate,
    required this.careerPlan,
    required this.yearsOfService,
    required this.serviceType,
    required this.departmentName,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.empty() {
    final now = DateTime.now();
    return UserProfile(
      currentRoles: const [],
      primaryGoalId: null,
      targetDate: null,
      careerPlan: CareerPlan.empty(),
      yearsOfService: null,
      serviceType: null,
      departmentName: null,
      state: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  UserProfile copyWith({
    List<String>? currentRoles,
    String? primaryGoalId,
    DateTime? targetDate,
    CareerPlan? careerPlan,
    int? yearsOfService,
    String? serviceType,
    String? departmentName,
    String? state,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearPrimaryGoalId = false,
  }) {
    return UserProfile(
      currentRoles: currentRoles ?? this.currentRoles,
      primaryGoalId: clearPrimaryGoalId ? null : (primaryGoalId ?? this.primaryGoalId),
      targetDate: targetDate ?? this.targetDate,
      careerPlan: careerPlan ?? this.careerPlan,
      yearsOfService: yearsOfService ?? this.yearsOfService,
      serviceType: serviceType ?? this.serviceType,
      departmentName: departmentName ?? this.departmentName,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentRoles': currentRoles,
    'primaryGoalId': primaryGoalId,
    'targetDate': targetDate?.toIso8601String(),
    'careerPlan': careerPlan.toJson(),
    'yearsOfService': yearsOfService,
    'serviceType': serviceType,
    'departmentName': departmentName,
    'state': state,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;

    final currentRolesRaw = json['currentRoles'];
    final roles = currentRolesRaw is List ? currentRolesRaw.whereType<String>().toList() : <String>[];

    final created = _dt(json['createdAt']) ?? DateTime.now();
    final updated = _dt(json['updatedAt']) ?? created;

    final legacyTarget = _dt(json['targetDate']);
    final planRaw = json['careerPlan'];
    CareerPlan plan;
    if (planRaw is Map) {
      plan = CareerPlan.fromJson(Map<String, dynamic>.from(planRaw));
    } else {
      // Migration: if old targetDate existed, move it into the plan.
      final now = DateTime.now();
      plan = CareerPlan(
        goalId: json['primaryGoalId'] is String ? json['primaryGoalId'] as String : null,
        startDate: now,
        targetDate: legacyTarget,
        timelineEnabled: legacyTarget != null,
        timelineStatus: legacyTarget == null ? TimelineStatus.noTargetDate : TimelineStatus.needsAttention,
      );
    }

    // Keep plan.goalId aligned with primaryGoalId.
    final primaryGoalId = json['primaryGoalId'] is String ? json['primaryGoalId'] as String : null;
    if (primaryGoalId != null && plan.goalId != primaryGoalId) {
      plan = plan.copyWith(goalId: primaryGoalId);
    }

    return UserProfile(
      currentRoles: roles,
      primaryGoalId: primaryGoalId,
      targetDate: legacyTarget,
      careerPlan: plan,
      yearsOfService: json['yearsOfService'] is int ? json['yearsOfService'] as int : null,
      serviceType: json['serviceType'] is String ? json['serviceType'] as String : null,
      departmentName: json['departmentName'] is String ? json['departmentName'] as String : null,
      state: json['state'] is String ? json['state'] as String : null,
      createdAt: created,
      updatedAt: updated,
    );
  }

  @override
  String toString() => 'UserProfile(currentRoles: $currentRoles, primaryGoalId: $primaryGoalId)';
}
