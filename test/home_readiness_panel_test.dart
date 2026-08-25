import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/pages/home/visual_home_page.dart';
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

  testWidgets('home keeps Quick Log immediately accessible with an active goal', (tester) async {
    final app = AppState();
    await app.bootstrap();
    await app.completeOnboarding(
      profile: volunteerProfile(),
      certifications: [cert('FF I'), cert('FF II')],
    );
    await app.setPrimaryGoal('ops_engineer');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: VisualHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Log'), findsOneWidget);

    final quickLogTop = tester.getTopLeft(find.text('Quick Log')).dy;
    expect(
      quickLogTop,
      lessThan(180),
      reason: 'Quick Log should be reachable from Home without scrolling.',
    );

    expect(find.textContaining('Driver/Operator'), findsWidgets);
    expect(find.text('CAREER READINESS'), findsOneWidget);
    expect(find.text('MAJOR GAPS'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text("Start Today's Focus"),
      300,
      scrollable: scrollable,
    );
    expect(find.text("Start Today's Focus"), findsOneWidget);
  });

  testWidgets('home prompts for a Task Book when no goal is set', (tester) async {
    final app = AppState();
    await app.bootstrap();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: VisualHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Log'), findsOneWidget);
    expect(find.text('Build My Task Book'), findsOneWidget);
    expect(find.text('CAREER READINESS'), findsNothing);
  });
}
