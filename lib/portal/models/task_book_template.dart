import 'package:flutter/foundation.dart';

enum TaskBookTemplateStatus { draft, active, archived }

extension TaskBookTemplateStatusLabel on TaskBookTemplateStatus {
  String get label => switch (this) {
        TaskBookTemplateStatus.draft => 'Draft',
        TaskBookTemplateStatus.active => 'Active',
        TaskBookTemplateStatus.archived => 'Archived',
      };
}

enum EvidenceType {
  none,
  writtenNote,
  photo,
  file,
  supervisorObservation,
  skillEvaluation,
  trainingAttendance,
  certificationUpload,
}

extension EvidenceTypeLabel on EvidenceType {
  String get label => switch (this) {
        EvidenceType.none => 'No evidence required',
        EvidenceType.writtenNote => 'Written note',
        EvidenceType.photo => 'Photo',
        EvidenceType.file => 'File',
        EvidenceType.supervisorObservation => 'Supervisor observation',
        EvidenceType.skillEvaluation => 'Skill evaluation',
        EvidenceType.trainingAttendance => 'Training attendance',
        EvidenceType.certificationUpload => 'Certification upload',
      };
}

@immutable
class TaskBookTemplate {
  final String id;
  final String departmentId;
  final String title;
  final String description;
  final String category;
  final String ownerUserId;
  final TaskBookTemplateStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskBookTemplate({
    required this.id,
    required this.departmentId,
    required this.title,
    required this.description,
    required this.category,
    required this.ownerUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskBookTemplate copyWith({
    String? id,
    String? departmentId,
    String? title,
    String? description,
    String? category,
    String? ownerUserId,
    TaskBookTemplateStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskBookTemplate(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskBookTemplate.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    TaskBookTemplateStatus statusFrom(String? v) => TaskBookTemplateStatus.values.firstWhere(
          (e) => e.name == v,
          orElse: () => TaskBookTemplateStatus.draft,
        );

    return TaskBookTemplate(
      id: (json['id'] ?? '').toString(),
      departmentId: (json['departmentId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      ownerUserId: (json['ownerUserId'] ?? '').toString(),
      status: statusFrom(json['status'] as String?),
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'departmentId': departmentId,
        'title': title,
        'description': description,
        'category': category,
        'ownerUserId': ownerUserId,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

@immutable
class TaskBookVersion {
  final String id;
  final String templateId;
  final String version;
  final bool isPublished;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskBookVersion({
    required this.id,
    required this.templateId,
    required this.version,
    required this.isPublished,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskBookVersion copyWith({
    String? id,
    String? templateId,
    String? version,
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskBookVersion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      version: version ?? this.version,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskBookVersion.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return TaskBookVersion(
      id: (json['id'] ?? '').toString(),
      templateId: (json['templateId'] ?? '').toString(),
      version: (json['version'] ?? '').toString(),
      isPublished: (json['isPublished'] as bool?) ?? false,
      publishedAt: dt('publishedAt'),
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'version': version,
        'isPublished': isPublished,
        'publishedAt': publishedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

@immutable
class TaskBookSection {
  final String id;
  final String versionId;
  final String title;
  final String description;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskBookSection({
    required this.id,
    required this.versionId,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskBookSection copyWith({
    String? id,
    String? versionId,
    String? title,
    String? description,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskBookSection(
      id: id ?? this.id,
      versionId: versionId ?? this.versionId,
      title: title ?? this.title,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskBookSection.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return TaskBookSection(
      id: (json['id'] ?? '').toString(),
      versionId: (json['versionId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'versionId': versionId,
        'title': title,
        'description': description,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

@immutable
class TaskBookRequirement {
  final String id;
  final String sectionId;
  final String title;
  final String description;
  final String instructions;
  final int sortOrder;
  final bool isRequired;
  final bool evaluatorSignOffRequired;
  final bool supervisorApprovalRequired;
  final EvidenceType evidenceType;
  final int repetitionsRequired;
  final int? dueOffsetDays;
  final List<String> prerequisiteRequirementIds;
  final List<String> tags;
  final int? estimatedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskBookRequirement({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.description,
    required this.instructions,
    required this.sortOrder,
    required this.isRequired,
    required this.evaluatorSignOffRequired,
    required this.supervisorApprovalRequired,
    required this.evidenceType,
    required this.repetitionsRequired,
    required this.dueOffsetDays,
    required this.prerequisiteRequirementIds,
    required this.tags,
    required this.estimatedMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskBookRequirement copyWith({
    String? id,
    String? sectionId,
    String? title,
    String? description,
    String? instructions,
    int? sortOrder,
    bool? isRequired,
    bool? evaluatorSignOffRequired,
    bool? supervisorApprovalRequired,
    EvidenceType? evidenceType,
    int? repetitionsRequired,
    int? dueOffsetDays,
    List<String>? prerequisiteRequirementIds,
    List<String>? tags,
    int? estimatedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskBookRequirement(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      sortOrder: sortOrder ?? this.sortOrder,
      isRequired: isRequired ?? this.isRequired,
      evaluatorSignOffRequired: evaluatorSignOffRequired ?? this.evaluatorSignOffRequired,
      supervisorApprovalRequired: supervisorApprovalRequired ?? this.supervisorApprovalRequired,
      evidenceType: evidenceType ?? this.evidenceType,
      repetitionsRequired: repetitionsRequired ?? this.repetitionsRequired,
      dueOffsetDays: dueOffsetDays ?? this.dueOffsetDays,
      prerequisiteRequirementIds: prerequisiteRequirementIds ?? this.prerequisiteRequirementIds,
      tags: tags ?? this.tags,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskBookRequirement.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    EvidenceType evidenceFrom(String? v) => EvidenceType.values.firstWhere(
          (e) => e.name == v,
          orElse: () => EvidenceType.none,
        );

    return TaskBookRequirement(
      id: (json['id'] ?? '').toString(),
      sectionId: (json['sectionId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isRequired: (json['isRequired'] as bool?) ?? true,
      evaluatorSignOffRequired: (json['evaluatorSignOffRequired'] as bool?) ?? true,
      supervisorApprovalRequired: (json['supervisorApprovalRequired'] as bool?) ?? false,
      evidenceType: evidenceFrom(json['evidenceType'] as String?),
      repetitionsRequired: (json['repetitionsRequired'] as num?)?.toInt() ?? 1,
      dueOffsetDays: (json['dueOffsetDays'] as num?)?.toInt(),
      prerequisiteRequirementIds: (json['prerequisiteRequirementIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sectionId': sectionId,
        'title': title,
        'description': description,
        'instructions': instructions,
        'sortOrder': sortOrder,
        'isRequired': isRequired,
        'evaluatorSignOffRequired': evaluatorSignOffRequired,
        'supervisorApprovalRequired': supervisorApprovalRequired,
        'evidenceType': evidenceType.name,
        'repetitionsRequired': repetitionsRequired,
        'dueOffsetDays': dueOffsetDays,
        'prerequisiteRequirementIds': prerequisiteRequirementIds,
        'tags': tags,
        'estimatedMinutes': estimatedMinutes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
