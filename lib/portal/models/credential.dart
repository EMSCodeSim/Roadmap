import 'package:flutter/foundation.dart';

enum CredentialVerificationStatus { unverified, verified, rejected }

extension CredentialVerificationStatusLabel on CredentialVerificationStatus {
  String get label => switch (this) {
        CredentialVerificationStatus.unverified => 'Unverified',
        CredentialVerificationStatus.verified => 'Verified',
        CredentialVerificationStatus.rejected => 'Rejected',
      };
}

@immutable
class Credential {
  final String id;
  final String departmentId;
  final String memberId;
  final String credentialType;
  final String credentialName;
  final String issuer;
  final String? credentialNumber;
  final DateTime? issueDate;
  final DateTime? expirationDate;
  final CredentialVerificationStatus verificationStatus;
  final String? attachmentUrl;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Credential({
    required this.id,
    required this.departmentId,
    required this.memberId,
    required this.credentialType,
    required this.credentialName,
    required this.issuer,
    required this.credentialNumber,
    required this.issueDate,
    required this.expirationDate,
    required this.verificationStatus,
    required this.attachmentUrl,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Credential.fromJson(Map<String, dynamic> json) {
    DateTime? dtOpt(String key) => (json[key] == null) ? null : DateTime.tryParse(json[key]);
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    CredentialVerificationStatus vsFrom(String? v) => CredentialVerificationStatus.values.firstWhere(
          (e) => e.name == v,
          orElse: () => CredentialVerificationStatus.unverified,
        );

    return Credential(
      id: (json['id'] ?? '').toString(),
      departmentId: (json['departmentId'] ?? '').toString(),
      memberId: (json['memberId'] ?? '').toString(),
      credentialType: (json['credentialType'] ?? '').toString(),
      credentialName: (json['credentialName'] ?? '').toString(),
      issuer: (json['issuer'] ?? '').toString(),
      credentialNumber: json['credentialNumber'] as String?,
      issueDate: dtOpt('issueDate'),
      expirationDate: dtOpt('expirationDate'),
      verificationStatus: vsFrom(json['verificationStatus'] as String?),
      attachmentUrl: json['attachmentUrl'] as String?,
      notes: (json['notes'] ?? '').toString(),
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'departmentId': departmentId,
        'memberId': memberId,
        'credentialType': credentialType,
        'credentialName': credentialName,
        'issuer': issuer,
        'credentialNumber': credentialNumber,
        'issueDate': issueDate?.toIso8601String(),
        'expirationDate': expirationDate?.toIso8601String(),
        'verificationStatus': verificationStatus.name,
        'attachmentUrl': attachmentUrl,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
