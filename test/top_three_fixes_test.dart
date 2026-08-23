import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  UserProfile profile() {
    final now = DateTime(2026, 8, 12);
    return UserProfile(
      currentRoles: const ['Firefighter'],
      primaryGoalId: null,
      targetDate: null,
      careerPlan: CareerPlan.empty(),
      yearsOfService: 4,
      serviceType: 'Career',
      departmentName: 'Test Department',
      state: 'CO',
      createdAt: now,
      updatedAt: now,
    );
  }

  Certification cert() {
    final now = DateTime(2026, 8, 12);
    return Certification(
      id: 'ff1',
      name: 'Firefighter I',
      certificationDefinitionId: 'firefighter_1',
      issuingOrganization: 'Test',
      certificationNumber: null,
      issueDate: now,
      expirationDate: null,
      doesNotExpire: true,
      notes: null,
      renewalHistory: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  test(
      'custom goal starts with actionable milestones instead of an empty completed roadmap',
      () async {
    final state = AppState();
    await state.bootstrap();
    await state
        .completeOnboarding(profile: profile(), certifications: [cert()]);
    await state.setPrimaryGoal('custom:Training Captain');

    expect(state.roadmap, isNotNull);
    expect(state.roadmap!.totalCount, greaterThanOrEqualTo(4));
    expect(state.roadmap!.completedCount, 0);
    expect(state.roadmap!.nextStep, isNotNull);
    expect(state.roadmap!.nextStep!.requirement.name,
        'Define eligibility requirements');
  });

  test(
      'portfolio backup includes roadmap certifications preferences task book state and career records envelope',
      () async {
    final state = AppState();
    await state.bootstrap();
    await state
        .completeOnboarding(profile: profile(), certifications: [cert()]);
    await state.setPrimaryGoal('custom:Training Captain');

    final raw = await CareerRecordStore().exportBackup();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    expect(decoded['format'], 'fireops-career-portfolio');
    expect(decoded['version'], 5);
    expect(decoded['profile'], isA<Map>());
    expect((decoded['certifications'] as List), isNotEmpty);
    expect((decoded['customRequirements'] as List).length,
        greaterThanOrEqualTo(4));
    expect(decoded.containsKey('pathOverrides'), isTrue);
    expect(decoded.containsKey('quickLogPreferences'), isTrue);
    expect(decoded.containsKey('taskBookTaskProgress'), isTrue);
    expect(decoded.containsKey('taskBookCustomTasks'), isTrue);
    expect(decoded.containsKey('taskBookCustomBooks'), isTrue);
    expect(decoded.containsKey('taskBookActiveBook'), isTrue);
    expect(decoded.containsKey('records'), isTrue);
  });
}
