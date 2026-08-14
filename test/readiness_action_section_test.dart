import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/readiness_action_plan.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/readiness_action_section.dart';

Requirement _requirement({
  required String id,
  required String name,
  required RequirementType type,
}) {
  final now = DateTime(2026, 1, 1);
  return Requirement(
    id: id,
    name: name,
    category: 'Test',
    priority: RequirementPriority.core,
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
    certificationReference: null,
    certificationDefinitionId: null,
    allowExpiredCertification: false,
    prerequisiteRequirementIds: const [],
    resourceIds: const [],
    resourceLinks: const [],
    sortOrder: 10,
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

ReadinessActionItem _item({
  required String id,
  required String name,
  required RequirementType type,
  required ReadinessActionKind kind,
  required String label,
}) {
  return ReadinessActionItem(
    roadmapRequirement: RoadmapRequirement(
      requirement: _requirement(id: id, name: name, type: type),
      isComplete: false,
      isExcluded: false,
    ),
    actionKind: kind,
    actionLabel: label,
    reason: 'This is a high-priority item on your path.',
  );
}

void main() {
  testWidgets('shows top three readiness actions by default', (tester) async {
    final plan = CareerReadinessActionPlan(items: [
      _item(
        id: 'a',
        name: 'Driver Operator – Pumper',
        type: RequirementType.certification,
        kind: ReadinessActionKind.getStarted,
        label: 'GET STARTED',
      ),
      _item(
        id: 'b',
        name: 'Driving Hours',
        type: RequirementType.numericProgress,
        kind: ReadinessActionKind.logProgress,
        label: 'LOG PROGRESS',
      ),
      _item(
        id: 'c',
        name: 'Engineer Task Book',
        type: RequirementType.taskBook,
        kind: ReadinessActionKind.updateTaskBook,
        label: 'UPDATE PROGRESS',
      ),
      _item(
        id: 'd',
        name: 'ICS-200',
        type: RequirementType.certification,
        kind: ReadinessActionKind.getStarted,
        label: 'GET STARTED',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadinessActionSection(plan: plan),
        ),
      ),
    );

    expect(find.text('WHAT TO WORK ON'), findsOneWidget);
    expect(find.text('Driver Operator – Pumper'), findsOneWidget);
    expect(find.text('Driving Hours'), findsOneWidget);
    expect(find.text('Engineer Task Book'), findsOneWidget);
    expect(find.text('ICS-200'), findsNothing);
  });

  testWidgets('forwards the tapped readiness action', (tester) async {
    final first = _item(
      id: 'a',
      name: 'Driver Operator – Pumper',
      type: RequirementType.certification,
      kind: ReadinessActionKind.getStarted,
      label: 'GET STARTED',
    );
    ReadinessActionItem? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadinessActionSection(
            plan: CareerReadinessActionPlan(items: [first]),
            onAction: (item) => tapped = item,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Driver Operator – Pumper'));
    await tester.pump();

    expect(tapped, same(first));
  });

  testWidgets('hides completely when there are no actions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadinessActionSection(
            plan: CareerReadinessActionPlan(items: []),
          ),
        ),
      ),
    );

    expect(find.text('WHAT TO WORK ON'), findsNothing);
  });
}
