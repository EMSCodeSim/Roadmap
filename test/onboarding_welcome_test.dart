import 'package:firepath/pages/onboarding/onboarding_v2_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome offers a clear standalone starting point',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingV2Page()),
    );

    expect(
      find.text('Your Fire & EMS career record starts here.'),
      findsOneWidget,
    );
    expect(find.text('Start with my personal record'), findsOneWidget);
    expect(find.text('Set up my roadmap first'), findsOneWidget);
    expect(find.text('A class or training'), findsOneWidget);
    expect(find.text('A certification'), findsOneWidget);
    expect(find.text('Experience or an accomplishment'), findsOneWidget);
    expect(
      find.textContaining('You do not need a career goal or department'),
      findsOneWidget,
    );
  });

  testWidgets('setup starts with career path then recruit shortcut',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingV2Page()),
    );

    await tester.tap(find.text('Set up my roadmap first'));
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
