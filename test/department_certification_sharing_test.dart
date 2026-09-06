import 'package:firepath/models/certification.dart';
import 'package:firepath/services/department_certification_sharing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('department payload includes expiration but excludes private details', () {
    final certification = Certification(
      id: 'cert-1',
      name: 'Firefighter I',
      issuingOrganization: 'State Fire Marshal',
      certificationNumber: 'PRIVATE-123',
      issueDate: DateTime.utc(2025, 1, 2),
      expirationDate: DateTime.utc(2028, 1, 2),
      doesNotExpire: false,
      notes: 'Private member note',
      createdAt: DateTime.utc(2025, 1, 2),
      updatedAt: DateTime.utc(2026, 9, 6),
    );

    final payload = departmentCertificationPayload(certification);

    expect(payload['expirationDate'], '2028-01-02T00:00:00.000Z');
    expect(payload['doesNotExpire'], isFalse);
    expect(payload['name'], 'Firefighter I');
    expect(payload.containsKey('certificationNumber'), isFalse);
    expect(payload.containsKey('notes'), isFalse);
    expect(payload.containsKey('renewalHistory'), isFalse);
  });

  test('does-not-expire state is shared without an expiration date', () {
    final certification = Certification(
      id: 'cert-2',
      name: 'Permanent Credential',
      issuingOrganization: null,
      certificationNumber: null,
      issueDate: null,
      expirationDate: DateTime.utc(2030, 1, 1),
      doesNotExpire: true,
      notes: null,
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2026),
    );

    final payload = departmentCertificationPayload(certification);

    expect(payload['expirationDate'], isNull);
    expect(payload['doesNotExpire'], isTrue);
  });
}
