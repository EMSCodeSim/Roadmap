enum CareerRecordType {
  operationalExperience,
  skill,
  training,
  achievement,
  leadership,
  teaching,
  project,
  education,
  taskBookEvidence,
}

enum CareerRecordOutcome {
  successful,
  unsuccessful,
  attempted,
  completed,
}

extension CareerRecordOutcomeX on CareerRecordOutcome {
  String get label => switch (this) {
        CareerRecordOutcome.successful => 'Successful',
        CareerRecordOutcome.unsuccessful => 'Unsuccessful',
        CareerRecordOutcome.attempted => 'Attempted',
        CareerRecordOutcome.completed => 'Completed',
      };
}

extension CareerRecordTypeX on CareerRecordType {
  String get label => switch (this) {
        CareerRecordType.operationalExperience => 'Operational experience',
        CareerRecordType.skill => 'Skill',
        CareerRecordType.training => 'Training',
        CareerRecordType.achievement => 'Award / achievement',
        CareerRecordType.leadership => 'Leadership',
        CareerRecordType.teaching => 'Teaching / mentoring',
        CareerRecordType.project => 'Project / committee',
        CareerRecordType.education => 'Education',
        CareerRecordType.taskBookEvidence => 'Task book evidence',
      };

  String get shortLabel => switch (this) {
        CareerRecordType.operationalExperience => 'Calls',
        CareerRecordType.skill => 'Skills',
        CareerRecordType.training => 'Training',
        CareerRecordType.achievement => 'Wins',
        CareerRecordType.leadership => 'Leadership',
        CareerRecordType.teaching => 'Teaching',
        CareerRecordType.project => 'Projects',
        CareerRecordType.education => 'Education',
        CareerRecordType.taskBookEvidence => 'Task book',
      };
}

class CareerRecord {
  final String id;
  final CareerRecordType type;
  final String title;
  final String category;
  final DateTime date;
  final String? roleOrAssignment;
  final String? summary;
  final String? impact;
  final String? evidenceReference;
  final double? hours;
  final int repetitions;
  final List<String> tags;
  final String? relatedGoalId;
  final String? relatedRequirementId;
  final String? relatedTaskId;
  final bool highlight;
  final String? trackingKey;
  final CareerRecordOutcome? outcome;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CareerRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.date,
    required this.roleOrAssignment,
    required this.summary,
    required this.impact,
    required this.evidenceReference,
    required this.hours,
    required this.repetitions,
    required this.tags,
    required this.relatedGoalId,
    required this.relatedRequirementId,
    this.relatedTaskId,
    required this.highlight,
    this.trackingKey,
    this.outcome,
    required this.createdAt,
    required this.updatedAt,
  });

  CareerRecord copyWith({
    CareerRecordType? type,
    String? title,
    String? category,
    DateTime? date,
    String? roleOrAssignment,
    String? summary,
    String? impact,
    String? evidenceReference,
    double? hours,
    int? repetitions,
    List<String>? tags,
    String? relatedGoalId,
    String? relatedRequirementId,
    String? relatedTaskId,
    bool? highlight,
    String? trackingKey,
    CareerRecordOutcome? outcome,
    DateTime? updatedAt,
    bool clearRoleOrAssignment = false,
    bool clearSummary = false,
    bool clearImpact = false,
    bool clearEvidenceReference = false,
    bool clearHours = false,
    bool clearRelatedGoalId = false,
    bool clearRelatedRequirementId = false,
    bool clearRelatedTaskId = false,
    bool clearTrackingKey = false,
    bool clearOutcome = false,
  }) {
    return CareerRecord(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      roleOrAssignment: clearRoleOrAssignment ? null : (roleOrAssignment ?? this.roleOrAssignment),
      summary: clearSummary ? null : (summary ?? this.summary),
      impact: clearImpact ? null : (impact ?? this.impact),
      evidenceReference: clearEvidenceReference ? null : (evidenceReference ?? this.evidenceReference),
      hours: clearHours ? null : (hours ?? this.hours),
      repetitions: repetitions ?? this.repetitions,
      tags: tags ?? this.tags,
      relatedGoalId: clearRelatedGoalId ? null : (relatedGoalId ?? this.relatedGoalId),
      relatedRequirementId: clearRelatedRequirementId ? null : (relatedRequirementId ?? this.relatedRequirementId),
      relatedTaskId: clearRelatedTaskId ? null : (relatedTaskId ?? this.relatedTaskId),
      highlight: highlight ?? this.highlight,
      trackingKey: clearTrackingKey ? null : (trackingKey ?? this.trackingKey),
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'category': category,
        'date': date.toIso8601String(),
        'roleOrAssignment': roleOrAssignment,
        'summary': summary,
        'impact': impact,
        'evidenceReference': evidenceReference,
        'hours': hours,
        'repetitions': repetitions,
        'tags': tags,
        'relatedGoalId': relatedGoalId,
        'relatedRequirementId': relatedRequirementId,
        'relatedTaskId': relatedTaskId,
        'highlight': highlight,
        'trackingKey': trackingKey,
        'outcome': outcome?.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CareerRecord.fromJson(Map<String, dynamic> json) {
    CareerRecordType parseType(dynamic value) {
      if (value is String) {
        try {
          return CareerRecordType.values.byName(value);
        } catch (_) {}
      }
      return CareerRecordType.training;
    }

    CareerRecordOutcome? parseOutcome(dynamic value) {
      if (value is String) {
        try {
          return CareerRecordOutcome.values.byName(value);
        } catch (_) {}
      }
      return null;
    }

    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    final createdAt = parseDate(json['createdAt'], now);
    final tagsRaw = json['tags'];
    return CareerRecord(
      id: (json['id'] as String?) ?? '',
      type: parseType(json['type']),
      title: (json['title'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      date: parseDate(json['date'], createdAt),
      roleOrAssignment: json['roleOrAssignment'] as String?,
      summary: json['summary'] as String?,
      impact: json['impact'] as String?,
      evidenceReference: json['evidenceReference'] as String?,
      hours: (json['hours'] as num?)?.toDouble(),
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 1,
      tags: tagsRaw is List ? tagsRaw.whereType<String>().toList() : const <String>[],
      relatedGoalId: json['relatedGoalId'] as String?,
      relatedRequirementId: json['relatedRequirementId'] as String?,
      relatedTaskId: json['relatedTaskId'] as String?,
      highlight: (json['highlight'] as bool?) ?? false,
      trackingKey: json['trackingKey'] as String?,
      outcome: parseOutcome(json['outcome']),
      createdAt: createdAt,
      updatedAt: parseDate(json['updatedAt'], createdAt),
    );
  }
}
