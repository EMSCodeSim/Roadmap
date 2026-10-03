import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/competency_evidence_bridge.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/state/app_state.dart';

enum CareerCoachKind {
  skillReassessment,
  skillImprovement,
  evidenceSuggestion,
  momentum,
}

class CareerCoachPrompt {
  final String id;
  final CareerCoachKind kind;
  final int priority;
  final String title;
  final String detail;
  final String why;
  final String actionLabel;
  final String? recordId;
  final RoadmapRequirement? requirement;
  final DepartmentSkillMasteryItem? mastery;

  const CareerCoachPrompt({
    required this.id,
    required this.kind,
    required this.priority,
    required this.title,
    required this.detail,
    required this.why,
    required this.actionLabel,
    this.recordId,
    this.requirement,
    this.mastery,
  });
}

class CareerCoachEngine {
  CareerCoachEngine._();

  static List<CareerCoachPrompt> build({
    required AppState app,
    required List<CareerRecord> records,
    DepartmentSkillMastery? skillMastery,
    DateTime? now,
  }) {
    final roadmap = app.roadmap;
    if (roadmap == null) return const <CareerCoachPrompt>[];
    final clock = now ?? DateTime.now();
    final prompts = <CareerCoachPrompt>[];

    for (final mastery in skillMastery?.skills ?? const <DepartmentSkillMasteryItem>[]) {
      final matches = roadmap.included.where(
        (item) => CompetencyEvidenceBridge.skillSupportsRequirement(
          mastery.skillName,
          item,
        ),
      );
      if (matches.isEmpty) continue;
      final requirement = matches.first;

      if (mastery.status == 'NEEDS_IMPROVEMENT') {
        prompts.add(
          CareerCoachPrompt(
            id: 'skill-improve:${mastery.skillId}',
            kind: CareerCoachKind.skillImprovement,
            priority: 0,
            title: 'Strengthen ${mastery.skillName}',
            detail: mastery.latestScore == null
                ? 'Your latest department evaluation needs improvement.'
                : 'Your latest department score was ${mastery.latestScore!.round()}%.',
            why: 'This skill supports ${requirement.requirement.name} on your ${roadmap.goal.title} roadmap.',
            actionLabel: 'Open Department',
            requirement: requirement,
            mastery: mastery,
          ),
        );
      } else if (mastery.status == 'REASSESS') {
        final date = mastery.lastEvaluatedAt;
        final age = date == null ? null : clock.difference(date).inDays;
        prompts.add(
          CareerCoachPrompt(
            id: 'skill-reassess:${mastery.skillId}',
            kind: CareerCoachKind.skillReassessment,
            priority: 1,
            title: 'Reassess ${mastery.skillName}',
            detail: age == null
                ? 'This department-verified skill is due for reassessment.'
                : 'Your last department evaluation was $age days ago.',
            why: 'Your department reassessment interval has passed, so Roadmap no longer treats this as current mastery evidence.',
            actionLabel: 'Open Department',
            requirement: requirement,
            mastery: mastery,
          ),
        );
      }
    }

    final cutoff = clock.subtract(const Duration(days: 45));
    final unlinked = records
        .where((record) =>
            !record.date.isBefore(cutoff) &&
            record.relatedRequirementId == null &&
            record.relatedGoalId == null &&
            record.details['possibleHealthExposure'] != true)
        .toList();

    for (final record in unlinked) {
      final match = _bestRequirementMatch(record, roadmap.included);
      if (match == null) continue;
      prompts.add(
        CareerCoachPrompt(
          id: 'evidence:${record.id}:${match.requirement.id}',
          kind: CareerCoachKind.evidenceSuggestion,
          priority: 2,
          title: 'This may support ${match.requirement.name}',
          detail: '${record.title} is not linked to your active roadmap yet.',
          why: 'The activity and requirement share the same competency area. Linking it preserves the evidence without changing its original record.',
          actionLabel: 'Add to roadmap',
          recordId: record.id,
          requirement: match,
        ),
      );
    }

    prompts.sort((a, b) => a.priority.compareTo(b.priority));
    return prompts.take(3).toList(growable: false);
  }

  static RoadmapRequirement? _bestRequirementMatch(
    CareerRecord record,
    List<RoadmapRequirement> requirements,
  ) {
    final recordTokens = _tokens([
      record.title,
      record.category,
      record.summary ?? '',
      record.impact ?? '',
      ...record.tags,
    ].join(' '));
    if (recordTokens.isEmpty) return null;

    RoadmapRequirement? best;
    var bestScore = 0;
    for (final item in requirements.where((item) => !item.isComplete)) {
      final requirement = item.requirement;
      final requirementTokens = _tokens(
        '${requirement.name} ${requirement.category} ${requirement.description}',
      );
      final overlap = recordTokens.intersection(requirementTokens).length;
      var score = overlap;
      if (record.category.toLowerCase() == requirement.category.toLowerCase()) {
        score += 2;
      }
      if (record.type.name.toLowerCase().contains(requirement.type.name.toLowerCase()) ||
          requirement.type.name.toLowerCase().contains(record.type.name.toLowerCase())) {
        score += 1;
      }
      if (score > bestScore) {
        best = item;
        bestScore = score;
      }
    }
    return bestScore >= 2 ? best : null;
  }

  static Set<String> _tokens(String value) {
    const stop = <String>{
      'this','that','with','from','your','into','over','under','training',
      'activity','personal','department','quick','class','call','skill',
    };
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .split(' ')
        .where((word) => word.length >= 4 && !stop.contains(word))
        .toSet();
  }
}
