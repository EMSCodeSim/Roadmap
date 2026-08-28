import 'package:flutter/foundation.dart';

@immutable
class ActivityEvent {
  final String id;
  final String departmentId;
  final String userId;
  final String type;
  final String referenceId;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ActivityEvent({
    required this.id,
    required this.departmentId,
    required this.userId,
    required this.type,
    required this.referenceId,
    required this.timestamp,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ActivityEvent(
      id: (json['id'] ?? '').toString(),
      departmentId: (json['departmentId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      referenceId: (json['referenceId'] ?? '').toString(),
      timestamp: dt('timestamp'),
      metadata: (json['metadata'] is Map)
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : <String, dynamic>{},
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'departmentId': departmentId,
        'userId': userId,
        'type': type,
        'referenceId': referenceId,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
