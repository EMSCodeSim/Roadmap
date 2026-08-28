import 'package:flutter/foundation.dart';

import 'package:firepath/portal/models/portal_user.dart';

enum MembershipStatus { pending, active, inactive }

extension MembershipStatusLabel on MembershipStatus {
  String get label => switch (this) {
        MembershipStatus.pending => 'Pending',
        MembershipStatus.active => 'Active',
        MembershipStatus.inactive => 'Inactive',
      };
}

@immutable
class DepartmentMembership {
  final String id;
  final String departmentId;
  final String userId;
  final PortalRole role;
  final MembershipStatus status;
  final DateTime joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DepartmentMembership({
    required this.id,
    required this.departmentId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  DepartmentMembership copyWith({
    String? id,
    String? departmentId,
    String? userId,
    PortalRole? role,
    MembershipStatus? status,
    DateTime? joinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DepartmentMembership(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DepartmentMembership.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    PortalRole roleFrom(String? v) => PortalRole.values.firstWhere(
          (e) => e.name == v,
          orElse: () => PortalRole.member,
        );
    MembershipStatus statusFrom(String? v) => MembershipStatus.values.firstWhere(
          (e) => e.name == v,
          orElse: () => MembershipStatus.active,
        );

    return DepartmentMembership(
      id: (json['id'] ?? '').toString(),
      departmentId: (json['departmentId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      role: roleFrom(json['role'] as String?),
      status: statusFrom(json['status'] as String?),
      joinedAt: dt('joinedAt'),
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'departmentId': departmentId,
        'userId': userId,
        'role': role.name,
        'status': status.name,
        'joinedAt': joinedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
