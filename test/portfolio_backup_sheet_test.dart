import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/portfolio_backup_sheet.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
late Directory _testDocumentsDirectory;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    print('backup setup: before temp directory');
    _testDocumentsDirectory = await Directory.systemTemp.createTemp('roadmap-backup-test-');
    print('backup setup: temp directory ready');
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    _pathProviderChannel.setMockMethodCallHandler((call) async {
      print('backup setup: path provider call ${call.method}');
      if (call.method == 'getApplicationDocumentsDirectory') {
        return _testDocumentsDirectory.path;
      }
      return null;
    });
  });

  tearDown(() async {
    _pathProviderChannel.setMockMethodCallHandler(null);
    if (await _testDocumentsDirectory.exists()) {
      await _testDocumentsDirectory.delete(recursive: true);
    }
  });

  testWidgets(
    'backup sheet makes file save and file restore the primary actions',
    (tester) async {
      final app = AppState();
      print('backup test: bootstrap start');
      await app.bootstrap();
      print('backup test: bootstrap complete');

      print('backup test: pump start');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: const MaterialApp(
            home: Scaffold(body: PortfolioBackupSheet()),
          ),
        ),
      );
      print('backup test: pump complete');
      await tester.pump();

      expect(find.byKey(const Key('backup-save-file')), findsOneWidget);
      expect(find.byKey(const Key('backup-restore-file')), findsOneWidget);
      expect(find.text('Save or share backup file'), findsOneWidget);
      expect(find.text('Restore from backup file'), findsOneWidget);
      expect(find.text('Paste FireOps Career Portfolio JSON'), findsNothing);

      await tester.tap(find.text('Paste an older backup instead'));
      await tester.pump();
      expect(find.text('Paste FireOps Career Portfolio JSON'), findsOneWidget);
      expect(find.text('Restore pasted backup'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
