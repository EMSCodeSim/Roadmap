import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/task_book/requirement_checklist_page.dart';
import 'package:firepath/pages/task_book/task_book_page.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/national_task_book_baseline.dart';
import 'package:firepath/services/task_book_navigation.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('every built-in certification requirement opens the skills checklist', () {
    var certificationCount = 0;
    for (final goal in FireOpsCatalog.goals()) {
      for (final requirement in goal.requirements) {
        if (requirement.type != RequirementType.certification) continue;
        certificationCount++;
        expect(
          TaskBookNavigation.targetFor(requirement),
          TaskBookOpenTarget.skillsChecklist,
          reason: '${goal.title} / ${requirement.name}',
        );
        expect(
          NationalTaskBookBaseline.standardFor(requirement),
          isNotNull,
          reason: '${requirement.name} is missing a JPR baseline',
        );
      }
    }
    expect(certificationCount, greaterThanOrEqualTo(8));
  });

  test('training courses stay on requirement detail instead of a JPR list', () {
    final course = FireOpsCatalog.goals()
        .expand((goal) => goal.requirements)
        .firstWhere((requirement) => requirement.id == 'ics300');

    expect(course.type, RequirementType.trainingCourse);
    expect(
      TaskBookNavigation.targetFor(course),
      TaskBookOpenTarget.requirementDetail,
    );

    final driverPolicy = FireOpsCatalog.goals()
        .expand((goal) => goal.requirements)
        .firstWhere((requirement) => requirement.id == 'state_driver_policy');
    expect(
      TaskBookNavigation.targetFor(driverPolicy),
      TaskBookOpenTarget.requirementDetail,
      reason: 'Driver/operator policy course must not open the pumper prep book',
    );
  });

  test('Driver/Operator keeps preparation tasks as a secondary layer', () {
    final pumper = FireOpsCatalog.goals()
        .expand((goal) => goal.requirements)
        .firstWhere(
          (requirement) =>
              requirement.certificationDefinitionId == 'driver_operator_pumper',
        );

    expect(
      TaskBookNavigation.targetFor(pumper),
      TaskBookOpenTarget.skillsChecklist,
    );
    expect(TaskBookNavigation.hasPreparationTasks(pumper), isTrue);
  });

  testWidgets('Firefighter I checklist shows national JPR sections', (tester) async {
    final app = AppState();
    await app.bootstrap();
    await app.completeOnboarding(
      profile: _profile(goalId: 'ops_firefighter'),
      certifications: const [],
    );

    final requirement = app.roadmap!.all
        .map((item) => item.requirement)
        .firstWhere((item) => item.certificationDefinitionId == 'firefighter_1');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: RequirementChecklistPage(
            goalId: app.roadmap!.goal.id,
            requirement: requirement,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Skills Checklist'), findsOneWidget);
    expect(find.text('Firefighter I'), findsWidgets);
    expect(find.text('Fireground operations'), findsOneWidget);

    await tester.tap(find.text('Fireground operations'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Deploy and operate attack hose lines'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('checklist-open-preparation-tasks')), findsNothing);
  });

  testWidgets('Pumper checklist offers preparation tasks as a secondary action',
      (tester) async {
    final app = AppState();
    await app.bootstrap();
    await app.completeOnboarding(
      profile: _profile(goalId: 'ops_engineer'),
      certifications: const [],
    );

    final requirement = app.roadmap!.all
        .map((item) => item.requirement)
        .firstWhere(
          (item) => item.certificationDefinitionId == 'driver_operator_pumper',
        );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: RequirementChecklistPage(
            goalId: app.roadmap!.goal.id,
            requirement: requirement,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pump engagement and discharge operations'), findsOneWidget);
    expect(find.byKey(const Key('checklist-open-preparation-tasks')), findsOneWidget);
  });

  testWidgets('Task Book tap on Firefighter I opens the skills checklist',
      (tester) async {
    final app = AppState();
    await app.bootstrap();
    await app.completeOnboarding(
      profile: _profile(goalId: 'ops_firefighter'),
      certifications: const [],
    );

    final router = GoRouter(
      initialLocation: AppRoutes.myPath,
      routes: [
        GoRoute(
          path: AppRoutes.myPath,
          builder: (context, state) => const TaskBookPage(),
        ),
        GoRoute(
          path: AppRoutes.requirementChecklist,
          builder: (context, state) {
            final args = TaskBookRouteArgs.fromExtra(state.extra);
            return RequirementChecklistPage(
              goalId: args.goalId ?? app.roadmap!.goal.id,
              requirement: args.requirement!,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.requirementDetail,
          builder: (context, state) => const Scaffold(
            body: Text('requirement-detail'),
          ),
        ),
        GoRoute(
          path: AppRoutes.qualificationTaskBook,
          builder: (context, state) => const Scaffold(
            body: Text('qualification-prep'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open task'), findsOneWidget);
    await tester.tap(find.text('Open task'));
    await tester.pumpAndSettle();

    expect(find.text('Skills Checklist'), findsOneWidget);
    expect(find.text('Fireground operations'), findsOneWidget);
    expect(find.text('requirement-detail'), findsNothing);
  });
}

UserProfile _profile({required String goalId}) {
  final now = DateTime(2026, 8, 27);
  return UserProfile(
    currentRoles: const ['Firefighter'],
    primaryGoalId: goalId,
    targetDate: null,
    careerPlan: CareerPlan.empty().copyWith(goalId: goalId),
    yearsOfService: 2,
    serviceType: 'Career',
    departmentName: 'Test Department',
    state: 'CO',
    createdAt: now,
    updatedAt: now,
  );
}
