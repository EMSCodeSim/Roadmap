import 'package:firepath/models/certification.dart';

/// Builds the deliberately limited certification record sent to a department.
/// Credential numbers, notes, and renewal history remain personal.
Map<String, dynamic> departmentCertificationPayload(
  Certification certification,
) =>
    {
      'id': certification.id,
      'name': certification.name,
      'issuer': certification.issuingOrganization,
      'issueDate': certification.issueDate?.toIso8601String(),
      'expirationDate': certification.doesNotExpire
          ? null
          : certification.expirationDate?.toIso8601String(),
      'doesNotExpire': certification.doesNotExpire,
      'updatedAt': certification.updatedAt.toIso8601String(),
    };
