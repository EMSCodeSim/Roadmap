import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/pages/home/visual_home_page.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Home retains My Roadmap and separates personal and department overview', (tester) async {
    final app = AppState();
    await app.bootstrap();
    final department = DepartmentInboxController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<DepartmentInboxController>.value(value: department),
        ],
        child: const MaterialApp(home: VisualHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Roadmap'), findsOneWidget);
    expect(find.text('Personal overview'), findsOneWidget);
    expect(find.text('What should I work on next?'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Department overview'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Department overview'), findsOneWidget);
    expect(find.textContaining('Connect to your department'), findsOneWidget);
    expect(find.text('Open Department'), findsOneWidget);
  });
}
