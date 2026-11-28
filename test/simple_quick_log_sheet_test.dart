import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/services/department_link_store.dart';

import 'package:firepath/pages/career/production_quick_log_sheet.dart';

void main() {
  testWidgets('standalone users only see personal quick-log actions', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppModeController(),
        child: const MaterialApp(
          home: Scaffold(
            body: ProductionQuickLogSheet(),
          ),
        ),
      ),
    );

    expect(find.text('What are you logging?'), findsOneWidget);
    expect(find.text('Create Training Sheet'), findsNothing);
    expect(find.byKey(const Key('quick_add_training_sheet')), findsNothing);
    expect(find.text('Scan Training Sheet'), findsNothing);
    expect(find.byKey(const Key('quick_add_scan_class_qr')), findsNothing);
    expect(find.text('TRAINING'), findsOneWidget);
    expect(find.text('CALL'), findsOneWidget);
    expect(find.text('SKILL'), findsOneWidget);
    expect(find.text('EXPOSURE'), findsOneWidget);
    expect(find.text('DRIVING'), findsOneWidget);
    expect(find.text('CAREER'), findsOneWidget);
    expect(
      find.text('Customize Quick Pick Buttons'),
      findsOneWidget,
    );
    expect(
      find.text('Choose and arrange your colored Quick Add tiles'),
      findsOneWidget,
    );
    expect(find.text('Task Book / Career Road progress'), findsNothing);
    expect(find.text('Training Resources'), findsOneWidget);
    expect(find.byKey(const Key('quick_add_training_resources')), findsOneWidget);
    expect(find.text('Scan department class QR'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('department members can scan but cannot create training sheets',
      (tester) async {
    final mode = AppModeController();
    await mode.setDepartmentLink(_departmentLink(role: 'MEMBER'));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: mode,
        child: const MaterialApp(
          home: Scaffold(body: ProductionQuickLogSheet()),
        ),
      ),
    );

    expect(find.text('Create Training Sheet'), findsNothing);
    expect(find.byKey(const Key('quick_add_training_sheet')), findsNothing);
    expect(find.text('Scan Training Sheet'), findsOneWidget);
    expect(find.byKey(const Key('quick_add_scan_class_qr')), findsOneWidget);
    expect(find.text('Scan department class QR'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('department instructors can create and scan training sheets',
      (tester) async {
    final mode = AppModeController();
    await mode.setDepartmentLink(_departmentLink(role: 'INSTRUCTOR'));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: mode,
        child: const MaterialApp(
          home: Scaffold(body: ProductionQuickLogSheet()),
        ),
      ),
    );

    expect(find.text('Create Training Sheet'), findsOneWidget);
    expect(find.byKey(const Key('quick_add_training_sheet')), findsOneWidget);
    expect(find.text('Scan Training Sheet'), findsOneWidget);
    expect(find.byKey(const Key('quick_add_scan_class_qr')), findsOneWidget);

    await tester.ensureVisible(find.text('DRIVING'));
    await tester.tap(find.text('DRIVING'));
    await tester.pumpAndSettle();

    expect(find.text('Which apparatus?'), findsOneWidget);
    expect(find.text('Create Training Sheet'), findsNothing);
    expect(find.text('Scan Training Sheet'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Create Training Sheet'), findsOneWidget);
    expect(find.text('Scan Training Sheet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('department evaluators can scan but cannot create training sheets',
      (tester) async {
    final mode = AppModeController();
    await mode.setDepartmentLink(_departmentLink(role: 'EVALUATOR'));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: mode,
        child: const MaterialApp(
          home: Scaffold(body: ProductionQuickLogSheet()),
        ),
      ),
    );

    expect(find.text('Create Training Sheet'), findsNothing);
    expect(find.text('Scan Training Sheet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('department administrators can create and scan training sheets',
      (tester) async {
    final mode = AppModeController();
    await mode.setDepartmentLink(
      _departmentLink(role: 'DEPARTMENT_ADMINISTRATOR'),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: mode,
        child: const MaterialApp(
          home: Scaffold(body: ProductionQuickLogSheet()),
        ),
      ),
    );

    expect(find.text('Create Training Sheet'), findsOneWidget);
    expect(find.text('Scan Training Sheet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Training Resources offers EMSCodeSim and FireOpsSim',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppModeController(),
        child: const MaterialApp(
          home: Scaffold(body: ProductionQuickLogSheet()),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Training Resources'));
    await tester.tap(find.text('Training Resources'));
    await tester.pumpAndSettle();

    expect(find.text('Choose training library'), findsOneWidget);
    expect(find.text('EMS Training'), findsOneWidget);
    expect(find.text('Open EMSCodeSim'), findsOneWidget);
    expect(find.text('Fire Training'), findsOneWidget);
    expect(find.text('Open FireOpsSim'), findsOneWidget);
    expect(find.byKey(const Key('training_library_ems')), findsOneWidget);
    expect(find.byKey(const Key('training_library_fire')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Career opens grouped career activity choices', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppModeController(),
        child: const MaterialApp(
          home: Scaffold(
            body: ProductionQuickLogSheet(),
          ),
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

  testWidgets('Quick Pick categories only show selectable choices',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppModeController(),
        child: const MaterialApp(
          home: Scaffold(body: ProductionQuickLogSheet()),
        ),
      ),
    );

    await tester.ensureVisible(find.text('CALL'));
    await tester.tap(find.text('CALL'));
    await tester.pumpAndSettle();

    expect(find.text('What kind of call?'), findsOneWidget);
    expect(find.text('Customize these choices'), findsNothing);
    expect(find.text('Custom / more details'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Driving captures miles response mode emergent transport and notes',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppModeController(),
        child: const MaterialApp(
          home: Scaffold(
            body: ProductionQuickLogSheet(),
          ),
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
    expect(find.text('Drive time (minutes)'), findsOneWidget);
    expect(find.text('Response'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Emergent / lights & siren'), findsOneWidget);
    expect(find.text('Patient transport'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skill capture supports IV success attempts and notes', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppModeController(),
        child: const MaterialApp(
          home: Scaffold(
            body: ProductionQuickLogSheet(),
          ),
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
    expect(find.text('Personal only'), findsOneWidget);
    expect(find.text('Share with department'), findsOneWidget);
    expect(
      find.textContaining('first result will start a success-rate statistic'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exposure captures possible health hazard context', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppModeController(),
        child: const MaterialApp(
          home: Scaffold(body: ProductionQuickLogSheet()),
        ),
      ),
    );

    await tester.ensureVisible(find.text('EXPOSURE'));
    await tester.tap(find.text('EXPOSURE'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Smoke / combustion products'));
    await tester.tap(find.text('Smoke / combustion products'));
    await tester.pumpAndSettle();

    expect(find.text('Approx. exposure time (minutes)'), findsOneWidget);
    expect(find.textContaining('not an official exposure report'), findsOneWidget);
    expect(find.textContaining('document the incident with an officer'), findsOneWidget);
    expect(find.text('Personal only'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

DepartmentLink _departmentLink({required String role}) => DepartmentLink(
      departmentId: 'department-1',
      departmentName: 'Test Department',
      userId: 'user-1',
      userName: 'Test User',
      email: 'test@example.com',
      role: role,
      rank: null,
      linkedAt: DateTime(2026, 1, 1),
    );
