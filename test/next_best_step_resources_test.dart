import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/home/visual_home_page.dart';
import 'package:firepath/pages/requirement/get_started_page.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Next Best Step opens resources for the recommended requirement',
      (tester) async {
    final now = DateTime(2026, 1, 1);
    final app = AppState();
    await tester.runAsync(() async {
      await app.bootstrap();
      await app.completeOnboarding(
        profile: UserProfile(
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
        ),
        certifications: [
          Certification(
            id: 'ff1',
            name: 'Firefighter I',
            certificationDefinitionId: 'ff1',
            issuingOrganization: null,
            certificationNumber: null,
            issueDate: now,
            expirationDate: null,
            doesNotExpire: true,
            notes: null,
            renewalHistory: const [],
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      await app.setPrimaryGoal('ops_engineer');
    });

    final nextRequirement = app.roadmap!.nextStep!.requirement;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const VisualHomePage(),
        ),
        GoRoute(
          path: AppRoutes.getStarted,
          builder: (_, state) => GetStartedPage(requirement: state.extra),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppModeController>(
            create: (_) => AppModeController(),
          ),
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<DepartmentInboxController>(
            create: (_) => DepartmentInboxController(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(nextRequirement.name));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text(nextRequirement.name), findsOneWidget);
    expect(find.text('Official requirements'), findsOneWidget);
    expect(find.text('Find training'), findsOneWidget);
  });
}
