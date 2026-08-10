enum CertificationStatus { current, expiringSoon, expired }

class Certification {
  final String id;
  final String name;
  final String? issuingOrganization;
  final String? certificationNumber;
  final DateTime? issueDate;
  final DateTime? expirationDate;
  final bool doesNotExpire;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Certification({
    required this.id,
    required this.name,
    required this.issuingOrganization,
    required this.certificationNumber,
    required this.issueDate,
    required this.expirationDate,
    required this.doesNotExpire,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Certification.empty({required String id}) {
    final now = DateTime.now();
    return Certification(
      id: id,
      name: '',
      issuingOrganization: null,
      certificationNumber: null,
      issueDate: null,
      expirationDate: null,
      doesNotExpire: false,
      notes: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  Certification copyWith({
    String? name,
    String? issuingOrganization,
    String? certificationNumber,
    DateTime? issueDate,
    DateTime? expirationDate,
    bool? doesNotExpire,
    String? notes,
    DateTime? updatedAt,
    bool clearExpirationDate = false,
    bool clearIssueDate = false,
  }) {
    return Certification(
      id: id,
      name: name ?? this.name,
      issuingOrganization: issuingOrganization ?? this.issuingOrganization,
      certificationNumber: certificationNumber ?? this.certificationNumber,
      issueDate: clearIssueDate ? null : (issueDate ?? this.issueDate),
      expirationDate: clearExpirationDate ? null : (expirationDate ?? this.expirationDate),
      doesNotExpire: doesNotExpire ?? this.doesNotExpire,
      notes: notes ?? this.notes,
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
    'issuingOrganization': issuingOrganization,
    'certificationNumber': certificationNumber,
    'issueDate': issueDate?.toIso8601String(),
    'expirationDate': expirationDate?.toIso8601String(),
    'doesNotExpire': doesNotExpire,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Certification.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    final now = DateTime.now();
    final created = _dt(json['createdAt']) ?? now;
    final updated = _dt(json['updatedAt']) ?? created;
    return Certification(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      issuingOrganization: json['issuingOrganization'] as String?,
      certificationNumber: json['certificationNumber'] as String?,
      issueDate: _dt(json['issueDate']),
      expirationDate: _dt(json['expirationDate']),
      doesNotExpire: (json['doesNotExpire'] as bool?) ?? false,
      notes: json['notes'] as String?,
      createdAt: created,
      updatedAt: updated,
    );
  }
}
