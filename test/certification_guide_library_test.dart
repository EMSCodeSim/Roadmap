import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/certification_guide_library.dart';
import 'package:firepath/services/task_book_library.dart';

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

  test('Firefighter II walks the user through planning and testing logistics', () {
    final ids = CertificationGuideLibrary.firefighterII.tasks
        .map((task) => task.id)
        .toSet();

    expect(ids, contains('ff2_confirm_required_jprs'));
    expect(ids, contains('ff2_confirm_required_reading'));
    expect(ids, contains('ff2_build_mastery_checklist'));
    expect(ids, contains('ff2_build_reading_checklist'));
    expect(ids, contains('ff2_find_test_location'));
    expect(ids, contains('ff2_confirm_test_dates_fees'));
    expect(ids, contains('ff2_register_written'));
    expect(ids, contains('ff2_register_practical'));
  });

  test('guide explicitly distinguishes preparation from official JPR criteria', () {
    final note = CertificationGuideLibrary.firefighterII.officialSourceNote;
    expect(note.toLowerCase(), contains('not copied official jpr'));
    expect(note.toLowerCase(), contains('current skill sheets'));
  });

  test('certification task books include explicit pass gates', () {
    final gates = TaskBookLibrary.certificationCompletionGates(
      firefighterIIRequirement(),
    );

    expect(gates.map((task) => task.title), contains('Pass JPR / practical evaluation'));
    expect(gates.map((task) => task.title), contains('Pass written test'));
    expect(gates.every((task) => task.section == 'TESTING'), isTrue);
  });

  test('non-certification requirements do not get certification pass gates', () {
    final requirement = firefighterIIRequirement().copyWith(
      type: RequirementType.trainingCourse,
    );

    expect(
      TaskBookLibrary.certificationCompletionGates(requirement),
      isEmpty,
    );
  });
}
