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

  testWidgets('Record Center categories open in focused popup sheets',
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
    expect(find.text('DAILY LOG ENTRIES'), findsNothing);

    await tester.tap(find.text('Certification Center'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Add certification'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Daily Logs'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('DAILY LOG ENTRIES'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Statistics'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Calls'), findsOneWidget);
    expect(find.text('Skill reps'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Career Timeline'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('CAREER TIMELINE'), findsOneWidget);
  });
}
