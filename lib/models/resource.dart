enum ResourceType {
  officialStateAgency,
  officialFederalAgency,
  credentialingOrganization,
  trainingProvider,
  courseFinder,
  collegeAcademy,
  studyResource,
  practiceResource,
  fireOpsTool,
  professionalOrganization,
  departmentResource,
}

enum ResourceSourceType { official, credentialing, training, education, study, practice, tool, department, unknown }

class Resource {
  final String id;
  final String title;
  final String description;
  final ResourceType type;
  final String? url;
  final String? state;
  /// Stable certificationDefinition IDs this resource relates to.
  final List<String> relatedCertificationDefinitionIds;
  final List<String> relatedCareerGoalIds;
  final bool verified;
  final DateTime? lastVerifiedDate;
  final ResourceSourceType sourceType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required this.state,
    required this.relatedCertificationDefinitionIds,
    required this.relatedCareerGoalIds,
    required this.verified,
    required this.lastVerifiedDate,
    required this.sourceType,
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
    'relatedCertificationDefinitionIds': relatedCertificationDefinitionIds,
    'relatedCareerGoalIds': relatedCareerGoalIds,
    'verified': verified,
    'lastVerifiedDate': lastVerifiedDate?.toIso8601String(),
    'sourceType': sourceType.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Resource.fromJson(Map<String, dynamic> json) {
    DateTime? dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    final now = DateTime.now();
    final created = dt(json['createdAt']) ?? now;
    final updated = dt(json['updatedAt']) ?? created;
    final relatedCertsRaw = json['relatedCertificationDefinitionIds'] ?? json['relatedCertificationIds'];
    final relatedGoalsRaw = json['relatedCareerGoalIds'];
    ResourceType type(dynamic v) {
      if (v is! String) return ResourceType.studyResource;
      try {
        return ResourceType.values.byName(v);
      } catch (_) {
        // Back-compat mappings.
        return switch (v) {
          'officialAgency' => ResourceType.officialFederalAgency,
          'courseProvider' => ResourceType.trainingProvider,
          'studyGuide' => ResourceType.studyResource,
          'practice' => ResourceType.practiceResource,
          'video' => ResourceType.studyResource,
          'fireOpsTool' => ResourceType.fireOpsTool,
          'departmentResource' => ResourceType.departmentResource,
          _ => ResourceType.studyResource,
        };
      }
    }

    ResourceSourceType source(dynamic v) {
      if (v is! String) return ResourceSourceType.unknown;
      try {
        return ResourceSourceType.values.byName(v);
      } catch (_) {
        return ResourceSourceType.unknown;
      }
    }

    return Resource(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      type: type(json['type']),
      url: json['url'] as String?,
      state: json['state'] as String?,
      relatedCertificationDefinitionIds: relatedCertsRaw is List ? relatedCertsRaw.whereType<String>().toList() : <String>[],
      relatedCareerGoalIds: relatedGoalsRaw is List ? relatedGoalsRaw.whereType<String>().toList() : <String>[],
      verified: (json['verified'] as bool?) ?? false,
      lastVerifiedDate: dt(json['lastVerifiedDate']),
      sourceType: source(json['sourceType']),
      createdAt: created,
      updatedAt: updated,
    );
  }
}
