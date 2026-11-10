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

  Future<void> pumpHome(WidgetTester tester, AppState app) async {
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
  }

  testWidgets('home shows daily priorities when a personal goal exists',
      (tester) async {
    final app = AppState();
    await tester.runAsync(() async {
      await app.bootstrap();
      await app.completeOnboarding(
        profile: volunteerProfile(),
        certifications: [cert('FF I'), cert('FF II')],
      );
      await app.setPrimaryGoal('ops_engineer');
    });

    await pumpHome(tester, app);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Next action'), findsOneWidget);
    expect(find.text('Credentials'), findsOneWidget);
    expect(find.text('My Roadmap'), findsNothing);
    await tester.scrollUntilVisible(find.text('Open My Roadmap'), 300);
    expect(find.text('Open My Roadmap'), findsOneWidget);
  });

  testWidgets('home directs members without a goal to My Roadmap',
      (tester) async {
    final app = AppState();
    await tester.runAsync(app.bootstrap);

    await pumpHome(tester, app);

    expect(find.text('Choose a career goal'), findsOneWidget);
    expect(
      find.text('Set a goal in My Roadmap to get a recommended next step.'),
      findsOneWidget,
    );
    expect(find.text('Start my roadmap'), findsNothing);
    expect(find.text('My Goals'), findsNothing);
  });
}
