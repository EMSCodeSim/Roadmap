import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/certification.dart';
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

    expect(find.byType(AlertDialog), findsOneWidget);
    final titleField = find.byKey(const ValueKey('career_record_title'));
    await tester.ensureVisible(titleField);
    await tester.enterText(titleField, 'EMT instructor course');
    await tester.pump();
    expect(find.text('EMT instructor course'), findsOneWidget);
    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsNothing);
    await tester.ensureVisible(find.text('EMT instructor course').first);
    expect(find.text('EMT instructor course'), findsAtLeastNWidgets(1));
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
  testWidgets(
    'career timeline includes credentials alongside personal records',
    (tester) async {
      final app = AppState();
      await tester.runAsync(app.bootstrap);
      final now = DateTime(2026, 1, 1);
      await tester.runAsync(
        () => app.upsertCertification(
          Certification(
            id: 'timeline-paramedic',
            name: 'Paramedic',
            issuingOrganization: 'National Registry',
            certificationNumber: null,
            certificationDefinitionId: null,
            issueDate: DateTime(2024, 4, 1),
            expirationDate: DateTime(2028, 3, 31),
            doesNotExpire: false,
            notes: null,
            renewalHistory: const [],
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
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
          child: MaterialApp(home: CareerVaultPage(api: api)),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.ensureVisible(
        find.widgetWithText(ListTile, 'Paramedic').first,
      );

      expect(find.text('My Career Timeline'), findsOneWidget);
      expect(find.text('Career snapshot'), findsNothing);
      expect(find.text('Quick capture'), findsNothing);
      expect(find.text('Certification radar'), findsNothing);
      expect(
        find.widgetWithText(ListTile, 'Paramedic'),
        findsAtLeastNWidgets(1),
      );
      expect(find.textContaining('Expires'), findsOneWidget);

      final credentialsFilter = find.widgetWithText(FilterChip, 'Credentials');
      await tester.ensureVisible(credentialsFilter);
      await tester.tap(credentialsFilter);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(
        find.widgetWithText(ListTile, 'Paramedic'),
        findsAtLeastNWidgets(1),
      );
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );

}
