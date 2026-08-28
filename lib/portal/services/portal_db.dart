import 'package:flutter/foundation.dart';

import 'package:firepath/portal/models/activity_event.dart';
import 'package:firepath/portal/models/assignment_models.dart';
import 'package:firepath/portal/models/credential.dart';
import 'package:firepath/portal/models/department.dart';
import 'package:firepath/portal/models/department_membership.dart';
import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/models/task_book_template.dart';

/// A lightweight, local-only database representation for the Department Portal.
///
/// This is intentionally a single persisted document so we can ship a complete
/// demo workflow with no backend connected. When a backend is connected later,
/// the service layer can swap to remote reads/writes while keeping UI stable.
@immutable
class PortalDb {
  final List<Department> departments;
  final List<PortalUser> users;
  final List<DepartmentMembership> memberships;

  final List<TaskBookTemplate> taskBookTemplates;
  final List<TaskBookVersion> taskBookVersions;
  final List<TaskBookSection> taskBookSections;
  final List<TaskBookRequirement> taskBookRequirements;

  final List<TaskBookAssignment> assignments;
  final List<RequirementCompletion> completions;
  final List<Evidence> evidence;
  final List<SignOff> signOffs;

  final List<Credential> credentials;
  final List<ActivityEvent> activity;

  final DateTime createdAt;
  final DateTime updatedAt;

  const PortalDb({
    required this.departments,
    required this.users,
    required this.memberships,
    required this.taskBookTemplates,
    required this.taskBookVersions,
    required this.taskBookSections,
    required this.taskBookRequirements,
    required this.assignments,
    required this.completions,
    required this.evidence,
    required this.signOffs,
    required this.credentials,
    required this.activity,
    required this.createdAt,
    required this.updatedAt,
  });

  PortalDb copyWith({
    List<Department>? departments,
    List<PortalUser>? users,
    List<DepartmentMembership>? memberships,
    List<TaskBookTemplate>? taskBookTemplates,
    List<TaskBookVersion>? taskBookVersions,
    List<TaskBookSection>? taskBookSections,
    List<TaskBookRequirement>? taskBookRequirements,
    List<TaskBookAssignment>? assignments,
    List<RequirementCompletion>? completions,
    List<Evidence>? evidence,
    List<SignOff>? signOffs,
    List<Credential>? credentials,
    List<ActivityEvent>? activity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PortalDb(
      departments: departments ?? this.departments,
      users: users ?? this.users,
      memberships: memberships ?? this.memberships,
      taskBookTemplates: taskBookTemplates ?? this.taskBookTemplates,
      taskBookVersions: taskBookVersions ?? this.taskBookVersions,
      taskBookSections: taskBookSections ?? this.taskBookSections,
      taskBookRequirements: taskBookRequirements ?? this.taskBookRequirements,
      assignments: assignments ?? this.assignments,
      completions: completions ?? this.completions,
      evidence: evidence ?? this.evidence,
      signOffs: signOffs ?? this.signOffs,
      credentials: credentials ?? this.credentials,
      activity: activity ?? this.activity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PortalDb.empty() {
    final now = DateTime.now();
    return PortalDb(
      departments: const [],
      users: const [],
      memberships: const [],
      taskBookTemplates: const [],
      taskBookVersions: const [],
      taskBookSections: const [],
      taskBookRequirements: const [],
      assignments: const [],
      completions: const [],
      evidence: const [],
      signOffs: const [],
      credentials: const [],
      activity: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory PortalDb.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    List<Map<String, dynamic>> list(String key) {
      final raw = json[key];
      if (raw is List) {
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return const [];
    }

    return PortalDb(
      departments: list('departments').map(Department.fromJson).toList(),
      users: list('users').map(PortalUser.fromJson).toList(),
      memberships: list('memberships').map(DepartmentMembership.fromJson).toList(),
      taskBookTemplates: list('taskBookTemplates').map(TaskBookTemplate.fromJson).toList(),
      taskBookVersions: list('taskBookVersions').map(TaskBookVersion.fromJson).toList(),
      taskBookSections: list('taskBookSections').map(TaskBookSection.fromJson).toList(),
      taskBookRequirements: list('taskBookRequirements').map(TaskBookRequirement.fromJson).toList(),
      assignments: list('assignments').map(TaskBookAssignment.fromJson).toList(),
      completions: list('completions').map(RequirementCompletion.fromJson).toList(),
      evidence: list('evidence').map(Evidence.fromJson).toList(),
      signOffs: list('signOffs').map(SignOff.fromJson).toList(),
      credentials: list('credentials').map(Credential.fromJson).toList(),
      activity: list('activity').map(ActivityEvent.fromJson).toList(),
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'departments': departments.map((e) => e.toJson()).toList(),
        'users': users.map((e) => e.toJson()).toList(),
        'memberships': memberships.map((e) => e.toJson()).toList(),
        'taskBookTemplates': taskBookTemplates.map((e) => e.toJson()).toList(),
        'taskBookVersions': taskBookVersions.map((e) => e.toJson()).toList(),
        'taskBookSections': taskBookSections.map((e) => e.toJson()).toList(),
        'taskBookRequirements': taskBookRequirements.map((e) => e.toJson()).toList(),
        'assignments': assignments.map((e) => e.toJson()).toList(),
        'completions': completions.map((e) => e.toJson()).toList(),
        'evidence': evidence.map((e) => e.toJson()).toList(),
        'signOffs': signOffs.map((e) => e.toJson()).toList(),
        'credentials': credentials.map((e) => e.toJson()).toList(),
        'activity': activity.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
