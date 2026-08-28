import 'package:flutter/foundation.dart';

enum PortalRole {
  member,
  evaluator,
  trainingOfficer,
  departmentAdmin,
}

extension PortalRoleLabels on PortalRole {
  String get label => switch (this) {
        PortalRole.member => 'Member',
        PortalRole.evaluator => 'Evaluator',
        PortalRole.trainingOfficer => 'Training Officer',
        PortalRole.departmentAdmin => 'Department Administrator',
      };
}

@immutable
class PortalUser {
  final String id;
  final String name;
  final String email;

  /// Department-facing attributes (for roster display)
  final String? rank;
  final String? station;
  final String? shift;
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  const PortalUser({
    required this.id,
    required this.name,
    required this.email,
    required this.rank,
    required this.station,
    required this.shift,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  PortalUser copyWith({
    String? id,
    String? name,
    String? email,
    String? rank,
    String? station,
    String? shift,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PortalUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      rank: rank ?? this.rank,
      station: station ?? this.station,
      shift: shift ?? this.shift,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PortalUser.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

    return PortalUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      rank: (json['rank'] as String?),
      station: (json['station'] as String?),
      shift: (json['shift'] as String?),
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'rank': rank,
        'station': station,
        'shift': shift,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
