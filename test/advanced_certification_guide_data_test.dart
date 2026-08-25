import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/advanced_certification_guide_data.dart';

Requirement requirement({
  required String id,
  required String name,
  required String certificationId,
}) =>
    Requirement(
      id: id,
      name: name,
      category: 'Certification',
      priority: RequirementPriority.core,
      description: '$name certification',
      type: RequirementType.certification,
      requirementSource: RequirementSource.commonlyRequired,
      defaultRequired: true,
      stateDependent: true,
      departmentDependent: false,
      completed: false,
      progressCurrent: null,
      progressRequired: null,
      progressUnit: null,
      experienceValue: null,
      experienceUnit: null,
      certificationReference: certificationId,
      certificationDefinitionId: certificationId,
      allowExpiredCertification: false,
      prerequisiteRequirementIds: const [],
      resourceIds: const [],
      resourceLinks: const [],
      sortOrder: 20,
      estimatedDurationDays: null,
      recommendedLeadTimeDays: null,
      canRunConcurrent: false,
      timelineCategory: TimelineCategory.certification,
      suggestedStartDate: null,
      suggestedCompletionDate: null,
      createdAt: DateTime(2026, 8, 25),
      updatedAt: DateTime(2026, 8, 25),
    );

void main() {
  test('Driver Operator Pumper has a complete certification pathway', () {
    final guide = AdvancedCertificationGuideData.forRequirement(
      requirement(
        id: 'req_do',
        name: 'Driver/Operator – Pumper',
        certificationId: 'driver_operator_pumper',
      ),
    );

    expect(guide, isNotNull);
    expect(guide!.pathwaySteps.length, greaterThanOrEqualTo(6));
    final sections = guide.tasks.map((task) => task.section).toSet();
    expect(sections, contains('GETTING STARTED'));
    expect(sections, contains('TRAINING'));
    expect(sections, contains('PRACTICAL / JPR PREPARATION'));
    expect(sections, contains('TESTING'));
    expect(sections, contains('CERTIFICATION'));

    final ids = guide.tasks.map((task) => task.id).toSet();
    expect(ids, contains('do_driving_competency'));
    expect(ids, contains('do_practical_prep'));
    expect(ids, contains('do_issue_credential'));
  });

  test('Fire Officer I expands into leadership and company officer preparation', () {
    final guide = AdvancedCertificationGuideData.forRequirement(
      requirement(
        id: 'req_fo1',
        name: 'Fire Officer I',
        certificationId: 'fire_officer_1',
      ),
    );

    expect(guide, isNotNull);
    expect(guide!.pathwaySteps.length, greaterThanOrEqualTo(6));
    expect(guide.tasks.length, greaterThanOrEqualTo(12));

    final sections = guide.tasks.map((task) => task.section).toSet();
    expect(sections, containsAll(<String>{
      'GETTING STARTED',
      'TRAINING',
      'PRACTICAL / JPR PREPARATION',
      'TESTING',
      'CERTIFICATION',
    }));

    final ids = guide.tasks.map((task) => task.id).toSet();
    expect(ids, contains('fo1_supervision'));
    expect(ids, contains('fo1_company_admin'));
    expect(ids, contains('fo1_training_delivery'));
    expect(ids, contains('fo1_incident_leadership'));
    expect(ids, contains('fo1_safety_risk'));
    expect(ids, contains('fo1_prevention_preplan'));
  });

  test('advanced guides defer official criteria to current authority materials', () {
    expect(
      AdvancedCertificationGuideData.driverOperatorPumper.officialSourceNote
          .toLowerCase(),
      contains('not official evaluator sheets'),
    );
    expect(
      AdvancedCertificationGuideData.fireOfficerI.officialSourceNote
          .toLowerCase(),
      contains('not copied official jpr'),
    );
  });
}
