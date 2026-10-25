class CertificationRemovalAuditEntry {
  final String id;
  final String certificationId;
  final String certificationName;
  final String affectedMemberLabel;
  final String removedBy;
  final DateTime removedAt;
  final String? note;

  const CertificationRemovalAuditEntry({
    required this.id,
    required this.certificationId,
    required this.certificationName,
    required this.affectedMemberLabel,
    required this.removedBy,
    required this.removedAt,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'certificationId': certificationId,
        'certificationName': certificationName,
        'affectedMemberLabel': affectedMemberLabel,
        'removedBy': removedBy,
        'removedAt': removedAt.toIso8601String(),
        'note': note,
      };

  factory CertificationRemovalAuditEntry.fromJson(Map<String, dynamic> json) {
    DateTime? dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
    final removedAt = dt(json['removedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return CertificationRemovalAuditEntry(
      id: json['id'] as String? ?? '',
      certificationId: json['certificationId'] as String? ?? '',
      certificationName: json['certificationName'] as String? ?? '',
      affectedMemberLabel: json['affectedMemberLabel'] as String? ?? '',
      removedBy: json['removedBy'] as String? ?? '',
      removedAt: removedAt,
      note: json['note'] as String?,
    );
  }
}
