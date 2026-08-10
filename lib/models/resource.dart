enum ResourceType { officialAgency, courseProvider, studyGuide, practice, video, fireOpsTool, departmentResource }

class Resource {
  final String id;
  final String title;
  final String description;
  final ResourceType type;
  final String? url;
  final String? state;
  final List<String> relatedCertificationIds;
  final List<String> relatedCareerGoalIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required this.state,
    required this.relatedCertificationIds,
    required this.relatedCareerGoalIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'url': url,
    'state': state,
    'relatedCertificationIds': relatedCertificationIds,
    'relatedCareerGoalIds': relatedCareerGoalIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Resource.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    final now = DateTime.now();
    final created = _dt(json['createdAt']) ?? now;
    final updated = _dt(json['updatedAt']) ?? created;
    final relatedCertsRaw = json['relatedCertificationIds'];
    final relatedGoalsRaw = json['relatedCareerGoalIds'];
    return Resource(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      type: ResourceType.values.byName((json['type'] as String?) ?? ResourceType.studyGuide.name),
      url: json['url'] as String?,
      state: json['state'] as String?,
      relatedCertificationIds: relatedCertsRaw is List ? relatedCertsRaw.whereType<String>().toList() : <String>[],
      relatedCareerGoalIds: relatedGoalsRaw is List ? relatedGoalsRaw.whereType<String>().toList() : <String>[],
      createdAt: created,
      updatedAt: updated,
    );
  }
}
