import 'package:flutter/foundation.dart';

@immutable
class Department {
  final String id;
  final String name;
  final String joinCode;
  final String? timeZone;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Department({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.timeZone,
    required this.createdAt,
    required this.updatedAt,
  });

  Department copyWith({
    String? id,
    String? name,
    String? joinCode,
    String? timeZone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      joinCode: joinCode ?? this.joinCode,
      timeZone: timeZone ?? this.timeZone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Department.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

    return Department(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      joinCode: (json['joinCode'] ?? '').toString(),
      timeZone: json['timeZone'] as String?,
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'joinCode': joinCode,
        'timeZone': timeZone,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
