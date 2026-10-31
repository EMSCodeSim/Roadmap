import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/portfolio_backup_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets(
    'backup sheet makes file save and file restore the primary actions',
      timeout: const Timeout(Duration(seconds: 45)),
      (tester) async {
        final app = AppState();
        print('backup widget test: bootstrap start');
        await app.bootstrap();
        print('backup widget test: bootstrap done');

        print('backup widget test: pump start');
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: app,
            child: const MaterialApp(
              home: Scaffold(body: PortfolioBackupSheet()),
            ),
          ),
        );
        print('backup widget test: pump done');
        await tester.pump();
        print('backup widget test: initial frame done');

        expect(find.byKey(const Key('backup-save-file')), findsOneWidget);
        expect(find.byKey(const Key('backup-restore-file')), findsOneWidget);
        expect(find.text('Save or share backup file'), findsOneWidget);
        expect(find.text('Restore from backup file'), findsOneWidget);
        expect(find.text('Paste FireOps Career Portfolio JSON'), findsNothing);

        await tester.tap(find.text('Paste an older backup instead'));
        print('backup widget test: tap done');
        await tester.pump();
        print('backup widget test: second frame done');
        expect(find.text('Paste FireOps Career Portfolio JSON'), findsOneWidget);
        expect(find.text('Restore pasted backup'), findsOneWidget);
      },
  );
}
