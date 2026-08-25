import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/firefighter1_certification_guide_data.dart';

void main() {
  Requirement firefighterIRequirement() => Requirement(
        id: 'req_ff1',
        name: 'Firefighter I',
        category: 'Certification',
        priority: RequirementPriority.core,
        description: 'Firefighter I certification',
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
        certificationReference: 'firefighter_1',
        certificationDefinitionId: 'firefighter_1',
        allowExpiredCertification: false,
        prerequisiteRequirementIds: const [],
        resourceIds: const [],
        resourceLinks: const [],
        sortOrder: 10,
        estimatedDurationDays: null,
        recommendedLeadTimeDays: null,
        canRunConcurrent: false,
        timelineCategory: TimelineCategory.certification,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        createdAt: DateTime(2026, 8, 25),
        updatedAt: DateTime(2026, 8, 25),
      );

  test('Firefighter I resolves to the detailed certification pathway', () {
    final guide = Firefighter1CertificationGuideData.forRequirement(
      firefighterIRequirement(),
    );

    expect(guide, isNotNull);
    expect(guide!.pathwaySteps.length, greaterThanOrEqualTo(7));
    expect(guide.tasks.length, greaterThanOrEqualTo(18));

    final sections = guide.tasks.map((task) => task.section).toSet();
    expect(sections, contains('GETTING STARTED'));
    expect(sections, contains('TRAINING'));
    expect(sections, contains('PRACTICAL / JPR PREPARATION'));
    expect(sections, contains('TESTING'));
    expect(sections, contains('CERTIFICATION'));
  });

  test('Firefighter I includes core practical preparation areas', () {
    final ids = Firefighter1CertificationGuideData.firefighterI.tasks
        .map((task) => task.id)
        .toSet();

    expect(ids, contains('ff1_ppe_scba'));
    expect(ids, contains('ff1_fire_behavior'));
    expect(ids, contains('ff1_hose_nozzle'));
    expect(ids, contains('ff1_ladders'));
    expect(ids, contains('ff1_forcible_entry'));
    expect(ids, contains('ff1_search_rescue'));
    expect(ids, contains('ff1_ventilation'));
    expect(ids, contains('ff1_water_supply'));
    expect(ids, contains('ff1_ropes_knots'));
    expect(ids, contains('ff1_live_fire'));
  });

  test('Firefighter I guide preserves official-source boundary', () {
    final note = Firefighter1CertificationGuideData.firefighterI.officialSourceNote.toLowerCase();
    expect(note, contains('not copied official jpr'));
    expect(note, contains('verify current'));
  });
}
