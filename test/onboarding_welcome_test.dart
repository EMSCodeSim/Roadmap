import 'package:firepath/pages/onboarding/onboarding_v2_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome explains the app and offers one startup path',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingV2Page()),
    );

    expect(
      find.text('One career record. A clearer path forward.'),
      findsOneWidget,
    );
    expect(find.text('Keep your career record'), findsOneWidget);
    expect(find.text('Build a simple roadmap'), findsOneWidget);
    expect(
      find.text('Connect to a department when needed'),
      findsOneWidget,
    );
    expect(
      find.textContaining('A department connection is optional'),
      findsOneWidget,
    );
    expect(find.text('Start with my personal record'), findsNothing);
    expect(find.text('Set up my roadmap first'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('single startup path continues to career setup',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingV2Page()),
    );

    await tester.tap(find.text('Continue'));
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
