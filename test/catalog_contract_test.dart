import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/services/catalog.dart';

/// Guardrail: when the career catalog is slimmed or expanded, these expectations
/// force an intentional test update instead of silent CI drift.
void main() {
  test('catalog exposes the current stable career goals', () {
    final goals = FireOpsCatalog.goals();
    final ids = goals.map((g) => g.id).toSet();

    expect(ids, containsAll(<String>['ops_firefighter', 'ops_engineer']));
    expect(ids.length, 2);
  });

  test('firefighter goal requires Firefighter I and HazMat baseline', () {
    final goal = FireOpsCatalog.goals().firstWhere((g) => g.id == 'ops_firefighter');
    final defIds = goal.requirements
        .map((r) => r.certificationDefinitionId)
        .whereType<String>()
        .toSet();
    final names = goal.requirements.map((r) => r.name).toSet();

    expect(defIds, contains('firefighter_1'));
    expect(names, contains('HazMat Awareness'));
    expect(names, contains('HazMat Operations'));
  });

  test('engineer goal requires Firefighter II and Driver/Operator – Pumper', () {
    final goal = FireOpsCatalog.goals().firstWhere((g) => g.id == 'ops_engineer');
    final defIds = goal.requirements
        .map((r) => r.certificationDefinitionId)
        .whereType<String>()
        .toSet();

    expect(defIds, containsAll(<String>['firefighter_2', 'driver_operator_pumper']));
    expect(
      goal.requirements.any((r) => r.id == 'state_driver_policy'),
      isTrue,
    );
  });

  test('common certification aliases resolve to stable definition ids', () {
    expect(FireOpsCatalog.matchCertificationDefinitionId('FF I'), 'firefighter_1');
    expect(FireOpsCatalog.matchCertificationDefinitionId('Firefighter II'), 'firefighter_2');
    expect(FireOpsCatalog.matchCertificationDefinitionId('DO Pumper'), 'driver_operator_pumper');
    expect(FireOpsCatalog.matchCertificationDefinitionId('EMT'), 'emt');
  });

  test('validateCatalog runs without throwing', () {
    expect(() => FireOpsCatalog.validateCatalog(), returnsNormally);
  });
}
