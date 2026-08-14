enum TransferRequirementKind {
  certification,
  experience,
  taskBook,
  education,
  practical,
  other,
}

extension TransferRequirementKindX on TransferRequirementKind {
  String get label => switch (this) {
    TransferRequirementKind.certification => 'Certification',
    TransferRequirementKind.experience => 'Experience',
    TransferRequirementKind.taskBook => 'Task book',
    TransferRequirementKind.education => 'Education',
    TransferRequirementKind.practical => 'Practical / process',
    TransferRequirementKind.other => 'Other',
  };
}

class DepartmentTransferRequirement {
  final String id;
  final String title;
  final TransferRequirementKind kind;
  final String? certificationDefinitionId;
  final List<String> keywords;
  final bool manuallySatisfied;
  final String? notes;

  const DepartmentTransferRequirement({
    required this.id,
    required this.title,
    required this.kind,
    required this.certificationDefinitionId,
    required this.keywords,
    required this.manuallySatisfied,
    required this.notes,
  });

  DepartmentTransferRequirement copyWith({
    String? title,
    TransferRequirementKind? kind,
    String? certificationDefinitionId,
    List<String>? keywords,
    bool? manuallySatisfied,
    String? notes,
    bool clearCertificationDefinitionId = false,
    bool clearNotes = false,
  }) {
    return DepartmentTransferRequirement(
      id: id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      certificationDefinitionId: clearCertificationDefinitionId
          ? null
          : (certificationDefinitionId ?? this.certificationDefinitionId),
      keywords: keywords ?? this.keywords,
      manuallySatisfied: manuallySatisfied ?? this.manuallySatisfied,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'certificationDefinitionId': certificationDefinitionId,
    'keywords': keywords,
    'manuallySatisfied': manuallySatisfied,
    'notes': notes,
  };

  factory DepartmentTransferRequirement.fromJson(Map<String, dynamic> json) {
    TransferRequirementKind parseKind(dynamic value) {
      if (value is String) {
        try {
          return TransferRequirementKind.values.byName(value);
        } catch (_) {}
      }
      return TransferRequirementKind.other;
    }

    return DepartmentTransferRequirement(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      kind: parseKind(json['kind']),
      certificationDefinitionId: json['certificationDefinitionId'] as String?,
      keywords:
          (json['keywords'] as List?)?.whereType<String>().toList() ?? const [],
      manuallySatisfied: (json['manuallySatisfied'] as bool?) ?? false,
      notes: json['notes'] as String?,
    );
  }
}

class DepartmentTransferPlan {
  final String departmentName;
  final String? targetGoalId;
  final String? targetRole;
  final List<DepartmentTransferRequirement> requirements;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DepartmentTransferPlan({
    required this.departmentName,
    required this.targetGoalId,
    required this.targetRole,
    required this.requirements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepartmentTransferPlan.empty() {
    final now = DateTime.now();
    return DepartmentTransferPlan(
      departmentName: '',
      targetGoalId: null,
      targetRole: null,
      requirements: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  DepartmentTransferPlan copyWith({
    String? departmentName,
    String? targetGoalId,
    String? targetRole,
    List<DepartmentTransferRequirement>? requirements,
    DateTime? updatedAt,
    bool clearTargetGoalId = false,
    bool clearTargetRole = false,
  }) {
    return DepartmentTransferPlan(
      departmentName: departmentName ?? this.departmentName,
      targetGoalId: clearTargetGoalId
          ? null
          : (targetGoalId ?? this.targetGoalId),
      targetRole: clearTargetRole ? null : (targetRole ?? this.targetRole),
      requirements: requirements ?? this.requirements,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'departmentName': departmentName,
    'targetGoalId': targetGoalId,
    'targetRole': targetRole,
    'requirements': requirements.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DepartmentTransferPlan.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, DateTime fallback) =>
        value is String ? (DateTime.tryParse(value) ?? fallback) : fallback;
    final now = DateTime.now();
    final created = parseDate(json['createdAt'], now);
    return DepartmentTransferPlan(
      departmentName: (json['departmentName'] as String?) ?? '',
      targetGoalId: json['targetGoalId'] as String?,
      targetRole: json['targetRole'] as String?,
      requirements:
          (json['requirements'] as List?)
              ?.whereType<Map>()
              .map(
                (e) => DepartmentTransferRequirement.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          const [],
      createdAt: created,
      updatedAt: parseDate(json['updatedAt'], created),
    );
  }
}

class TransferRequirementEvaluation {
  final DepartmentTransferRequirement requirement;
  final bool satisfied;
  final String reason;
  final int matchingRecords;

  const TransferRequirementEvaluation({
    required this.requirement,
    required this.satisfied,
    required this.reason,
    required this.matchingRecords,
  });
}

class DepartmentTransferEvaluation {
  final DepartmentTransferPlan plan;
  final List<TransferRequirementEvaluation> items;

  const DepartmentTransferEvaluation({required this.plan, required this.items});

  int get satisfiedCount => items.where((e) => e.satisfied).length;
  int get totalCount => items.length;
  double get percent => totalCount == 0 ? 0 : satisfiedCount / totalCount;
  List<TransferRequirementEvaluation> get gaps =>
      items.where((e) => !e.satisfied).toList();
}
