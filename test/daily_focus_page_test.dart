import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/pages/career/daily_focus_page.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Certification cert(String name) {
    final now = DateTime(2026, 1, 1);
    return Certification(
      id: 'c_$name',
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

  testWidgets('daily focus shows time modes and next-step framing', (tester) async {
    final app = AppState();
    await app.bootstrap();
    await app.completeOnboarding(
      profile: volunteerProfile(),
      certifications: [cert('FF I')],
    );
    await app.setPrimaryGoal('ops_engineer');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: DailyFocusPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('1 hour'), findsOneWidget);
    expect(find.text('Crew drill'), findsOneWidget);
    expect(find.textContaining('Record'), findsWidgets);
  });
}
