import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

class CompetencyMatch {
  final RoadmapRequirement item;
  final Set<String> sharedKeys;

  const CompetencyMatch({required this.item, required this.sharedKeys});
}

class CompetencyEvidenceBridge {
  static const Map<String, Set<String>> _synonyms = {
    'pump': {'pump', 'pumping', 'pump operator', 'pump operations', 'engineer'},
    'driver': {'driver', 'driver operator', 'apparatus operator', 'engineer'},
    'scba': {'scba', 'self contained breathing apparatus', 'air pack'},
    'mayday': {'mayday', 'firefighter survival', 'rapid intervention'},
    'patient assessment': {'patient assessment', 'assessment', 'medical assessment'},
    'airway': {'airway', 'ventilation', 'oxygenation'},
    'leadership': {'leadership', 'officer', 'company officer', 'supervision'},
    'hazmat': {'hazmat', 'hazardous materials'},
    'ems': {'ems', 'emergency medical', 'medical'},
    'instructor': {'instructor', 'teaching', 'education'},
  };

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  static Set<String> _keysForText(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return <String>{};
    final keys = <String>{normalized};
    final words = normalized.split(' ').where((w) => w.length > 2).toSet();
    keys.addAll(words);

    for (final entry in _synonyms.entries) {
      if (entry.value.any((term) => normalized.contains(term))) {
        keys.add(entry.key);
      }
    }
    return keys;
  }

  static Set<String> keysForRequirement(RoadmapRequirement item) {
    final r = item.requirement;
    return <String>{
      ..._keysForText(r.name),
      ..._keysForText(r.category),
      ..._keysForText(r.certificationReference ?? ''),
    };
  }

  static Set<String> keysForAssignment(DepartmentTaskBookAssignment assignment) {
    return <String>{
      ..._keysForText(assignment.taskBookTitle),
      ..._keysForText(assignment.category),
      ...assignment.sections
          .expand((section) => section.requirements)
          .expand((requirement) => _keysForText(requirement.title)),
    };
  }

  static CompetencyMatch? matchAssignment(
    DepartmentTaskBookAssignment assignment,
    Roadmap? roadmap,
  ) {
    if (roadmap == null) return null;
    final assignmentKeys = keysForAssignment(assignment);
    if (assignmentKeys.isEmpty) return null;

    CompetencyMatch? best;
    var bestScore = 0;

    for (final item in roadmap.included) {
      final requirementKeys = keysForRequirement(item);
      final shared = assignmentKeys.intersection(requirementKeys);
      if (shared.isEmpty) continue;

      var score = shared.length;
      final assignmentTitle = _normalize(assignment.taskBookTitle);
      final requirementName = _normalize(item.requirement.name);
      if (assignmentTitle == requirementName) score += 6;
      if (assignmentTitle.contains(requirementName) ||
          requirementName.contains(assignmentTitle)) {
        score += 3;
      }
      if (item.requirement.type.name == 'taskBook') score += 2;

      if (score > bestScore) {
        bestScore = score;
        best = CompetencyMatch(item: item, sharedKeys: shared);
      }
    }

    return bestScore >= 2 ? best : null;
  }

  static String trackingKeyForAssignment(String assignmentId) =>
      'department-assignment:$assignmentId';

  static bool isImported(
    Iterable<CareerRecord> records,
    DepartmentTaskBookAssignment assignment,
  ) {
    final key = trackingKeyForAssignment(assignment.id);
    return records.any((record) => record.trackingKey == key);
  }

  static CareerRecord toVerifiedCareerRecord({
    required DepartmentTaskBookAssignment assignment,
    required String departmentName,
    required String? relatedGoalId,
    CompetencyMatch? match,
  }) {
    final now = DateTime.now();
    return CareerRecord(
      id: 'dept-${assignment.id}',
      type: CareerRecordType.taskBookEvidence,
      title: assignment.taskBookTitle,
      category: assignment.category.isEmpty
          ? 'Department training'
          : assignment.category,
      date: assignment.dueDate ?? assignment.assignedDate ?? now,
      roleOrAssignment: 'Department verified',
      summary: 'Completed department-assigned training in Responder Roadmap.',
      impact: match == null
          ? null
          : 'Also supports ${match.item.requirement.name} on your personal roadmap.',
      evidenceReference: assignment.id,
      hours: null,
      repetitions: 1,
      tags: <String>[
        'department-verified',
        ...keysForAssignment(assignment)
            .where((key) => key.contains(' ') || _synonyms.containsKey(key))
            .take(8),
      ],
      relatedGoalId: relatedGoalId,
      relatedRequirementId: match?.item.requirement.id,
      relatedTaskId: assignment.id,
      highlight: true,
      trackingKey: trackingKeyForAssignment(assignment.id),
      outcome: CareerRecordOutcome.completed,
      details: <String, dynamic>{
        'source': 'department',
        'verification': 'department_verified',
        'departmentName': departmentName,
        'assignmentId': assignment.id,
        'assignmentKind': assignment.assignmentKind,
        'version': assignment.version,
        'competencyKeys': keysForAssignment(assignment).toList()..sort(),
      },
      createdAt: now,
      updatedAt: now,
    );
  }
}
