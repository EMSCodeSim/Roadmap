import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/settings/settings_page.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  testWidgets('main settings exposes phone notification preferences',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => AppState(),
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    expect(
      find.byKey(const Key('settings-phone-notifications')),
      findsOneWidget,
    );
    expect(find.text('Phone notifications'), findsOneWidget);
    expect(
      find.text('Task Books, Assignments, and Needs Attention alerts'),
      findsOneWidget,
    );
  });
}
