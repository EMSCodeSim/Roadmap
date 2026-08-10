import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/readiness_snapshot.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Certification cert(String name) {
    final now = DateTime(2026, 1, 1);
    return Certification(
      id: 'cert_$name',
      name: name,
      certificationDefinitionId: null,
      issuingOrganization: null,
      certificationNumber: null,
      issueDate: null,
      expirationDate: null,
      doesNotExpire: true,
      notes: null,
      renewalHistory: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  UserProfile profile() {
    final now = DateTime(2026, 1, 1);
    return UserProfile(
      currentRoles: const ['Volunteer Firefighter'],
      primaryGoalId: null,
      targetDate: null,
      careerPlan: CareerPlan.empty(),
      yearsOfService: 5,
      serviceType: 'Volunteer',
      departmentName: null,
      state: 'CO',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('majorGaps is de-duplicated and agrees with majorGapCount', () async {
    final state = AppState();
    await state.bootstrap();
    await state.completeOnboarding(
      profile: profile(),
      certifications: [
        cert('FF I'),
        cert('FF II'),
        cert('HazMat Ops'),
        cert('EMT'),
      ],
    );
    await state.setPrimaryGoal('ops_engineer');

    final snapshot = CareerReadinessSnapshot.fromRoadmap(state.roadmap!);
    final ids = snapshot.majorGaps.map((e) => e.requirement.id).toList();

    expect(ids.toSet().length, ids.length);
    expect(snapshot.majorGapCount, snapshot.majorGaps.length);
    expect(snapshot.majorGaps.isNotEmpty, isTrue);
  });

  test('excluded requirements never appear in majorGaps', () async {
    final state = AppState();
    await state.bootstrap();
    await state.completeOnboarding(
      profile: profile(),
      certifications: [cert('FF I')],
    );
    await state.setPrimaryGoal('ops_engineer');

    final before = CareerReadinessSnapshot.fromRoadmap(state.roadmap!);
    final target = before.majorGaps.first.requirement;

    await state.setRequirementExcluded(
      goalId: state.roadmap!.goal.id,
      requirementId: target.id,
      excluded: true,
    );

    final after = CareerReadinessSnapshot.fromRoadmap(state.roadmap!);
    expect(
      after.majorGaps.any((e) => e.requirement.id == target.id),
      isFalse,
    );
  });
}
