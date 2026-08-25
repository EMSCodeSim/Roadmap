import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/certification_guide_library.dart';

void main() {
  Requirement firefighterIIRequirement() => Requirement(
        id: 'req_ff2',
        name: 'Firefighter II',
        category: 'Certification',
        priority: RequirementPriority.core,
        description: 'Firefighter II certification',
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
        certificationReference: 'firefighter_2',
        certificationDefinitionId: 'firefighter_2',
        allowExpiredCertification: false,
        prerequisiteRequirementIds: const ['firefighter_1'],
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

  test('Firefighter II expands into a full certification pathway', () {
    final guide =
        CertificationGuideLibrary.guideForRequirement(firefighterIIRequirement());

    expect(guide, isNotNull);
    expect(guide!.pathwaySteps.length, greaterThanOrEqualTo(6));
    expect(guide.tasks.length, greaterThanOrEqualTo(15));

    final sections = guide.tasks.map((task) => task.section).toSet();
    expect(sections, contains('GETTING STARTED'));
    expect(sections, contains('TRAINING'));
    expect(sections, contains('PRACTICAL / JPR PREPARATION'));
    expect(sections, contains('TESTING'));
    expect(sections, contains('CERTIFICATION'));
  });

  test('Firefighter II includes key practical preparation areas', () {
    final guide = CertificationGuideLibrary.firefighterII;
    final ids = guide.tasks.map((task) => task.id).toSet();

    expect(ids, contains('ff2_command_communications'));
    expect(ids, contains('ff2_fire_attack_support'));
    expect(ids, contains('ff2_search_rescue'));
    expect(ids, contains('ff2_ventilation'));
    expect(ids, contains('ff2_vehicle_extrication'));
    expect(ids, contains('ff2_prevention_public_ed'));
    expect(ids, contains('ff2_preincident_planning'));
  });

  test('guide explicitly distinguishes preparation from official JPR criteria', () {
    final note = CertificationGuideLibrary.firefighterII.officialSourceNote;
    expect(note.toLowerCase(), contains('not copied official jpr'));
    expect(note.toLowerCase(), contains('current skill sheets'));
  });
}
