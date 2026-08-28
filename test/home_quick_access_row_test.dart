import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/pages/home/visual_home_page.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home quick-access row shows Department and not Task Book', (tester) async {
    final app = AppState();
    await app.bootstrap();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: VisualHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    final row = find.byKey(const Key('home_quick_access_row'));
    expect(row, findsOneWidget);

    expect(
      find.descendant(of: row, matching: find.text('Department')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('Task Book')),
      findsNothing,
    );
    expect(
      find.descendant(of: row, matching: find.text('Build Task Book')),
      findsNothing,
    );
  });
}
