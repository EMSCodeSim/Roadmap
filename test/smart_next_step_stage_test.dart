import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/task_book_stage_planner.dart';

Requirement _req({
  required String id,
  required String name,
  required RequirementType type,
  RequirementPriority priority = RequirementPriority.core,
  List<String> prereqs = const [],
  double? current,
  double? required,
  int sortOrder = 10,
}) {
  final now = DateTime(2026, 8, 26);
  return Requirement(
    id: id,
    name: name,
    category: 'Test',
    priority: priority,
    description: name,
    type: type,
    requirementSource: RequirementSource.commonlyRequired,
    defaultRequired: true,
    stateDependent: false,
    departmentDependent: false,
    completed: false,
    progressCurrent: current,
    progressRequired: required,
    progressUnit: current == null ? null : 'hours',
    experienceValue: null,
    experienceUnit: null,
    certificationReference: type == RequirementType.certification ? name : null,
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

void main() {
  test('locked requirement stays visible but cannot become suggested next', () {
    final officerOne = _req(
      id: 'fo1',
      name: 'Fire Officer I',
      type: RequirementType.certification,
      sortOrder: 10,
    );
    final officerTwo = _req(
      id: 'fo2',
      name: 'Fire Officer II',
      type: RequirementType.certification,
      prereqs: const ['Fire Officer I'],
      sortOrder: 20,
    );

    final plan = TaskBookStagePlanner.buildPlan<Requirement>(
      items: [officerOne, officerTwo],
      getRequirement: (r) => r,
      isComplete: (_) => false,
      getId: (r) => r.id,
    );

    expect(plan.suggestedNext?.requirement.id, 'fo1');
    final locked = plan.sections
        .expand((section) => section.items)
        .firstWhere((item) => item.requirement.id == 'fo2');
    expect(locked.canStartNow, isFalse);
    expect(locked.unmetPrerequisiteLabels, contains('Complete Fire Officer I first'));
  });

  test('partially completed work is favored inside the current stage', () {
    final untouched = _req(
      id: 'hours-a',
      name: 'Company officer acting hours',
      type: RequirementType.numericProgress,
      current: 0,
      required: 100,
      sortOrder: 10,
    );
    final underway = _req(
      id: 'hours-b',
      name: 'Command repetitions',
      type: RequirementType.numericProgress,
      current: 6,
      required: 20,
      sortOrder: 20,
    );

    final plan = TaskBookStagePlanner.buildPlan<Requirement>(
      items: [untouched, underway],
      getRequirement: (r) => r,
      isComplete: (_) => false,
      getId: (r) => r.id,
    );

    expect(plan.suggestedNext?.requirement.id, 'hours-b');
  });
}
