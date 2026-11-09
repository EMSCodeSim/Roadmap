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

    expect(find.text('Personal Progress'), findsOneWidget);
    expect(find.text('My Roadmap'), findsOneWidget);
    expect(find.text('Department updates'), findsOneWidget);
    expect(find.text('Open Department'), findsNothing);

    // Department actions stay collapsed until the member asks for them.
    await tester.scrollUntilVisible(
      find.text('Department updates'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Department updates'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Open Department'), findsOneWidget);
  });
}
