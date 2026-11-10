import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/pages/home/visual_home_page.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home stays focused on daily priorities', (tester) async {
    final app = AppState();
    await tester.runAsync(app.bootstrap);

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
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Next action'), findsOneWidget);
    expect(find.text('Credentials'), findsOneWidget);
    expect(find.text('Unfinished records'), findsOneWidget);
    expect(find.text('Department attention'), findsOneWidget);
    expect(find.text('Start my roadmap'), findsNothing);

    await tester.scrollUntilVisible(find.text('Open My Roadmap'), 300);
    expect(find.text('Open My Roadmap'), findsOneWidget);
  });
}
