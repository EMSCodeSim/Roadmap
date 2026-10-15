import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/widgets/portfolio_backup_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'backup sheet makes file save and file restore the primary actions',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PortfolioBackupSheet()),
        ),
      );

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
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
