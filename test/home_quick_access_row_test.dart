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

  testWidgets('home stays focused on personal career growth', (tester) async {
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

    expect(find.text('Department'), findsNothing);
    expect(find.text('Personal'), findsNothing);
    expect(find.text('Personal overview'), findsOneWidget);
    expect(find.text('Needs attention'), findsWidgets);
    expect(find.text('Open My Roadmap'), findsOneWidget);
    expect(find.text('Department overview'), findsOneWidget);
    expect(find.text('Open Department'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Personal overview')).dy,
      lessThan(tester.getTopLeft(find.text('Department overview')).dy),
    );
  });
}
