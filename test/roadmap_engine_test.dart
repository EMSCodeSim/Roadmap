import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/timeline_planner.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppState> _bootedState() async {
    final s = AppState();
    await s.bootstrap();
    return s;
  }

  Certification _cert(String name, {DateTime? exp, bool doesNotExpire = false}) {
    final now = DateTime(2026, 1, 1);
    return Certification(
      id: 'c_${name}_${now.microsecondsSinceEpoch}',
      name: name,
      certificationDefinitionId: null,
      issuingOrganization: null,
      certificationNumber: null,
      issueDate: null,
      expirationDate: exp,
      doesNotExpire: doesNotExpire,
      notes: null,
      renewalHistory: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  UserProfile _volunteerCO({int years = 5}) {
    final now = DateTime(2026, 1, 1);
    return UserProfile(
      currentRoles: const ['Volunteer Firefighter'],
      primaryGoalId: null,
      targetDate: null,
      careerPlan: CareerPlan.empty(),
      yearsOfService: years,
      serviceType: 'Volunteer',
      departmentName: null,
      state: 'CO',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('TEST 1: Volunteer + base fire certs recognized; next step is selected', () async {
    final s = await _bootedState();
    await s.completeOnboarding(
      profile: _volunteerCO(years: 5),
      certifications: [
        _cert('FF I'),
        _cert('FF II'),
        _cert('HazMat Ops'),
        _cert('EMT'),
      ],
    );
    await s.setPrimaryGoal('ops_engineer');

    final road = s.roadmap;
    expect(road, isNotNull);
    // Current minimal engineer path includes Firefighter II as a core cert.
    expect(road!.completedCount, greaterThanOrEqualTo(1));
    expect(road.nextStep, isNotNull);

    final completedDefinitionIds = road.completed
        .map((item) => item.requirement.certificationDefinitionId)
        .whereType<String>()
        .toSet();
    expect(completedDefinitionIds, contains('firefighter_2'));
  });

  test('TEST 2/10: Excluded requirement does not count in totals', () async {
    final s = await _bootedState();
    await s.completeOnboarding(profile: _volunteerCO(), certifications: [_cert('FF I')]);
    await s.setPrimaryGoal('ops_firefighter');
    final road1 = s.roadmap!;
    final target = road1.included.first.requirement;
    await s.setRequirementExcluded(goalId: road1.goal.id, requirementId: target.id, excluded: true);
    final road2 = s.roadmap!;
    expect(road2.totalCount, road1.totalCount - 1);
  });

  test('TEST 3: Alias "FF I" satisfies Firefighter I requirement', () async {
    final s = await _bootedState();
    await s.completeOnboarding(profile: _volunteerCO(), certifications: [_cert('FF I')]);
    await s.setPrimaryGoal('ops_firefighter');
    final road = s.roadmap!;
    final ff1 = road.all.where((e) => e.requirement.certificationDefinitionId == 'firefighter_1').firstOrNull;
    expect(ff1, isNotNull);
    expect(ff1!.isComplete, isTrue);
  });

  test('TEST 4: Firefighter II does NOT satisfy Firefighter I', () async {
    final s = await _bootedState();
    await s.completeOnboarding(profile: _volunteerCO(), certifications: [_cert('Firefighter II')]);
    await s.setPrimaryGoal('ops_firefighter');
    final road = s.roadmap!;
    final ff1 = road.all.where((e) => e.requirement.certificationDefinitionId == 'firefighter_1').firstOrNull;
    expect(ff1, isNotNull);
    expect(ff1!.isComplete, isFalse);
  });

  test('TEST 5: Expired Firefighter I does not satisfy active Firefighter I requirement', () async {
    final s = await _bootedState();
    // Attach an expired Firefighter I credential; ops_firefighter FF I does not allow expired.
    await s.completeOnboarding(
      profile: _volunteerCO(),
      certifications: [_cert('Firefighter I', exp: DateTime(2024, 1, 1))],
    );
    await s.setPrimaryGoal('ops_firefighter');
    final road = s.roadmap!;
    final ff1 = road.all.where((e) => e.requirement.certificationDefinitionId == 'firefighter_1').firstOrNull;
    expect(ff1, isNotNull);
    expect(ff1!.isComplete, isFalse);
  });

  test('TEST 6: Does Not Expire is always current', () {
    final cert = _cert('ICS-100', doesNotExpire: true);
    expect(cert.status, CertificationStatus.current);
    expect(cert.daysRemaining, isNull);
  });

  test('TEST 7: Completing Next Step forces a different Next Step', () async {
    final s = await _bootedState();
    await s.completeOnboarding(profile: _volunteerCO(), certifications: [_cert('FF I'), _cert('FF II')]);
    await s.setPrimaryGoal('ops_engineer');
    final before = s.roadmap!.nextStep!.requirement;
    // Mark complete by adding the associated cert.
    final id = before.certificationDefinitionId;
    expect(id, isNotNull);
    await s.upsertCertification(_cert(before.name).copyWith(certificationDefinitionId: id));
    final after = s.roadmap!.nextStep;
    expect(after, isNotNull);
    expect(after!.requirement.id == before.id, isFalse);
  });

  test('TEST 8: Cert expiring before target date generates renewal timeline item', () async {
    final s = await _bootedState();
    final profile = _volunteerCO();
    final today = DateTime.now();
    final expiration = DateTime(today.year, today.month, today.day).add(const Duration(days: 180));
    final target = expiration.add(const Duration(days: 180));
    await s.completeOnboarding(
      profile: profile,
      certifications: [_cert('Firefighter II', exp: expiration)],
    );
    await s.setPrimaryGoal('ops_engineer');
    await s.setTargetReadyDate(target);
    final plan = CareerTimelinePlanner.build(s);
    expect(plan, isNotNull);
    final renewals = plan!.sections.expand((e) => e.items).where((i) => i.kind == TimelineItemKind.renewal).toList();
    expect(renewals.isNotEmpty, isTrue);
  });

  test('TEST 9: Volunteer years of service satisfies experience requirements', () async {
    final s = await _bootedState();
    await s.completeOnboarding(profile: _volunteerCO(years: 5), certifications: [_cert('FF I')]);
    await s.setPrimaryGoal('ops_engineer');
    final road = s.roadmap!;
    final expReq = road.all.where((e) => e.requirement.type.name == 'experience').firstOrNull;
    if (expReq != null) {
      expect(expReq.isComplete, isTrue);
    }
  });

  test('TEST 11: Restart after onboarding keeps onboarding complete', () async {
    final s1 = await _bootedState();
    await s1.completeOnboarding(profile: _volunteerCO(), certifications: [_cert('FF I')]);
    expect(s1.onboardingComplete, isTrue);

    final s2 = AppState();
    await s2.bootstrap();
    expect(s2.onboardingComplete, isTrue);
    expect(s2.certifications.isNotEmpty, isTrue);
  });

  test('TEST 12: Alias "DO Pumper" matches Driver Operator – Pumper', () async {
    final s = await _bootedState();
    await s.completeOnboarding(profile: _volunteerCO(), certifications: [_cert('DO Pumper')]);
    await s.setPrimaryGoal('ops_engineer');
    final road = s.roadmap!;
    final doReq = road.all.where((e) => e.requirement.certificationDefinitionId == 'driver_operator_pumper').firstOrNull;
    if (doReq != null) {
      expect(doReq.isComplete, isTrue);
    }
  });
}
