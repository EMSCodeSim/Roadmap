import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/career_coach.dart';
import 'package:firepath/state/app_state.dart';

Requirement _requirement() {
  final now = DateTime(2026, 1, 1);
  return Requirement(
    id: 'pump-ops',
    name: 'Pump Operations',
    category: 'Driver Operator',
    priority: RequirementPriority.core,
    description: 'Demonstrate pump operations competency.',
    type: RequirementType.practical,
    requirementSource: RequirementSource.commonlyRequired,
    defaultRequired: true,
    stateDependent: false,
    departmentDependent: false,
    completed: false,
    progressCurrent: null,
    progressRequired: null,
    progressUnit: null,
    experienceValue: null,
    experienceUnit: null,
    certificationReference: null,
    certificationDefinitionId: null,
    allowExpiredCertification: false,
    prerequisiteRequirementIds: const [],
    resourceIds: const [],
    resourceLinks: const [],
    sortOrder: 1,
    estimatedDurationDays: null,
    recommendedLeadTimeDays: null,
    canRunConcurrent: true,
    timelineCategory: TimelineCategory.practical,
    suggestedStartDate: null,
    suggestedCompletionDate: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('Career Coach suggests linking recent matching evidence', () async {
    final app = AppState();
    final req = _requirement();
    final now = DateTime(2026, 10, 3);
    final goal = CareerGoal(
      id: 'engineer',
      title: 'Engineer',
      category: 'Promotion',
      description: '',
      subtitle: null,
      typicalPrerequisiteRoles: const [],
      requirements: [req],
      recommendedExperience: const [],
      resourceIds: const [],
      nextRoles: const [],
      createdAt: now,
      updatedAt: now,
    );
    app.debugSetRoadmapForTesting(
      Roadmap(
        goal: goal,
        all: [RoadmapRequirement(requirement: req, isComplete: false, isExcluded: false)],
      ),
    );

    final record = CareerRecord(
      id: 'r1',
      type: CareerRecordType.skill,
      title: 'Pump Operations practice',
      category: 'Driver Operator',
      date: now.subtract(const Duration(days: 2)),
      roleOrAssignment: null,
      summary: 'Practiced pump pressure control.',
      impact: null,
      evidenceReference: null,
      hours: 1,
      repetitions: 1,
      tags: const ['pump', 'driver'],
      relatedGoalId: null,
      relatedRequirementId: null,
      relatedTaskId: null,
      highlight: false,
      trackingKey: null,
      outcome: CareerRecordOutcome.completed,
      details: const {},
      createdAt: now,
      updatedAt: now,
    );

    final prompts = CareerCoachEngine.build(
      app: app,
      records: [record],
      now: now,
    );

    expect(prompts, isNotEmpty);
    expect(prompts.first.kind, CareerCoachKind.evidenceSuggestion);
    expect(prompts.first.requirement?.requirement.id, 'pump-ops');
  });
}
