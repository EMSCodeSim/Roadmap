import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/pages/home/visual_home_page.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
late Directory _testDocumentsDirectory;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _testDocumentsDirectory = await Directory.systemTemp.createTemp('roadmap-home-test-');
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    _pathProviderChannel.setMockMethodCallHandler((call) async {
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
    'Home retains My Roadmap and separates personal and department overview',
    (tester) async {
      final app = AppState();
      await app.bootstrap();
      final department = DepartmentInboxController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: app),
            ChangeNotifierProvider<DepartmentInboxController>.value(
              value: department,
            ),
          ],
          child: const MaterialApp(home: VisualHomePage()),
        ),
      );
      // Avoid waiting indefinitely for progress indicators and asynchronous sync.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('My Roadmap'), findsOneWidget);
      expect(find.text('Personal overview'), findsOneWidget);
      expect(find.text('What should I work on next?'), findsNothing);

      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Department overview'), findsOneWidget);
      expect(find.textContaining('Connect to your department'), findsOneWidget);
      expect(find.text('Open Department'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
