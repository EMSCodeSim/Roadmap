import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/pages/home/visual_home_page.dart';
import 'package:firepath/state/app_mode_controller.dart';
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
    'Home stays focused on daily priorities',
    (tester) async {
      final app = AppState();
      await tester.runAsync(app.bootstrap);
      final department = DepartmentInboxController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppModeController>(
              create: (_) => AppModeController(),
            ),
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
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text &&
              const {'Good night', 'Good morning', 'Good afternoon', 'Good evening'}
                  .contains(widget.data),
        ),
        findsOneWidget,
      );
      expect(find.text('Career goal'), findsOneWidget);
      expect(find.text('Next best step'), findsOneWidget);
      expect(find.text('Needs attention'), findsOneWidget);
      expect(find.text('Credentials'), findsOneWidget);
      expect(find.text('YOUR CAREER'), findsNothing);
      expect(find.text('Add detailed career history'), findsNothing);
      expect(find.text('Unfinished records'), findsNothing);
      expect(find.text('Department attention'), findsNothing);
      expect(find.text('Open Career Goals'), findsNothing);
      expect(find.text('Quick actions'), findsNothing);
      expect(find.text('My Progress'), findsNothing);
      expect(find.text('My Goals'), findsNothing);
      expect(find.text('My Learning'), findsNothing);
      expect(find.text('My Achievements'), findsNothing);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
