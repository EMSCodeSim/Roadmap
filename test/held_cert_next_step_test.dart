import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Fire 1 shorthand is recognized as held Firefighter I', () async {
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

    final fireOne = Certification(
      id: 'held-fire-1',
      name: 'Fire 1',
      certificationDefinitionId: null,
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
      certifications: [fireOne],
    );

    final held = app.certifications.single;
    expect(held.certificationDefinitionId, 'firefighter_1');

    final firefighterOneRequirement = app.roadmap!.all.firstWhere(
      (item) => item.requirement.certificationDefinitionId == 'firefighter_1',
    );
    expect(firefighterOneRequirement.isComplete, isTrue);
    expect(
      app.roadmap!.nextStep?.requirement.certificationDefinitionId,
      isNot('firefighter_1'),
      reason: 'Next Best Step must never recommend a certification already held.',
    );
    expect(
      app.roadmap!.nextStep?.requirement.certificationDefinitionId,
      isNot('fire_officer_2'),
      reason: 'Battalion Chief planning must preserve the intermediate career ladder.',
    );
  });

  test('cert added after onboarding is normalized before Next Best Step', () async {
    final now = DateTime(2026, 8, 25);
    final app = AppState();
    await app.bootstrap();

    final profile = UserProfile(
      currentRoles: const ['Firefighter'],
      primaryGoalId: 'ops_engineer',
      targetDate: null,
      careerPlan: CareerPlan.empty().copyWith(goalId: 'ops_engineer'),
      yearsOfService: 4,
      serviceType: 'Career',
      departmentName: null,
      state: 'CO',
      createdAt: now,
      updatedAt: now,
    );

    await app.completeOnboarding(profile: profile, certifications: const []);

    await app.upsertCertification(
      Certification(
        id: 'held-ff2',
        name: 'Firefighter II',
        certificationDefinitionId: null,
        issuingOrganization: null,
        certificationNumber: null,
        issueDate: null,
        expirationDate: null,
        doesNotExpire: true,
        notes: null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(
      app.getCertificationById('held-ff2')!.certificationDefinitionId,
      'firefighter_2',
    );
    expect(
      app.roadmap!.nextStep?.requirement.certificationDefinitionId,
      isNot('firefighter_2'),
      reason: 'A newly added held cert must be removed from Next Best Step immediately.',
    );
  });
}
