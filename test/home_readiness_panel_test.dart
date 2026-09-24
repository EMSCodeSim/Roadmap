import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/career_path.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/pages/home/visual_home_page.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/app_state.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PathProviderPlatform previous;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('firepath_home_');
    previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = previous;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpHome(WidgetTester tester, AppState app) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider(create: (_) => AppModeController()),
        ],
        child: const MaterialApp(home: VisualHomePage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('home leads with My Roadmap and one next step', (tester) async {
    final app = AppState();
    await app.bootstrap();
    final now = DateTime(2026, 1, 1);
    await app.updateProfile(
      UserProfile(
        currentRoles: const ['Volunteer Firefighter'],
        primaryGoalId: 'ops_engineer',
        targetDate: null,
        careerPlan: CareerPlan(
          goalId: 'ops_engineer',
          startDate: now,
          targetDate: null,
          timelineEnabled: false,
          timelineStatus: TimelineStatus.noTargetDate,
        ),
        yearsOfService: 5,
        serviceType: 'Volunteer',
        departmentName: null,
        state: 'CO',
        careerPath: CareerPath.fire,
        careerPathConfirmed: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await app.profileController.setOnboardingComplete(true);

    await pumpHome(tester, app);

    expect(find.text('Department'), findsOneWidget);
    expect(find.text('MY ROADMAP'), findsOneWidget);
    expect(find.text('NEXT STEP'), findsOneWidget);
    expect(find.text('Do next step'), findsOneWidget);
    expect(find.text("Start today's focus"), findsOneWidget);
    expect(find.text('My Progress'), findsOneWidget);
    expect(find.text('Certifications'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.textContaining('Driver/Operator'), findsWidgets);
  });

  testWidgets('home prompts for a roadmap when no goal is set', (tester) async {
    final app = AppState();
    await app.bootstrap();

    await pumpHome(tester, app);

    expect(find.text('Department'), findsOneWidget);
    expect(find.text('Build My Roadmap'), findsOneWidget);
    expect(find.text('MY ROADMAP'), findsNothing);
  });

  testWidgets('legacy Fire users see lightweight career path confirm',
      (tester) async {
    final app = AppState();
    await app.bootstrap();
    final now = DateTime(2026, 1, 1);
    await app.updateProfile(
      UserProfile(
        currentRoles: const ['Volunteer Firefighter'],
        primaryGoalId: 'ops_firefighter',
        targetDate: null,
        careerPlan: CareerPlan(
          goalId: 'ops_firefighter',
          startDate: now,
          targetDate: null,
          timelineEnabled: false,
          timelineStatus: TimelineStatus.noTargetDate,
        ),
        yearsOfService: 5,
        serviceType: 'Volunteer',
        departmentName: null,
        state: 'CO',
        careerPath: null,
        careerPathConfirmed: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await app.profileController.setOnboardingComplete(true);

    await pumpHome(tester, app);

    expect(find.text('Your Roadmap is currently set to Fire.'), findsOneWidget);
    expect(find.text('Keep Fire'), findsOneWidget);
    expect(find.text('Add EMS'), findsOneWidget);
    expect(find.text('Switch to EMS'), findsOneWidget);

    await tester.tap(find.text('Add EMS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(app.profile.careerPath, CareerPath.both);
    expect(app.profile.primaryTrack, CareerPath.fire);
    expect(app.profile.careerPathConfirmed, isTrue);
    expect(find.text('Your Roadmap is currently set to Fire.'), findsNothing);
  });
}
