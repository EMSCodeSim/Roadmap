enum CertificationStatus { current, expiringSoon, expired }

/// User-held credential record (may be linked to a [CertificationDefinition]).
class Certification {
  final String id;
  /// User-entered display name (kept for backward compatibility and custom certs).
  final String name;
  /// Stable catalog ID when this cert is mapped to a known definition.
  final String? certificationDefinitionId;
  final String? issuingOrganization;
  final String? certificationNumber;
  final DateTime? issueDate;
  final DateTime? expirationDate;
  final bool doesNotExpire;
  final String? notes;
  /// Renewal history (most recent item should match the main fields).
  final List<CertificationRenewal> renewalHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Certification({
    required this.id,
    required this.name,
    this.certificationDefinitionId,
    required this.issuingOrganization,
    required this.certificationNumber,
    required this.issueDate,
    required this.expirationDate,
    required this.doesNotExpire,
    required this.notes,
    this.renewalHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Certification.empty({required String id}) {
    final now = DateTime.now();
    return Certification(
      id: id,
      name: '',
      certificationDefinitionId: null,
      issuingOrganization: null,
      certificationNumber: null,
      issueDate: null,
      expirationDate: null,
      doesNotExpire: false,
      notes: null,
      renewalHistory: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  Certification copyWith({
    String? name,
    String? certificationDefinitionId,
    String? issuingOrganization,
    String? certificationNumber,
    DateTime? issueDate,
    DateTime? expirationDate,
    bool? doesNotExpire,
    String? notes,
    List<CertificationRenewal>? renewalHistory,
    DateTime? updatedAt,
    bool clearExpirationDate = false,
    bool clearIssueDate = false,
  }) {
    return Certification(
      id: id,
      name: name ?? this.name,
      certificationDefinitionId: certificationDefinitionId ?? this.certificationDefinitionId,
      issuingOrganization: issuingOrganization ?? this.issuingOrganization,
      certificationNumber: certificationNumber ?? this.certificationNumber,
      issueDate: clearIssueDate ? null : (issueDate ?? this.issueDate),
      expirationDate: clearExpirationDate ? null : (expirationDate ?? this.expirationDate),
      doesNotExpire: doesNotExpire ?? this.doesNotExpire,
      notes: notes ?? this.notes,
      renewalHistory: renewalHistory ?? this.renewalHistory,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  CertificationStatus get status {
    if (doesNotExpire || expirationDate == null) return CertificationStatus.current;
    final now = DateTime.now();
    final days = expirationDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days < 0) return CertificationStatus.expired;
    if (days <= 90) return CertificationStatus.expiringSoon;
    return CertificationStatus.current;
  }

  int? get daysRemaining {
    if (doesNotExpire || expirationDate == null) return null;
    final now = DateTime.now();
    return expirationDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'certificationDefinitionId': certificationDefinitionId,
    'issuingOrganization': issuingOrganization,
    'certificationNumber': certificationNumber,
    'issueDate': issueDate?.toIso8601String(),
    'expirationDate': expirationDate?.toIso8601String(),
    'doesNotExpire': doesNotExpire,
    'notes': notes,
    'renewalHistory': renewalHistory.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Certification.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    final now = DateTime.now();
    final created = _dt(json['createdAt']) ?? now;
    final updated = _dt(json['updatedAt']) ?? created;
    final historyRaw = json['renewalHistory'];
    final history = historyRaw is List
        ? historyRaw.whereType<Map>().map((e) {
            try {
              return CertificationRenewal.fromJson(Map<String, dynamic>.from(e));
            } catch (_) {
              return null;
            }
          }).whereType<CertificationRenewal>().toList()
        : <CertificationRenewal>[];
    return Certification(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      certificationDefinitionId: json['certificationDefinitionId'] as String?,
      issuingOrganization: json['issuingOrganization'] as String?,
      certificationNumber: json['certificationNumber'] as String?,
      issueDate: _dt(json['issueDate']),
      expirationDate: _dt(json['expirationDate']),
      doesNotExpire: (json['doesNotExpire'] as bool?) ?? false,
      notes: json['notes'] as String?,
      renewalHistory: history,
      createdAt: created,
      updatedAt: updated,
    );
  }
}

class CertificationRenewal {
  final DateTime? issueDate;
  final DateTime? expirationDate;
  final bool doesNotExpire;
  final String? issuingOrganization;
  final String? certificationNumber;
  final String? notes;
  final DateTime createdAt;

  const CertificationRenewal({
    required this.issueDate,
    required this.expirationDate,
    required this.doesNotExpire,
    required this.issuingOrganization,
    required this.certificationNumber,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'issueDate': issueDate?.toIso8601String(),
    'expirationDate': expirationDate?.toIso8601String(),
    'doesNotExpire': doesNotExpire,
    'issuingOrganization': issuingOrganization,
    'certificationNumber': certificationNumber,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CertificationRenewal.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    final now = DateTime.now();
    return CertificationRenewal(
      issueDate: _dt(json['issueDate']),
      expirationDate: _dt(json['expirationDate']),
      doesNotExpire: (json['doesNotExpire'] as bool?) ?? false,
      issuingOrganization: json['issuingOrganization'] as String?,
      certificationNumber: json['certificationNumber'] as String?,
      notes: json['notes'] as String?,
      createdAt: _dt(json['createdAt']) ?? now,
    );
  }
}
