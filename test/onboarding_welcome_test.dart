import 'package:firepath/pages/onboarding/onboarding_v2_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome explains both personal and department workflows',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingV2Page()),
    );

    expect(find.text('Your fire service career, organized.'), findsOneWidget);
    expect(find.text('Build your personal roadmap'), findsOneWidget);
    expect(find.text('Complete task books and assignments'), findsOneWidget);
    expect(find.text('Connect with your department'), findsOneWidget);
    expect(find.text('Set up my roadmap'), findsOneWidget);
    expect(find.textContaining('Connecting a department is optional'),
        findsOneWidget);
  });

  testWidgets('setup starts with clear progress and recruit shortcut',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingV2Page()),
    );

    await tester.tap(find.text('Set up my roadmap'));
    await tester.pumpAndSettle();

    expect(find.text('Career Setup'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Use Recruit'), findsOneWidget);
    expect(find.text('Service type (optional)'), findsOneWidget);
    expect(find.text('Years of service (optional)'), findsOneWidget);
  });
}
