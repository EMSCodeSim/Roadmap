import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/pages/career/career_record_v2_page.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Records separates logs, statistics, and timeline',
      (tester) async {
    final app = AppState();
    await tester.runAsync(app.bootstrap);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: const MaterialApp(
          home: CareerRecordV2Page(embedded: true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Certification Center'), findsOneWidget);
    expect(find.text('Daily Logs'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Career Timeline'), findsOneWidget);
    expect(find.text('DAILY LOG ENTRIES'), findsOneWidget);

    await tester.tap(find.text('Statistics'));
    await tester.pump();
    final mainScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Calls'),
      250,
      scrollable: mainScroll,
    );
    expect(find.text('Calls'), findsOneWidget);
    expect(find.text('Skill reps'), findsOneWidget);
    expect(find.text('DAILY LOG ENTRIES'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Career Timeline'),
      -250,
      scrollable: mainScroll,
    );
    await tester.tap(find.text('Career Timeline'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.textContaining('CAREER TIMELINE'),
      250,
      scrollable: mainScroll,
    );
    expect(find.textContaining('CAREER TIMELINE'), findsOneWidget);
  });
}
