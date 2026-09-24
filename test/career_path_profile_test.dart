import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/career_path.dart';
import 'package:firepath/models/user_profile.dart';

void main() {
  test('legacy profiles without careerPath default to Fire and need confirm', () {
    final now = DateTime(2026, 1, 1);
    final profile = UserProfile(
      currentRoles: const ['Firefighter'],
      primaryGoalId: 'ops_firefighter',
      targetDate: null,
      careerPlan: CareerPlan.empty(),
      yearsOfService: 2,
      serviceType: 'Career',
      departmentName: null,
      state: 'TX',
      createdAt: now,
      updatedAt: now,
    );

    expect(profile.careerPath, isNull);
    expect(profile.effectiveCareerPath, CareerPath.fire);
    expect(profile.needsCareerPathConfirmation, isTrue);
  });

  test('careerPath round-trips through JSON without dropping progress fields', () {
    final now = DateTime(2026, 2, 2);
    final original = UserProfile(
      currentRoles: const ['Paramedic', 'Firefighter'],
      primaryGoalId: 'ems_paramedic',
      targetDate: null,
      careerPlan: CareerPlan(
        goalId: 'ems_paramedic',
        startDate: now,
        targetDate: null,
        timelineEnabled: false,
        timelineStatus: TimelineStatus.noTargetDate,
      ),
      yearsOfService: 5,
      serviceType: 'Career',
      departmentName: null,
      state: 'CA',
      careerPath: CareerPath.both,
      primaryTrack: CareerPath.ems,
      careerPathConfirmed: true,
      createdAt: now,
      updatedAt: now,
    );

    final restored = UserProfile.fromJson(original.toJson());
    expect(restored.careerPath, CareerPath.both);
    expect(restored.primaryTrack, CareerPath.ems);
    expect(restored.careerPathConfirmed, isTrue);
    expect(restored.currentRoles, original.currentRoles);
    expect(restored.primaryGoalId, 'ems_paramedic');
    expect(restored.emphasisTrack, CareerPath.ems);
  });

  test('storage values use FIRE / EMS / BOTH', () {
    expect(CareerPath.fire.storageValue, 'FIRE');
    expect(CareerPath.ems.storageValue, 'EMS');
    expect(CareerPath.both.storageValue, 'BOTH');
    expect(CareerPathX.tryParse('fire'), CareerPath.fire);
    expect(CareerPathX.tryParse('EMS'), CareerPath.ems);
    expect(CareerPathX.tryParse('BOTH'), CareerPath.both);
  });
}
