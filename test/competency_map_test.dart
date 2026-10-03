import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/competency_map.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

Requirement _req({
  required String id,
  required String name,
  required String category,
  bool complete = false,
}) {
  final now = DateTime(2026, 1, 1);
  return Requirement(
    id: id,
    name: name,
    category: category,
    priority: RequirementPriority.core,
    description: '',
    type: RequirementType.practical,
    requirementSource: RequirementSource.commonlyRequired,
    defaultRequired: true,
    stateDependent: false,
    departmentDependent: false,
    completed: complete,
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
    timelineCategory: TimelineCategory.taskBook,
    suggestedStartDate: null,
    suggestedCompletionDate: null,
    createdAt: now,
    updatedAt: now,
  );
}

Roadmap _roadmap(List<Requirement> requirements) {
  final now = DateTime(2026, 1, 1);
  final goal = CareerGoal(
    id: 'engineer',
    title: 'Engineer',
    category: 'Promotion',
    description: '',
    subtitle: null,
    typicalPrerequisiteRoles: const [],
    requirements: requirements,
    recommendedExperience: const [],
    resourceIds: const [],
    nextRoles: const [],
    createdAt: now,
    updatedAt: now,
  );
  return Roadmap(
    goal: goal,
    all: requirements
        .map(
          (requirement) => RoadmapRequirement(
            requirement: requirement,
            isComplete: requirement.completed,
            isExcluded: false,
          ),
        )
        .toList(),
  );
}

CareerRecord _record({
  required String id,
  required String title,
  required String category,
  required DateTime date,
  String? relatedRequirementId,
  bool exposure = false,
}) {
  return CareerRecord(
    id: id,
    type: CareerRecordType.skill,
    title: title,
    category: category,
    date: date,
    roleOrAssignment: null,
    summary: null,
    impact: null,
    evidenceReference: null,
    hours: 1,
    repetitions: 1,
    tags: const [],
    relatedGoalId: null,
    relatedRequirementId: relatedRequirementId,
    relatedTaskId: null,
    highlight: false,
    trackingKey: null,
    outcome: CareerRecordOutcome.completed,
    details: {
      if (exposure) 'possibleHealthExposure': true,
    },
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  test('competency map marks recent supported competency current', () {
    final now = DateTime(2026, 10, 3);
    final req = _req(
      id: 'pump',
      name: 'Pump Operations',
      category: 'Driver Operator',
      complete: true,
    );
    final mastery = DepartmentSkillMastery.fromJson({
      'settings': {
        'proficiencyThreshold': 80,
        'reassessmentDays': 180,
      },
      'skills': [
        {
          'skillId': 'pump-skill',
          'skillName': 'Pump Operations',
          'status': 'PROFICIENT',
          'stale': false,
          'trend': 'RETAINED',
          'latestScore': 91,
          'previousScore': 88,
          'latestResult': 'PASS',
          'lastEvaluatedAt': '2026-09-20T12:00:00.000Z',
          'observations': 3,
          'evaluatorName': 'Captain Example',
          'source': 'CLASS',
          'referenceTitle': 'Pump Skills',
        }
      ],
    });

    final map = CompetencyMapEngine.build(
      roadmap: _roadmap([req]),
      records: [
        _record(
          id: 'r1',
          title: 'Pump Operations practice',
          category: 'Driver Operator',
          date: now.subtract(const Duration(days: 4)),
          relatedRequirementId: 'pump',
        ),
      ],
      skillMastery: mastery,
      now: now,
    );

    expect(map.items, hasLength(1));
    expect(map.items.first.status, CompetencyFreshness.strong);
    expect(map.items.first.verifiedEvidenceCount, 1);
    expect(map.items.first.recentEvidenceCount, 2);
  });

  test('competency map marks old evidence stale and excludes health exposure logs', () {
    final now = DateTime(2026, 10, 3);
    final req = _req(
      id: 'hazmat',
      name: 'HazMat Operations',
      category: 'HazMat',
    );

    final map = CompetencyMapEngine.build(
      roadmap: _roadmap([req]),
      records: [
        _record(
          id: 'old',
          title: 'HazMat Operations drill',
          category: 'HazMat',
          date: now.subtract(const Duration(days: 250)),
          relatedRequirementId: 'hazmat',
        ),
        _record(
          id: 'exposure',
          title: 'HazMat / chemical',
          category: 'Exposure',
          date: now.subtract(const Duration(days: 1)),
          exposure: true,
        ),
      ],
      now: now,
    );

    expect(map.items.first.status, CompetencyFreshness.stale);
    expect(map.items.first.evidenceCount, 1);
  });

  test('competency map marks unsupported competency missing', () {
    final req = _req(
      id: 'leadership',
      name: 'Company Leadership',
      category: 'Leadership',
    );
    final map = CompetencyMapEngine.build(
      roadmap: _roadmap([req]),
      records: const [],
      now: DateTime(2026, 10, 3),
    );

    expect(map.items.first.status, CompetencyFreshness.missing);
    expect(map.items.first.nextFocus, contains('Company Leadership'));
  });
}
