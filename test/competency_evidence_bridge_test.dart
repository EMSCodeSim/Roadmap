import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/competency_evidence_bridge.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

Requirement requirement({
  required String id,
  required String name,
  String category = 'Operations',
  RequirementType type = RequirementType.taskBook,
}) {
  final now = DateTime(2026, 1, 1);
  return Requirement(
    id: id,
    name: name,
    category: category,
    priority: RequirementPriority.core,
    description: '',
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
    timelineCategory: TimelineCategory.taskBook,
    suggestedStartDate: null,
    suggestedCompletionDate: null,
    createdAt: now,
    updatedAt: now,
  );
}

Roadmap roadmapFor(Requirement req) {
  final now = DateTime(2026, 1, 1);
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
  return Roadmap(
    goal: goal,
    all: [
      RoadmapRequirement(
        requirement: req,
        isComplete: false,
        isExcluded: false,
      ),
    ],
  );
}

void main() {
  group('CompetencyEvidenceBridge', () {
    test('matches department pump work to the personal pump competency', () {
      final assignment = DepartmentTaskBookAssignment.fromJson({
        'id': 'dept-pump-1',
        'taskBookTitle': 'Pump Operator Task Book',
        'category': 'Driver / Operator',
        'status': 'COMPLETE',
        'progress': 100,
      });
      final road = roadmapFor(
        requirement(id: 'pump-ops', name: 'Pump Operations'),
      );

      final match = CompetencyEvidenceBridge.matchAssignment(assignment, road);

      expect(match, isNotNull);
      expect(match!.item.requirement.id, 'pump-ops');
      expect(match.sharedKeys, contains('pump'));
    });

    test('does not force unrelated department work into the roadmap', () {
      final assignment = DepartmentTaskBookAssignment.fromJson({
        'id': 'dept-cpr-1',
        'taskBookTitle': 'CPR Refresher',
        'category': 'EMS',
        'status': 'COMPLETE',
        'progress': 100,
      });
      final road = roadmapFor(
        requirement(id: 'pump-ops', name: 'Pump Operations'),
      );

      expect(
        CompetencyEvidenceBridge.matchAssignment(assignment, road),
        isNull,
      );
    });

    test('creates portable department-verified evidence', () {
      final assignment = DepartmentTaskBookAssignment.fromJson({
        'id': 'dept-pump-2',
        'taskBookTitle': 'Pump Operations',
        'category': 'Driver',
        'assignmentKind': 'TASK_BOOK',
        'version': '2.0',
        'status': 'COMPLETE',
        'progress': 100,
      });
      final road = roadmapFor(
        requirement(id: 'pump-ops', name: 'Pump Operations'),
      );
      final match = CompetencyEvidenceBridge.matchAssignment(assignment, road)!;

      final record = CompetencyEvidenceBridge.toVerifiedCareerRecord(
        assignment: assignment,
        departmentName: 'Example Fire',
        relatedGoalId: road.goal.id,
        match: match,
      );

      expect(record.relatedGoalId, 'engineer');
      expect(record.relatedRequirementId, 'pump-ops');
      expect(record.trackingKey, 'department-assignment:dept-pump-2');
      expect(record.details['verification'], 'department_verified');
      expect(record.details['departmentName'], 'Example Fire');
      expect(record.tags, contains('department-verified'));
    });
  });
}
