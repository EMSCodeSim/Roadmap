import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/pages/home/visual_home_page.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';

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

  testWidgets('home keeps personal career goal visible and separates department progress', (tester) async {
    final app = AppState();
    await app.bootstrap();
    await app.completeOnboarding(
      profile: volunteerProfile(),
      certifications: [cert('FF I'), cert('FF II')],
    );
    await app.setPrimaryGoal('ops_engineer');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<DepartmentInboxController>(
            create: (_) => DepartmentInboxController(),
          ),
        ],
        child: const MaterialApp(home: VisualHomePage()),
      ),
    );
    // Bounded pumps: live progress indicators must not stall widget tests.
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Roadmap'), findsOneWidget);
    expect(find.text('MY GOAL · MY PROGRESS'), findsOneWidget);
    expect(find.text('Career goal'), findsOneWidget);
    expect(find.textContaining('Driver/Operator'), findsWidgets);
    expect(find.text('Personal overview'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Department overview'), findsOneWidget);
    expect(find.text('Open Department'), findsOneWidget);
  });

  testWidgets('home prompts to choose a roadmap when no goal is set', (tester) async {
    final app = AppState();
    await app.bootstrap();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<DepartmentInboxController>(
            create: (_) => DepartmentInboxController(),
          ),
        ],
        child: const MaterialApp(home: VisualHomePage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Roadmap'), findsOneWidget);
    expect(find.text('Choose a roadmap'), findsOneWidget);
    expect(find.text('Personal overview'), findsOneWidget);
  });
}
