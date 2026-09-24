import 'package:firepath/pages/onboarding/onboarding_v2_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome explains both personal and department workflows',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingV2Page()),
    );

    expect(find.text('Your career roadmap, organized.'), findsOneWidget);
    expect(find.text('Build your personal roadmap'), findsOneWidget);
    expect(find.text('Complete task books and assignments'), findsOneWidget);
    expect(find.text('Connect with your department'), findsOneWidget);
    expect(find.text('Set up my roadmap'), findsOneWidget);
    expect(find.textContaining('Connecting a department is optional'),
        findsOneWidget);
  });

  testWidgets('setup starts with career path then recruit shortcut',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingV2Page()),
    );

    await tester.tap(find.text('Set up my roadmap'));
    await tester.pumpAndSettle();

    expect(find.text('Career Path'), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('What career path are you building?'), findsOneWidget);
    expect(find.text('Fire'), findsWidgets);
    expect(find.text('EMS'), findsOneWidget);
    expect(find.text('Fire & EMS'), findsOneWidget);

    await tester.tap(find.text('Fire').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Career Setup'), findsOneWidget);
    expect(find.text('Step 2 of 4'), findsOneWidget);
    expect(find.text('Use Recruit'), findsOneWidget);
    expect(find.text('Service type (optional)'), findsOneWidget);
    expect(find.text('Years of service (optional)'), findsOneWidget);
  });
}
