import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/portfolio_backup_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('backup sheet makes file save and file restore the primary actions',
      (tester) async {
    final app = AppState();
    await app.bootstrap();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(
          home: Scaffold(body: PortfolioBackupSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('backup-save-file')), findsOneWidget);
    expect(find.byKey(const Key('backup-restore-file')), findsOneWidget);
    expect(find.text('Save or share backup file'), findsOneWidget);
    expect(find.text('Restore from backup file'), findsOneWidget);
    expect(find.text('Paste FireOps Career Portfolio JSON'), findsNothing);

    await tester.tap(find.text('Paste an older backup instead'));
    await tester.pumpAndSettle();
    expect(find.text('Paste FireOps Career Portfolio JSON'), findsOneWidget);
    expect(find.text('Restore pasted backup'), findsOneWidget);
  });
}
