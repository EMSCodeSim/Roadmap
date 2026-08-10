import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/readiness_snapshot.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Certification cert(String name) {
    final now = DateTime(2026, 1, 1);
    return Certification(
      id: 'cert_${name.replaceAll(' ', '_')}',
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

  UserProfile volunteerProfile() {
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

  test('snapshot mirrors roadmap totals and next step', () async {
    final state = AppState();
    await state.bootstrap();
    await state.completeOnboarding(
      profile: volunteerProfile(),
      certifications: [
        cert('FF I'),
        cert('FF II'),
        cert('HazMat Ops'),
        cert('EMT'),
      ],
    );
    await state.setPrimaryGoal('ops_engineer');

    final roadmap = state.roadmap!;
    final snapshot = CareerReadinessSnapshot.fromRoadmap(roadmap);

    expect(snapshot.completedCount, roadmap.completedCount);
    expect(snapshot.totalCount, roadmap.totalCount);
    expect(snapshot.percentComplete, roadmap.percentComplete);
    expect(snapshot.nextStep?.requirement.id, roadmap.nextStep?.requirement.id);
    expect(snapshot.remainingCount, roadmap.totalCount - roadmap.completedCount);
    expect(snapshot.majorGapCount, greaterThan(0));
  });

  test('excluded requirements never appear as readiness gaps', () async {
    final state = AppState();
    await state.bootstrap();
    await state.completeOnboarding(
      profile: volunteerProfile(),
      certifications: [cert('FF I')],
    );
    await state.setPrimaryGoal('ops_engineer');

    final before = state.roadmap!;
    final excluded = before.missing.last.requirement;
    await state.setRequirementExcluded(
      goalId: before.goal.id,
      requirementId: excluded.id,
      excluded: true,
    );

    final snapshot = CareerReadinessSnapshot.fromRoadmap(state.roadmap!);
    final allGapIds = <String>{
      ...snapshot.prerequisiteGaps.map((e) => e.requirement.id),
      ...snapshot.coreGaps.map((e) => e.requirement.id),
      ...snapshot.departmentGaps.map((e) => e.requirement.id),
      ...snapshot.experienceGaps.map((e) => e.requirement.id),
      ...snapshot.taskBookGaps.map((e) => e.requirement.id),
      ...snapshot.recommendedGaps.map((e) => e.requirement.id),
      ...snapshot.developmentGaps.map((e) => e.requirement.id),
    };

    expect(allGapIds.contains(excluded.id), isFalse);
  });
}
