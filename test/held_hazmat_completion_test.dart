import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('held HazMat certs satisfy Task Book and cannot be Next Best Step', () async {
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

    Certification held(String id, String name) => Certification(
          id: id,
          name: name,
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
      certifications: [
        held('ff1-held', 'Firefighter I'),
        held('haz-awareness-held', 'HazMat Awareness'),
        held('haz-ops-held', 'HazMat Operations'),
      ],
    );

    final roadmap = app.roadmap;
    expect(roadmap, isNotNull);

    bool completed(String definitionId) => roadmap!.all.any(
          (item) =>
              item.requirement.certificationDefinitionId == definitionId &&
              item.isComplete,
        );

    expect(completed('firefighter_1'), isTrue);
    expect(completed('hazmat_awareness'), isTrue);
    expect(completed('hazmat_operations'), isTrue);

    final nextId = roadmap!.nextStep?.requirement.certificationDefinitionId;
    expect(nextId, isNot('firefighter_1'));
    expect(nextId, isNot('hazmat_awareness'));
    expect(nextId, isNot('hazmat_operations'));
  });
}
