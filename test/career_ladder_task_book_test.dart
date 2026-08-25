import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Battalion Chief goal includes the full career ladder before Fire Officer II', () async {
    final now = DateTime(2026, 8, 25);
    final app = AppState();
    await app.bootstrap();

    final profile = UserProfile(
      currentRoles: const ['Firefighter'],
      primaryGoalId: 'ops_battalion_chief',
      targetDate: null,
      careerPlan: CareerPlan.empty().copyWith(goalId: 'ops_battalion_chief'),
      yearsOfService: 3,
      serviceType: 'Career',
      departmentName: null,
      state: 'CO',
      createdAt: now,
      updatedAt: now,
    );

    final firefighterOne = Certification(
      id: 'ff1-held',
      name: 'Firefighter I',
      certificationDefinitionId: 'firefighter_1',
      issuingOrganization: null,
      certificationNumber: null,
      issueDate: null,
      expirationDate: null,
      doesNotExpire: true,
      notes: null,
      createdAt: now,
      updatedAt: now,
    );

    await app.completeOnboarding(
      profile: profile,
      certifications: [firefighterOne],
    );

    final roadmap = app.roadmap;
    expect(roadmap, isNotNull);
    expect(roadmap!.goal.id, 'ops_battalion_chief');

    final definitionIds = roadmap.all
        .map((item) => item.requirement.certificationDefinitionId)
        .whereType<String>()
        .toList();

    final ff2Index = definitionIds.indexOf('firefighter_2');
    final driverIndex = definitionIds.indexOf('driver_operator_pumper');
    final fo1Index = definitionIds.indexOf('fire_officer_1');
    final instructorIndex = definitionIds.indexOf('fire_instructor_1');
    final fo2Index = definitionIds.indexOf('fire_officer_2');

    expect(ff2Index, greaterThanOrEqualTo(0));
    expect(driverIndex, greaterThan(ff2Index));
    expect(fo1Index, greaterThan(driverIndex));
    expect(instructorIndex, greaterThan(fo1Index));
    expect(fo2Index, greaterThan(instructorIndex));

    expect(
      roadmap.nextStep?.requirement.certificationDefinitionId,
      isNot('fire_officer_2'),
      reason: 'A firefighter with only Firefighter I should not jump directly to Fire Officer II.',
    );
    expect(
      roadmap.comingUp
          .takeWhile((item) => item.requirement.certificationDefinitionId != 'fire_officer_2')
          .length,
      greaterThan(2),
      reason: 'Several prerequisite steps should appear before the Battalion Chief end-stage cert.',
    );
  });
}
