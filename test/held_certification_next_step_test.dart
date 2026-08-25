import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Certification cert(String name) {
    final now = DateTime(2026, 8, 25);
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

  UserProfile profile() {
    final now = DateTime(2026, 8, 25);
    return UserProfile(
      currentRoles: const ['Firefighter'],
      primaryGoalId: null,
      targetDate: null,
      careerPlan: CareerPlan.empty(),
      yearsOfService: 3,
      serviceType: 'Career',
      departmentName: null,
      state: 'CO',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('Fire 1 shorthand is recognized as an already-held Firefighter I credential', () async {
    final state = AppState();
    await state.bootstrap();
    await state.completeOnboarding(
      profile: profile(),
      certifications: [cert('Fire 1')],
    );
    await state.setPrimaryGoal('ops_firefighter');

    final roadmap = state.roadmap!;
    final ff1 = roadmap.all.firstWhere(
      (item) => item.requirement.certificationDefinitionId == 'firefighter_1',
    );

    expect(ff1.isComplete, isTrue);
    expect(
      roadmap.nextStep?.requirement.certificationDefinitionId,
      isNot('firefighter_1'),
      reason: 'Next Best Step must never recommend a certification the user already has.',
    );
  });

  test('upserting a known held certification also resolves its stable ID', () async {
    final state = AppState();
    await state.bootstrap();
    await state.completeOnboarding(profile: profile(), certifications: const []);
    await state.setPrimaryGoal('ops_battalion_chief');

    await state.upsertCertification(cert('Officer 1'));

    final stored = state.certifications.single;
    expect(stored.certificationDefinitionId, 'fire_officer_1');

    final matching = state.roadmap!.all.where(
      (item) => item.requirement.certificationDefinitionId == 'fire_officer_1',
    );
    expect(matching, isNotEmpty);
    expect(matching.every((item) => item.isComplete), isTrue);
  });
}
