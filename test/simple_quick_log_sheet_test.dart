import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/pages/career/production_quick_log_sheet.dart';

void main() {
  testWidgets('Quick Log starts with six fixed primary choices', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductionQuickLogSheet(),
        ),
      ),
    );

    expect(find.text('What are you logging?'), findsOneWidget);
    expect(find.text('TRAINING'), findsOneWidget);
    expect(find.text('CALL'), findsOneWidget);
    expect(find.text('SKILL'), findsOneWidget);
    expect(find.text('DRIVING'), findsOneWidget);
    expect(find.text('CAREER'), findsOneWidget);
    expect(find.text('TASK BOOK'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Career opens grouped career activity choices', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductionQuickLogSheet(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('CAREER'));
    await tester.tap(find.text('CAREER'));
    await tester.pumpAndSettle();

    expect(find.text('Leadership'), findsOneWidget);
    expect(find.text('Teaching / Instructor'), findsOneWidget);
    expect(find.text('Achievement'), findsOneWidget);
    expect(find.text('Award / Recognition'), findsOneWidget);
    expect(find.text('Project'), findsOneWidget);
    expect(find.text('Education'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Driving captures miles response mode emergent transport and notes',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductionQuickLogSheet(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('DRIVING'));
    await tester.tap(find.text('DRIVING'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Engine'));
    await tester.tap(find.text('Engine'));
    await tester.pumpAndSettle();

    expect(find.text('Miles driven'), findsOneWidget);
    expect(find.text('Response'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Emergent / lights & siren'), findsOneWidget);
    expect(find.text('Patient transport'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skill capture supports IV success attempts and notes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductionQuickLogSheet(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('SKILL'));
    await tester.tap(find.text('SKILL'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('IV / vascular access'));
    await tester.tap(find.text('IV / vascular access'));
    await tester.pumpAndSettle();

    expect(find.text('Attempts / reps'), findsOneWidget);
    expect(find.text('Successful'), findsOneWidget);
    expect(find.text('Attempted'), findsOneWidget);
    expect(find.text('Unsuccessful'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
