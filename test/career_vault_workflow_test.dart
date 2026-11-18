import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/pages/career/career_vault_page.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets(
    'create entry opens the editor and saves a personal record',
    (tester) async {
    final app = AppState();
    await tester.runAsync(app.bootstrap);
    final api = ResponderRoadmapApi(
      client: MockClient((request) async => http.Response(
        jsonEncode(<String, Object>{'userId': 'standalone-user'}),
        200,
        headers: const {'content-type': 'application/json'},
      )),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          home: CareerVaultPage(openEditorOnLoad: true, api: api),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Add career record'), findsOneWidget);
    final titleField = find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField && widget.decoration?.labelText == 'Title *',
    );
    await tester.enterText(titleField, 'EMT instructor course');
    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('EMT instructor course'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
