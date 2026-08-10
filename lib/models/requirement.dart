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
  /// Prerequisite requirement keys.
  ///
  /// In the starter dataset these are typically certification names (e.g.
  /// "Firefighter I"). In future builds this can evolve to true requirement IDs.
  final List<String> prerequisiteRequirementIds;
  final List<String> resourceIds;
  final List<ResourceLink> resourceLinks;
  final int sortOrder;

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
    required this.prerequisiteRequirementIds,
    required this.resourceIds,
    required this.resourceLinks,
    required this.sortOrder,

    required this.estimatedDurationDays,
    required this.recommendedLeadTimeDays,
    required this.canRunConcurrent,
    required this.timelineCategory,
    required this.suggestedStartDate,
    required this.suggestedCompletionDate,
    required this.createdAt,
    required this.updatedAt,
  });

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
    List<String>? prerequisiteRequirementIds,
    List<String>? resourceIds,
    List<ResourceLink>? resourceLinks,
    int? sortOrder,
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
      prerequisiteRequirementIds: prerequisiteRequirementIds ?? this.prerequisiteRequirementIds,
      resourceIds: resourceIds ?? this.resourceIds,
      resourceLinks: resourceLinks ?? this.resourceLinks,
      sortOrder: sortOrder ?? this.sortOrder,

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
    'prerequisiteRequirementIds': prerequisiteRequirementIds,
    'resourceIds': resourceIds,
    'resourceLinks': resourceLinks.map((e) => e.toJson()).toList(),
    'sortOrder': sortOrder,
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
      prerequisiteRequirementIds: prereq,
      resourceIds: resIds,
      resourceLinks: links,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,

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
