import 'package:flutter/foundation.dart';

import 'package:firepath/models/requirement.dart';

/// User-created (department/custom) Task Book.
///
/// Stored locally and designed to coexist with the generated Career Road Task
/// Book. Progress for requirements inside a custom book is tracked via the
/// existing [PathRequirementOverride] layer by using a stable pseudo goal ID.
@immutable
class CustomTaskBook {
  final String id;
  final String name;
  final bool departmentSpecific;
  final String? linkedGoalId;
  final bool archived;
  final List<Requirement> requirements;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomTaskBook({
    required this.id,
    required this.name,
    required this.departmentSpecific,
    required this.linkedGoalId,
    required this.archived,
    required this.requirements,
    required this.createdAt,
    required this.updatedAt,
  });

  static String pseudoGoalIdFor(String taskBookId) => 'custom_task_book::$taskBookId';

  String get pseudoGoalId => pseudoGoalIdFor(id);

  CustomTaskBook copyWith({
    String? name,
    bool? departmentSpecific,
    String? linkedGoalId,
    bool? archived,
    List<Requirement>? requirements,
    DateTime? updatedAt,
  }) {
    return CustomTaskBook(
      id: id,
      name: name ?? this.name,
      departmentSpecific: departmentSpecific ?? this.departmentSpecific,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      archived: archived ?? this.archived,
      requirements: requirements ?? this.requirements,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'departmentSpecific': departmentSpecific,
        'linkedGoalId': linkedGoalId,
        'archived': archived,
        'requirements': requirements.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CustomTaskBook.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    final reqsRaw = json['requirements'];
    final reqs = <Requirement>[];
    if (reqsRaw is List) {
      for (final item in reqsRaw.whereType<Map>()) {
        try {
          reqs.add(Requirement.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Skip corrupted entries instead of failing the whole load.
        }
      }
    }

    final created = parseDate(json['createdAt']);
    final updated = parseDate(json['updatedAt']);

    return CustomTaskBook(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Custom Task Book',
      departmentSpecific: (json['departmentSpecific'] as bool?) ?? true,
      linkedGoalId: json['linkedGoalId'] as String?,
      archived: (json['archived'] as bool?) ?? false,
      requirements: reqs,
      createdAt: created,
      updatedAt: updated.isBefore(created) ? created : updated,
    );
  }
}
