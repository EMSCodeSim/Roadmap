import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/services/catalog.dart';

void main() {
  test('HazMat certifications have stable catalog ids', () {
    expect(
      FireOpsCatalog.matchCertificationDefinitionId('HazMat Awareness'),
      'hazmat_awareness',
    );
    expect(
      FireOpsCatalog.matchCertificationDefinitionId('HazMat Operations'),
      'hazmat_operations',
    );
    expect(
      FireOpsCatalog.matchCertificationDefinitionId('HazMat Ops'),
      'hazmat_operations',
    );
  });
}
