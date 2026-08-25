enum RequirementType {
  certification,
  trainingCourse,
  taskBook,
  experience,
  numericProgress,
  course,
  promotionalTest,
  practical,
  interview,
  education,
  custom,
}

/// Where this requirement typically comes from.
///
/// Note: even "commonly" items can be state/department dependent; use
/// [stateDependent]/[departmentDependent] flags for nuance.
enum RequirementSource { commonlyRequired, recommended, stateRequirement, departmentRequirement }

/// How important this requirement is for readiness.
enum RequirementPriority { core, recommended, development, department, state }

/// Timeline grouping for career planning.
enum TimelineCategory {
  certification,
  course,
  experience,
  taskBook,
  renewal,
  promotionalPreparation,
  development,
  departmentRequirement,
}

class ResourceLink {
  final String title;
  final String? url;

  const ResourceLink({required this.title, required this.url});

  Map<String, dynamic> toJson() => {'title': title, 'url': url};
  factory ResourceLink.fromJson(Map<String, dynamic> json) => ResourceLink(title: json['title'] as String, url: json['url'] as String?);
}

class Requirement {
  final String id;
  final String name;
  final String category;
  final RequirementPriority priority;
  final String description;
  final RequirementType type;
  final RequirementSource requirementSource;
  final bool defaultRequired;
  final bool stateDependent;
  final bool departmentDependent;
  final bool completed;
  final double? progressCurrent;
  final double? progressRequired;
  final String? progressUnit;
  final double? experienceValue;
  final String? experienceUnit;
  final String? certificationReference;

  /// Stable certification definition ID explicitly stored on this requirement.
  final String? _certificationDefinitionId;

  /// Stable certification definition ID for certification requirements.
  ///
  /// Explicit IDs remain authoritative. Older catalog/state requirements were
  /// sometimes created with only a human-readable label, which meant a user
  /// could already hold the credential but still see it as Next Best Step.
  /// This getter provides a narrow compatibility map for known common labels.
  String? get certificationDefinitionId {
    final explicit = _certificationDefinitionId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (type != RequirementType.certification) return null;
    return _inferKnownCertificationId(certificationReference ?? name);
  }

  static String? _inferKnownCertificationId(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return null;

    const exact = <String, String>{
      'firefighter i': 'firefighter_1',
      'firefighter 1': 'firefighter_1',
      'fire fighter i': 'firefighter_1',
      'fire fighter 1': 'firefighter_1',
      'fire 1': 'firefighter_1',
      'fire i': 'firefighter_1',
      'ff1': 'firefighter_1',
      'ff i': 'firefighter_1',
      'ff 1': 'firefighter_1',
      'firefighter ii': 'firefighter_2',
      'firefighter 2': 'firefighter_2',
      'fire fighter ii': 'firefighter_2',
      'fire fighter 2': 'firefighter_2',
      'fire 2': 'firefighter_2',
      'fire ii': 'firefighter_2',
      'ff2': 'firefighter_2',
      'ff ii': 'firefighter_2',
      'ff 2': 'firefighter_2',
      'hazmat awareness': 'hazmat_awareness',
      'haz mat awareness': 'hazmat_awareness',
      'hazardous materials awareness': 'hazmat_awareness',
      'hazmat operations': 'hazmat_operations',
      'hazmat ops': 'hazmat_operations',
      'haz mat operations': 'hazmat_operations',
      'haz mat ops': 'hazmat_operations',
      'hazardous materials operations': 'hazmat_operations',
      'emt': 'emt',
      'aemt': 'aemt',
      'advanced emt': 'aemt',
      'paramedic': 'paramedic',
    };
    final direct = exact[normalized];
    if (direct != null) return direct;

    // Legacy state/NREMT labels often include extra words around the credential.
    if (normalized.startsWith('national registry aemt') ||
        normalized.startsWith('state aemt certification')) {
      return 'aemt';
    }
    if (normalized.startsWith('national registry paramedic') ||
        normalized.startsWith('state paramedic certification')) {
      return 'paramedic';
    }
    if (normalized.startsWith('national registry emt') ||
        normalized.startsWith('state emt certification')) {
      return 'emt';
    }
    return null;
  }

  /// If true, an expired credential can still satisfy this requirement.
  /// Defaults to false.
  final bool allowExpiredCertification;
  /// Prerequisite requirement keys.
  ///
  /// In the starter dataset these are typically certification names (e.g.
  /// "Firefighter I"). In future builds this can evolve to true requirement IDs.
  final List<String> prerequisiteRequirementIds;
  final List<String> resourceIds;
  final List<ResourceLink> resourceLinks;
  final int sortOrder;

  /// Optional metadata for VERIFIED state requirements.
  ///
  /// These fields are only set when FireOps Career Road has a verified state
  /// source for a requirement. If null, the requirement should NOT be
  /// interpreted as an official state requirement.
  final String? sourceStateCode;
  final String? sourceTitle;
  final String? sourceUrl;
  final DateTime? sourceVerifiedDate;
  final String? sourceNotes;

  // Timeline estimation metadata (optional).
  final int? estimatedDurationDays;
  final int? recommendedLeadTimeDays;
  final bool canRunConcurrent;
  final TimelineCategory? timelineCategory;

  // Optional planning dates (usually set via user overrides; not required).
  final DateTime? suggestedStartDate;
  final DateTime? suggestedCompletionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Requirement({
    required this.id,
    required this.name,
    required this.category,
    required this.priority,
    required this.description,
    required this.type,
    required this.requirementSource,
    required this.defaultRequired,
    required this.stateDependent,
    required this.departmentDependent,
    required this.completed,
    required this.progressCurrent,
    required this.progressRequired,
    required this.progressUnit,
    required this.experienceValue,
    required this.experienceUnit,
    required this.certificationReference,
    required String? certificationDefinitionId,
    required this.allowExpiredCertification,
    required this.prerequisiteRequirementIds,
    required this.resourceIds,
    required this.resourceLinks,
    required this.sortOrder,

    this.sourceStateCode,
    this.sourceTitle,
    this.sourceUrl,
    this.sourceVerifiedDate,
    this.sourceNotes,

    required this.estimatedDurationDays,
    required this.recommendedLeadTimeDays,
    required this.canRunConcurrent,
    required this.timelineCategory,
    required this.suggestedStartDate,
    required this.suggestedCompletionDate,
    required this.createdAt,
    required this.updatedAt,
  }) : _certificationDefinitionId = certificationDefinitionId;

  Requirement copyWith({
    String? name,
    String? category,
    RequirementPriority? priority,
    String? description,
    RequirementType? type,
    RequirementSource? requirementSource,
    bool? defaultRequired,
    bool? stateDependent,
    bool? departmentDependent,
    bool? completed,
    double? progressCurrent,
    double? progressRequired,
    String? progressUnit,
    double? experienceValue,
    String? experienceUnit,
    String? certificationReference,
    String? certificationDefinitionId,
    bool? allowExpiredCertification,
    List<String>? prerequisiteRequirementIds,
    List<String>? resourceIds,
    List<ResourceLink>? resourceLinks,
    int? sortOrder,

    String? sourceStateCode,
    String? sourceTitle,
    String? sourceUrl,
    DateTime? sourceVerifiedDate,
    String? sourceNotes,
    int? estimatedDurationDays,
    int? recommendedLeadTimeDays,
    bool? canRunConcurrent,
    TimelineCategory? timelineCategory,
    DateTime? suggestedStartDate,
    DateTime? suggestedCompletionDate,
    DateTime? updatedAt,
  }) {
    return Requirement(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      type: type ?? this.type,
      requirementSource: requirementSource ?? this.requirementSource,
      defaultRequired: defaultRequired ?? this.defaultRequired,
      stateDependent: stateDependent ?? this.stateDependent,
      departmentDependent: departmentDependent ?? this.departmentDependent,
      completed: completed ?? this.completed,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressRequired: progressRequired ?? this.progressRequired,
      progressUnit: progressUnit ?? this.progressUnit,
      experienceValue: experienceValue ?? this.experienceValue,
      experienceUnit: experienceUnit ?? this.experienceUnit,
      certificationReference: certificationReference ?? this.certificationReference,
      certificationDefinitionId: certificationDefinitionId ?? this.certificationDefinitionId,
      allowExpiredCertification: allowExpiredCertification ?? this.allowExpiredCertification,
      prerequisiteRequirementIds: prerequisiteRequirementIds ?? this.prerequisiteRequirementIds,
      resourceIds: resourceIds ?? this.resourceIds,
      resourceLinks: resourceLinks ?? this.resourceLinks,
      sortOrder: sortOrder ?? this.sortOrder,

      sourceStateCode: sourceStateCode ?? this.sourceStateCode,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceVerifiedDate: sourceVerifiedDate ?? this.sourceVerifiedDate,
      sourceNotes: sourceNotes ?? this.sourceNotes,

      estimatedDurationDays: estimatedDurationDays ?? this.estimatedDurationDays,
      recommendedLeadTimeDays: recommendedLeadTimeDays ?? this.recommendedLeadTimeDays,
      canRunConcurrent: canRunConcurrent ?? this.canRunConcurrent,
      timelineCategory: timelineCategory ?? this.timelineCategory,
      suggestedStartDate: suggestedStartDate ?? this.suggestedStartDate,
      suggestedCompletionDate: suggestedCompletionDate ?? this.suggestedCompletionDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'priority': priority.name,
    'description': description,
    'type': type.name,
    'requirementSource': requirementSource.name,
    'defaultRequired': defaultRequired,
    'stateDependent': stateDependent,
    'departmentDependent': departmentDependent,
    'completed': completed,
    'progressCurrent': progressCurrent,
    'progressRequired': progressRequired,
    'progressUnit': progressUnit,
    'experienceValue': experienceValue,
    'experienceUnit': experienceUnit,
    'certificationReference': certificationReference,
    'certificationDefinitionId': certificationDefinitionId,
    'allowExpiredCertification': allowExpiredCertification,
    'prerequisiteRequirementIds': prerequisiteRequirementIds,
    'resourceIds': resourceIds,
    'resourceLinks': resourceLinks.map((e) => e.toJson()).toList(),
    'sortOrder': sortOrder,

    'sourceStateCode': sourceStateCode,
    'sourceTitle': sourceTitle,
    'sourceUrl': sourceUrl,
    'sourceVerifiedDate': sourceVerifiedDate?.toIso8601String(),
    'sourceNotes': sourceNotes,
    'estimatedDurationDays': estimatedDurationDays,
    'recommendedLeadTimeDays': recommendedLeadTimeDays,
    'canRunConcurrent': canRunConcurrent,
    'timelineCategory': timelineCategory?.name,
    'suggestedStartDate': suggestedStartDate?.toIso8601String(),
    'suggestedCompletionDate': suggestedCompletionDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Requirement.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    final now = DateTime.now();
    final created = _dt(json['createdAt']) ?? now;
    final updated = _dt(json['updatedAt']) ?? created;
    final linksRaw = json['resourceLinks'];
    final links = linksRaw is List ? linksRaw.whereType<Map>().map((e) => ResourceLink.fromJson(Map<String, dynamic>.from(e))).toList() : <ResourceLink>[];

    // Back-compat:
    // - old dataset didn't have category/priority/dependency flags.
    // - old dataset used certificationReference and resourceLinks only.
    RequirementPriority _priorityFallback(RequirementSource src) {
      switch (src) {
        case RequirementSource.commonlyRequired:
          return RequirementPriority.core;
        case RequirementSource.recommended:
          return RequirementPriority.recommended;
        case RequirementSource.stateRequirement:
          return RequirementPriority.core;
        case RequirementSource.departmentRequirement:
          return RequirementPriority.department;
      }
    }

    final src = RequirementSource.values.byName((json['requirementSource'] as String?) ?? RequirementSource.recommended.name);

    final prereqRaw = json['prerequisiteRequirementIds'] ?? json['prerequisiteCertificationIds'];
    final prereq = prereqRaw is List ? prereqRaw.whereType<String>().toList() : <String>[];

    final resIdsRaw = json['resourceIds'];
    final resIds = resIdsRaw is List ? resIdsRaw.whereType<String>().toList() : <String>[];

    bool _bool(dynamic v, bool fallback) => v is bool ? v : fallback;

    RequirementType _parseType(dynamic v) {
      if (v is! String) return RequirementType.custom;
      try {
        return RequirementType.values.byName(v);
      } catch (_) {
        // Back-compat for older type names.
        if (v == 'trainingCourse') return RequirementType.trainingCourse;
        return RequirementType.custom;
      }
    }

    TimelineCategory? _parseTimelineCategory(dynamic v) {
      if (v is! String) return null;
      try {
        return TimelineCategory.values.byName(v);
      } catch (_) {
        return null;
      }
    }

    RequirementPriority _parsePriority(dynamic v) {
      if (v is! String) return _priorityFallback(src);
      try {
        return RequirementPriority.values.byName(v);
      } catch (_) {
        return _priorityFallback(src);
      }
    }

    return Requirement(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'General',
      priority: _parsePriority(json['priority']),
      description: (json['description'] as String?) ?? '',
      type: _parseType(json['type']),
      requirementSource: src,
      defaultRequired: (json['defaultRequired'] as bool?) ?? true,
      stateDependent: (json['stateDependent'] as bool?) ?? (src == RequirementSource.stateRequirement),
      departmentDependent: (json['departmentDependent'] as bool?) ?? (src == RequirementSource.departmentRequirement),
      completed: (json['completed'] as bool?) ?? false,
      progressCurrent: (json['progressCurrent'] as num?)?.toDouble(),
      progressRequired: (json['progressRequired'] as num?)?.toDouble(),
      progressUnit: json['progressUnit'] as String?,
      experienceValue: (json['experienceValue'] as num?)?.toDouble(),
      experienceUnit: json['experienceUnit'] as String?,
      certificationReference: json['certificationReference'] as String?,
      certificationDefinitionId: json['certificationDefinitionId'] as String?,
      allowExpiredCertification: _bool(json['allowExpiredCertification'], false),
      prerequisiteRequirementIds: prereq,
      resourceIds: resIds,
      resourceLinks: links,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,

      sourceStateCode: json['sourceStateCode'] as String?,
      sourceTitle: json['sourceTitle'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      sourceVerifiedDate: _dt(json['sourceVerifiedDate']),
      sourceNotes: json['sourceNotes'] as String?,

      estimatedDurationDays: (json['estimatedDurationDays'] as num?)?.toInt(),
      recommendedLeadTimeDays: (json['recommendedLeadTimeDays'] as num?)?.toInt(),
      canRunConcurrent: (json['canRunConcurrent'] as bool?) ?? true,
      timelineCategory: _parseTimelineCategory(json['timelineCategory']),
      suggestedStartDate: _dt(json['suggestedStartDate']),
      suggestedCompletionDate: _dt(json['suggestedCompletionDate']),
      createdAt: created,
      updatedAt: updated,
    );
  }
}
