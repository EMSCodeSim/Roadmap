import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/readiness_action_plan.dart';
import 'package:firepath/services/readiness_snapshot.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/career_readiness_panel.dart';

Requirement _req(String id, String name, {RequirementType type = RequirementType.certification, RequirementPriority priority = RequirementPriority.core, int sortOrder = 10}) {
  final now = DateTime(2026, 1, 1);
  return Requirement(
    id: id,
    name: name,
    category: 'Test',
    priority: priority,
    description: 'Test requirement',
    type: type,
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
    certificationReference: name,
    certificationDefinitionId: id,
    allowExpiredCertification: false,
    prerequisiteRequirementIds: const [],
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
  final now = DateTime(2026, 1, 1);
  return CareerGoal(
    id: 'goal',
    title: 'Engineer',
    category: 'Operations',
    description: 'Test goal',
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
  testWidgets('panel renders readiness, gaps, and actions together', (tester) async {
    final requirements = [
      _req('driver_operator_pumper', 'Driver Operator – Pumper'),
      _req('drive_hours', 'Apparatus driving hours', type: RequirementType.numericProgress, priority: RequirementPriority.department, sortOrder: 20),
    ];
    final road = Roadmap(
      goal: _goal(requirements),
      all: requirements.map((r) => RoadmapRequirement(requirement: r, isComplete: false, isExcluded: false)).toList(),
    );
    final snapshot = CareerReadinessSnapshot.fromRoadmap(road);
    final plan = CareerReadinessActionPlan.fromRoadmapForTesting(road);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CareerReadinessPanel(
            snapshot: snapshot,
            actionPlan: plan,
            goalTitle: 'Engineer',
          ),
        ),
      ),
    );

    expect(find.textContaining('Engineer'), findsWidgets);
    expect(find.text('MAJOR GAPS'), findsOneWidget);
    expect(find.textContaining('Driver Operator'), findsWidgets);
  });
}
