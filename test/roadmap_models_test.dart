import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/notification_preferences_store.dart';

Requirement _req({
  required String id,
  required String name,
  required RequirementPriority priority,
  required RequirementType type,
  int sortOrder = 10,
  List<String> prereqs = const [],
  RequirementSource source = RequirementSource.commonlyRequired,
  bool completed = false,
}) {
  final now = DateTime(2026, 8, 16);
  return Requirement(
    id: id,
    name: name,
    category: 'Test',
    priority: priority,
    description: name,
    type: type,
    requirementSource: source,
    defaultRequired: true,
    stateDependent: false,
    departmentDependent: false,
    completed: completed,
    progressCurrent: null,
    progressRequired: null,
    progressUnit: null,
    experienceValue: null,
    experienceUnit: null,
    certificationReference: name,
    certificationDefinitionId: null,
    allowExpiredCertification: false,
    prerequisiteRequirementIds: prereqs,
    resourceIds: const [],
    resourceLinks: const [],
    sortOrder: sortOrder,
    estimatedDurationDays: null,
    recommendedLeadTimeDays: null,
    canRunConcurrent: true,
    timelineCategory: null,
    suggestedStartDate: null,
    suggestedCompletionDate: null,
    createdAt: now,
    updatedAt: now,
  );
}

CareerGoal _goal(List<Requirement> requirements) {
  final now = DateTime(2026, 8, 16);
  return CareerGoal(
    id: 'goal_test',
    title: 'Test Goal',
    category: 'Ops',
    description: 'Test',
    subtitle: null,
    typicalPrerequisiteRoles: const [],
    requirements: requirements,
    recommendedExperience: const [],
    resourceIds: const [],
    nextRoles: const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Roadmap.nextStep', () {
    test('returns null when every included requirement is complete', () {
      final roadmap = Roadmap(
        goal: _goal([
          _req(
            id: 'a',
            name: 'Firefighter I',
            priority: RequirementPriority.core,
            type: RequirementType.certification,
          ),
        ]),
        all: [
          RoadmapRequirement(
            requirement: _req(
              id: 'a',
              name: 'Firefighter I',
              priority: RequirementPriority.core,
              type: RequirementType.certification,
            ),
            isComplete: true,
            isExcluded: false,
          ),
        ],
      );

      expect(roadmap.nextStep, isNull);
      expect(roadmap.percentComplete, 1.0);
    });

    test('prefers unmet prerequisite over later core cert', () {
      final ff1 = _req(
        id: 'ff1',
        name: 'Firefighter I',
        priority: RequirementPriority.core,
        type: RequirementType.certification,
        sortOrder: 1,
      );
      final ff2 = _req(
        id: 'ff2',
        name: 'Firefighter II',
        priority: RequirementPriority.core,
        type: RequirementType.certification,
        sortOrder: 2,
        prereqs: const ['Firefighter I'],
      );

      final roadmap = Roadmap(
        goal: _goal([ff1, ff2]),
        all: [
          RoadmapRequirement(
            requirement: ff1,
            isComplete: false,
            isExcluded: false,
          ),
          RoadmapRequirement(
            requirement: ff2,
            isComplete: false,
            isExcluded: false,
          ),
        ],
      );

      expect(roadmap.nextStep?.requirement.id, 'ff1');
    });

    test('prefers core certification over recommended development', () {
      final core = _req(
        id: 'core',
        name: 'EMT',
        priority: RequirementPriority.core,
        type: RequirementType.certification,
        sortOrder: 20,
      );
      final recommended = _req(
        id: 'rec',
        name: 'Instructor I',
        priority: RequirementPriority.recommended,
        type: RequirementType.certification,
        sortOrder: 1,
      );

      final roadmap = Roadmap(
        goal: _goal([core, recommended]),
        all: [
          RoadmapRequirement(
            requirement: recommended,
            isComplete: false,
            isExcluded: false,
          ),
          RoadmapRequirement(
            requirement: core,
            isComplete: false,
            isExcluded: false,
          ),
        ],
      );

      expect(roadmap.nextStep?.requirement.id, 'core');
    });

    test('excluded requirements do not count toward progress', () {
      final included = _req(
        id: 'keep',
        name: 'HazMat Ops',
        priority: RequirementPriority.core,
        type: RequirementType.certification,
      );
      final excluded = _req(
        id: 'drop',
        name: 'Optional Course',
        priority: RequirementPriority.recommended,
        type: RequirementType.course,
      );

      final roadmap = Roadmap(
        goal: _goal([included, excluded]),
        all: [
          RoadmapRequirement(
            requirement: included,
            isComplete: true,
            isExcluded: false,
          ),
          RoadmapRequirement(
            requirement: excluded,
            isComplete: false,
            isExcluded: true,
          ),
        ],
      );

      expect(roadmap.totalCount, 1);
      expect(roadmap.completedCount, 1);
      expect(roadmap.nextStep, isNull);
    });
  });

  group('PathRequirementOverride json', () {
    test('round trips schedule and activity status', () {
      final original = PathRequirementOverride(
        goalId: 'goal',
        requirementId: 'req',
        excluded: false,
        completed: true,
        overrideExperienceValue: 2,
        overrideProgressCurrent: 3,
        overrideProgressRequired: 10,
        overrideProgressUnit: 'hours',
        activityStatus: RequirementActivityStatus.scheduled,
        schedule: const TrainingSchedule(
          courseName: 'Pump Ops',
          provider: 'Academy',
          startDate: null,
          endDate: null,
          location: 'Station 1',
          notes: null,
        ),
        taskBookCompletedItems: 1,
        taskBookTotalItems: 4,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        removedFromTimeline: false,
      );

      final restored = PathRequirementOverride.fromJson(original.toJson());
      expect(restored.activityStatus, RequirementActivityStatus.scheduled);
      expect(restored.schedule?.courseName, 'Pump Ops');
      expect(restored.overrideProgressCurrent, 3);
      expect(restored.completed, isTrue);
    });
  });

  group('NotificationPreferencesStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads defaults then persists toggles', () async {
      final store = NotificationPreferencesStore();
      final initial = await store.load();
      expect(initial.dailyFocusReminders, isFalse);
      expect(initial.certificationExpiryAlerts, isTrue);
      expect(initial.targetDateRiskAlerts, isTrue);

      await store.save(
        initial.copyWith(
          dailyFocusReminders: true,
          certificationExpiryAlerts: false,
        ),
      );

      final reloaded = await store.load();
      expect(reloaded.dailyFocusReminders, isTrue);
      expect(reloaded.certificationExpiryAlerts, isFalse);
      expect(reloaded.targetDateRiskAlerts, isTrue);
    });
  });
}
