import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/career_path.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/state/app_state.dart';

/// Home UX coverage without pumping VisualHomePage.
///
/// Widget tests that bootstrap AppState against the real PlatformFileJsonStore
/// can hang in this Linux CI host when path_provider waits on a platform
/// channel. These unit tests cover the Personal Home data contracts instead.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Fire home profile exposes Fire goals and confirmed path copy', () async {
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

    expect(app.profile.effectiveCareerPath, CareerPath.fire);
    expect(app.availableGoals.every((g) => g.id.startsWith('ops_')), isTrue);
    expect(app.selectedGoal?.title, contains('Driver/Operator'));
    expect(CareerPathCopy.homeProductLine(CareerPath.fire), contains('fire'));
    expect(app.roadmap, isNotNull);
    expect(app.roadmap!.totalCount, greaterThan(0));
  });

  test('EMS home profile exposes EMS goals only', () async {
    final app = AppState();
    await app.bootstrap();
    final now = DateTime(2026, 1, 1);
    await app.updateProfile(
      UserProfile(
        currentRoles: const ['EMT'],
        primaryGoalId: 'ems_paramedic',
        targetDate: null,
        careerPlan: CareerPlan(
          goalId: 'ems_paramedic',
          startDate: now,
          targetDate: null,
          timelineEnabled: false,
          timelineStatus: TimelineStatus.noTargetDate,
        ),
        yearsOfService: 2,
        serviceType: 'Career',
        departmentName: null,
        state: 'TX',
        careerPath: CareerPath.ems,
        careerPathConfirmed: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(app.profile.effectiveCareerPath, CareerPath.ems);
    expect(app.availableGoals.every((g) => g.id.startsWith('ems_')), isTrue);
    expect(app.selectedGoal?.title, 'Paramedic');
    expect(
      CareerPathCopy.trackLabelForGoalCategory(app.selectedGoal?.category),
      'EMS',
    );
    // Cumulative EMS ladder should include earlier EMT credential work.
    final ids = app.roadmap!.all.map((e) => e.requirement.id).toSet();
    expect(ids.contains('emt_cred'), isTrue);
    expect(ids.contains('paramedic_cred'), isTrue);
  });

  test('legacy Fire users can add EMS without losing goal progress', () async {
    final app = AppState();
    await app.bootstrap();
    final now = DateTime(2026, 1, 1);
    await app.updateProfile(
      UserProfile(
        currentRoles: const ['Firefighter'],
        primaryGoalId: 'ops_firefighter',
        targetDate: null,
        careerPlan: CareerPlan(
          goalId: 'ops_firefighter',
          startDate: now,
          targetDate: null,
          timelineEnabled: false,
          timelineStatus: TimelineStatus.noTargetDate,
        ),
        yearsOfService: 1,
        serviceType: 'Volunteer',
        departmentName: null,
        state: 'CO',
        careerPath: null,
        careerPathConfirmed: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(app.profile.needsCareerPathConfirmation, isTrue);
    expect(app.profile.effectiveCareerPath, CareerPath.fire);

    await app.setCareerPath(
      careerPath: CareerPath.both,
      primaryTrack: CareerPath.fire,
    );

    expect(app.profile.careerPath, CareerPath.both);
    expect(app.profile.primaryTrack, CareerPath.fire);
    expect(app.profile.careerPathConfirmed, isTrue);
    expect(app.profile.primaryGoalId, 'ops_firefighter');
    expect(app.profile.currentRoles, contains('Firefighter'));
    expect(
      FireOpsCatalog.goalsForPath(CareerPath.both).length,
      FireOpsCatalog.goals().length,
    );
  });
}
