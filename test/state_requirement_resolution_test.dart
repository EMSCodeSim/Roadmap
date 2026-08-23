import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/controllers/profile_controller.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/catalog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  UserProfile profileFor(String state) {
    final now = DateTime(2026, 8, 23);
    return UserProfile(
      currentRoles: const ['Firefighter'],
      primaryGoalId: 'ops_engineer',
      targetDate: null,
      careerPlan: CareerPlan.empty().copyWith(goalId: 'ops_engineer'),
      yearsOfService: 5,
      serviceType: 'Career',
      departmentName: null,
      state: state,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('California users receive California context, not Colorado context', () async {
    final controller = ProfileController();
    await controller.bootstrap();
    await controller.setProfile(profileFor('CA'));

    final goal = controller.selectedGoalResolved();
    expect(goal, isNotNull);

    final stateDependent = goal!.requirements
        .where((r) => r.stateDependent && r.requirementSource != RequirementSource.stateRequirement)
        .toList();
    expect(stateDependent, isNotEmpty);
    expect(
      stateDependent.every((r) => r.description.contains('California')),
      isTrue,
    );
    expect(
      stateDependent.any((r) => r.description.contains('Colorado')),
      isFalse,
    );
  });

  test('changing state rebuilds state-dependent requirement context', () async {
    final controller = ProfileController();
    await controller.bootstrap();
    await controller.setProfile(profileFor('CA'));

    final california = controller.selectedGoalResolved()!;
    expect(
      california.requirements
          .where((r) => r.stateDependent && r.requirementSource != RequirementSource.stateRequirement)
          .every((r) => r.description.contains('California')),
      isTrue,
    );

    await controller.setProfile(profileFor('TX'));
    final texas = controller.selectedGoalResolved()!;
    final stateDependent = texas.requirements
        .where((r) => r.stateDependent && r.requirementSource != RequirementSource.stateRequirement)
        .toList();
    expect(stateDependent, isNotEmpty);
    expect(stateDependent.every((r) => r.description.contains('Texas')), isTrue);
    expect(stateDependent.any((r) => r.description.contains('California')), isFalse);
  });

  test('no resolved roadmap contains a foreign sourced state requirement', () async {
    for (final option in FireOpsCatalog.usStateOptions) {
      if (option.code == FireOpsCatalog.otherStateCode) continue;

      SharedPreferences.setMockInitialValues({});
      final controller = ProfileController();
      await controller.bootstrap();
      await controller.setProfile(profileFor(option.code));
      final goal = controller.selectedGoalResolved();
      expect(goal, isNotNull, reason: option.name);

      for (final requirement in goal!.requirements) {
        final source = requirement.sourceStateCode?.trim().toUpperCase();
        if (source == null || source.isEmpty) continue;
        expect(
          source,
          option.code,
          reason:
              '${option.name} received ${requirement.name} sourced to $source',
        );
      }
    }
  });
}
