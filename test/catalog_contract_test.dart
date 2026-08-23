import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/services/catalog.dart';

/// Guardrail: when the career catalog is slimmed or expanded, these expectations
/// force an intentional test update instead of silent CI drift.
void main() {
  test('catalog exposes the full operations career ladder', () {
    final goals = FireOpsCatalog.goals();
    final ids = goals.map((g) => g.id).toList();

    expect(
      ids,
      containsAll(<String>[
        'ops_firefighter',
        'ops_engineer',
        'ops_company_officer',
        'ops_battalion_chief',
        'ops_division_chief',
        'ops_deputy_chief',
        'ops_fire_chief',
      ]),
    );
    expect(ids.length, 7);
  });

  test('commonRoles include company through chief titles', () {
    expect(
      FireOpsCatalog.commonRoles,
      containsAll(<String>[
        'Lieutenant',
        'Captain',
        'Battalion Chief',
        'Division Chief',
        'Assistant Chief',
        'Deputy Chief',
        'Fire Chief',
      ]),
    );
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

  test('company officer goal requires Fire Officer I and Fire Instructor I', () {
    final goal =
        FireOpsCatalog.goals().firstWhere((g) => g.id == 'ops_company_officer');
    final defIds = goal.requirements
        .map((r) => r.certificationDefinitionId)
        .whereType<String>()
        .toSet();

    expect(defIds, containsAll(<String>['fire_officer_1', 'fire_instructor_1']));
  });

  test('chief pathway goals require progressive Fire Officer levels', () {
    String? requiredOfficer(String goalId) {
      final goal = FireOpsCatalog.goals().firstWhere((g) => g.id == goalId);
      return goal.requirements
          .map((r) => r.certificationDefinitionId)
          .whereType<String>()
          .where((id) => id.startsWith('fire_officer_'))
          .firstOrNull;
    }

    expect(requiredOfficer('ops_battalion_chief'), 'fire_officer_2');
    expect(requiredOfficer('ops_division_chief'), 'fire_officer_3');
    expect(requiredOfficer('ops_deputy_chief'), 'fire_officer_4');
    expect(requiredOfficer('ops_fire_chief'), 'fire_officer_4');
  });

  test('common certification aliases resolve to stable definition ids', () {
    expect(FireOpsCatalog.matchCertificationDefinitionId('FF I'), 'firefighter_1');
    expect(FireOpsCatalog.matchCertificationDefinitionId('Firefighter II'), 'firefighter_2');
    expect(FireOpsCatalog.matchCertificationDefinitionId('DO Pumper'), 'driver_operator_pumper');
    expect(FireOpsCatalog.matchCertificationDefinitionId('EMT'), 'emt');
    expect(FireOpsCatalog.matchCertificationDefinitionId('FO I'), 'fire_officer_1');
    expect(FireOpsCatalog.matchCertificationDefinitionId('Fire Officer II'), 'fire_officer_2');
    expect(FireOpsCatalog.matchCertificationDefinitionId('NFPA 1021 Fire Officer III'), 'fire_officer_3');
    expect(FireOpsCatalog.matchCertificationDefinitionId('Executive Fire Officer'), 'fire_officer_4');
    expect(FireOpsCatalog.matchCertificationDefinitionId('FI I'), 'fire_instructor_1');
    expect(FireOpsCatalog.matchCertificationDefinitionId('NFPA 1041 Fire Instructor I'), 'fire_instructor_1');
  });

  test('validateCatalog runs without throwing', () {
    expect(() => FireOpsCatalog.validateCatalog(), returnsNormally);
  });
}
