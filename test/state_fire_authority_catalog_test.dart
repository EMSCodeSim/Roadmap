import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/state_fire_authority_catalog.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('every selectable US state and DC has an official fire authority source', () {
    final expected = FireOpsCatalog.usStateOptions
        .where((s) => s.code != FireOpsCatalog.otherStateCode)
        .map((s) => s.code)
        .toSet();
    final actual = StateFireAuthorityCatalog.all.map((e) => e.stateCode).toSet();

    expect(actual.containsAll(expected), isTrue);
    expect(actual.length, expected.length);

    for (final code in expected) {
      final authority = StateFireAuthorityCatalog.forState(code);
      expect(authority, isNotNull, reason: 'Missing state authority for $code');
      expect(authority!.sourceTitle.trim(), isNotEmpty);
      expect(authority.sourceUrl.trim(), isNotEmpty);
      expect(authority.guidance.trim(), isNotEmpty);
    }
  });

  test('known statewide policy guidance remains state-specific', () {
    final co = StateFireAuthorityCatalog.forState('CO')!;
    final tx = StateFireAuthorityCatalog.forState('TX')!;
    final ky = StateFireAuthorityCatalog.forState('KY')!;
    final ny = StateFireAuthorityCatalog.forState('NY')!;

    expect(co.guidance.toLowerCase(), contains('voluntary'));
    expect(tx.sourceTitle, contains('Texas Commission on Fire Protection'));
    expect(tx.guidance.toLowerCase(), contains('requires'));
    expect(ky.guidance, contains('Basic 1'));
    expect(ky.guidance, contains('Basic 2'));
    expect(ny.guidance.toLowerCase(), contains('career firefighters'));
  });

  test('roadmap state-dependent items use the selected state authority', () async {
    final state = AppState();
    await state.bootstrap();

    UserProfile profileFor(String code) {
      final now = DateTime(2026, 8, 23);
      return UserProfile(
        currentRoles: const ['Firefighter'],
        primaryGoalId: null,
        targetDate: null,
        careerPlan: CareerPlan.empty(),
        yearsOfService: 3,
        serviceType: 'Career',
        departmentName: 'Test Department',
        state: code,
        createdAt: now,
        updatedAt: now,
      );
    }

    await state.completeOnboarding(
      profile: profileFor('CO'),
      certifications: const [],
    );
    await state.setPrimaryGoal('ops_engineer');

    final coStateDependent = state.roadmap!.all
        .map((e) => e.requirement)
        .where((r) => r.stateDependent)
        .toList();
    expect(coStateDependent, isNotEmpty);
    for (final r in coStateDependent) {
      expect(r.sourceStateCode, 'CO');
      expect(r.sourceTitle, contains('Colorado'));
      expect(r.sourceUrl, isNotNull);
    }

    await state.profileController.updateProfile(profileFor('TX').copyWith(
      primaryGoalId: 'ops_engineer',
      careerPlan: state.profile.careerPlan,
    ));

    final txStateDependent = state.roadmap!.all
        .map((e) => e.requirement)
        .where((r) => r.stateDependent)
        .toList();
    expect(txStateDependent, isNotEmpty);
    for (final r in txStateDependent) {
      expect(r.sourceStateCode, 'TX');
      expect(r.sourceTitle, contains('Texas'));
      expect(r.sourceTitle, isNot(contains('Colorado')));
    }
  });
}
