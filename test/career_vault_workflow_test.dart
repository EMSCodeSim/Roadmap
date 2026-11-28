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
    'career timeline opens its record editor when requested directly',
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
    expect(find.text('My development'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
  testWidgets(
    'career timeline summarizes growth and includes credential milestones',
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
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.6),
              ),
              child: child!,
            ),
            home: CareerVaultPage(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('Roadmap'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('My development'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('My development'), findsOneWidget);
      expect(find.text('Qualifications'), findsOneWidget);
      final qualifications = tester.widget<Text>(find.text('Qualifications'));
      expect(qualifications.softWrap, isFalse);
      expect(qualifications.overflow, isNull);
      await tester.scrollUntilVisible(
        find.text('Career opportunities'),
        250,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ).first,
      );
      expect(find.text('Career opportunities'), findsOneWidget);
      expect(find.text('Application Center'), findsOneWidget);
      expect(find.text('Job Search'), findsOneWidget);
      expect(find.text('More roadmap tools'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );

}
