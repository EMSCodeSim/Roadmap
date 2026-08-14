import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/readiness_action_plan.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppState> booted() async {
    final s = AppState();
    await s.bootstrap();
    return s;
  }

  Certification cert(String name) {
    final now = DateTime(2026, 1, 1);
    return Certification(
      id: 'c_${name}_${now.microsecondsSinceEpoch}',
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

  test('action plan follows roadmap major-gap order', () async {
    final s = await booted();
    await s.completeOnboarding(
      profile: volunteerProfile(),
      certifications: [
        cert('FF I'),
        cert('FF II'),
        cert('HazMat Ops'),
        cert('EMT'),
      ],
    );
    await s.setPrimaryGoal('ops_engineer');

    final plan = CareerReadinessActionPlan.fromState(s);
    expect(plan.items, isNotEmpty);
    expect(plan.primary?.requirement.id, s.roadmap?.nextStep?.requirement.id);
  });

  test('numeric experience gaps use log progress CTA', () async {
    final s = await booted();
    await s.completeOnboarding(
      profile: volunteerProfile(),
      certifications: [
        cert('FF I'),
        cert('FF II'),
        cert('HazMat Ops'),
        cert('EMT'),
        cert('Driver Operator – Pumper'),
        cert('Driver Operator – Aerial'),
        cert('ICS-200'),
      ],
    );
    await s.setPrimaryGoal('ops_engineer');

    final plan = CareerReadinessActionPlan.fromState(s, maxItems: 20);
    final progressItems = plan.items.where(
      (e) => e.actionKind == ReadinessActionKind.logProgress,
    );
    expect(progressItems.isNotEmpty, isTrue);
  });

  test('scheduled gap uses view training CTA', () async {
    final s = await booted();
    await s.completeOnboarding(
      profile: volunteerProfile(),
      certifications: [cert('FF I'), cert('FF II')],
    );
    await s.setPrimaryGoal('ops_engineer');

    final next = s.roadmap!.nextStep!.requirement;
    await s.setRequirementActivityStatus(
      goalId: s.roadmap!.goal.id,
      requirementId: next.id,
      status: RequirementActivityStatus.scheduled,
    );

    final plan = CareerReadinessActionPlan.fromState(s);
    expect(plan.primary, isNotNull);
    expect(plan.primary!.actionKind, ReadinessActionKind.viewTraining);
    expect(plan.primary!.actionLabel, 'VIEW TRAINING');
  });

  test('in-progress gap uses continue CTA', () async {
    final s = await booted();
    await s.completeOnboarding(
      profile: volunteerProfile(),
      certifications: [cert('FF I'), cert('FF II')],
    );
    await s.setPrimaryGoal('ops_engineer');

    final next = s.roadmap!.nextStep!.requirement;
    await s.setRequirementActivityStatus(
      goalId: s.roadmap!.goal.id,
      requirementId: next.id,
      status: RequirementActivityStatus.inProgress,
    );

    final plan = CareerReadinessActionPlan.fromState(s);
    expect(plan.primary, isNotNull);
    expect(plan.primary!.actionKind, ReadinessActionKind.continueWork);
    expect(plan.primary!.actionLabel, 'CONTINUE');
  });
}
