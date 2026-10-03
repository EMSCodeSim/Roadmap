import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/competency_evidence_bridge.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/state/app_state.dart';

class GapEvidenceItem {
  final String title;
  final String detail;
  final bool verified;
  const GapEvidenceItem({required this.title, required this.detail, required this.verified});
}

class GapExplanation {
  final RoadmapRequirement item;
  final String whyItMatters;
  final List<GapEvidenceItem> evidence;
  final List<String> stillMissing;
  final String bestAction;
  final String actionLabel;
  final DepartmentSkillMasteryItem? mastery;
  const GapExplanation({
    required this.item,
    required this.whyItMatters,
    required this.evidence,
    required this.stillMissing,
    required this.bestAction,
    required this.actionLabel,
    required this.mastery,
  });
}

class GapExplanationEngine {
  GapExplanationEngine._();

  static GapExplanation explain({
    required AppState app,
    required RoadmapRequirement item,
    required List<CareerRecord> records,
    DepartmentSkillMastery? skillMastery,
  }) {
    final r = item.requirement;
    final linked = records.where((record) => record.relatedRequirementId == r.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final masteryMatches = (skillMastery?.skills ?? const <DepartmentSkillMasteryItem>[])
        .where((skill) => CompetencyEvidenceBridge.skillSupportsRequirement(skill.skillName, item))
        .toList()
      ..sort((a, b) => (b.lastEvaluatedAt ?? DateTime(1970)).compareTo(a.lastEvaluatedAt ?? DateTime(1970)));
    final mastery = masteryMatches.isEmpty ? null : masteryMatches.first;

    final evidence = <GapEvidenceItem>[
      ...linked.take(5).map((record) => GapEvidenceItem(
        title: record.title,
        detail: _recordDetail(record),
        verified: record.details['verification'] == 'department_verified' || record.tags.contains('department-verified'),
      )),
      if (mastery != null) GapEvidenceItem(
        title: mastery.skillName,
        detail: _masteryDetail(mastery),
        verified: true,
      ),
    ];

    final missing = _missing(app, item, linked, mastery);
    final action = _action(r, missing, mastery);
    return GapExplanation(
      item: item,
      whyItMatters: _why(r),
      evidence: evidence,
      stillMissing: missing,
      bestAction: action.$1,
      actionLabel: action.$2,
      mastery: mastery,
    );
  }

  static String _why(Requirement r) {
    if (r.priority == RequirementPriority.core) return 'This is a core requirement for your selected career goal.';
    if (r.priority == RequirementPriority.state) return 'This is a state-level requirement on your selected path.';
    if (r.requirementSource == RequirementSource.departmentRequirement || r.priority == RequirementPriority.department) {
      return 'This requirement depends on your department and may need department verification.';
    }
    if (r.type == RequirementType.taskBook) return 'This task book documents hands-on progression toward your selected role.';
    if (r.type == RequirementType.experience || r.type == RequirementType.numericProgress) {
      return 'This requirement depends on accumulating enough documented experience.';
    }
    return 'This requirement supports readiness for your selected career goal.';
  }

  static List<String> _missing(
    AppState app,
    RoadmapRequirement item,
    List<CareerRecord> linked,
    DepartmentSkillMasteryItem? mastery,
  ) {
    final r = item.requirement;
    final missing = <String>[];
    if (item.isComplete) return const <String>[];

    if (r.type == RequirementType.taskBook) {
      final road = app.roadmap;
      final progress = road == null ? null : app.taskBookProgressFor(goalId: road.goal.id, requirementId: r.id);
      if (progress != null && progress.$2 > 0) {
        final remaining = (progress.$2 - progress.$1).clamp(0, progress.$2);
        if (remaining > 0) missing.add(remaining.toString() + ' task-book item' + (remaining == 1 ? '' : 's') + ' remaining');
      } else {
        missing.add('Task-book completion is not yet documented');
      }
    }

    if ((r.type == RequirementType.numericProgress || r.type == RequirementType.experience) &&
        r.progressRequired != null && r.progressRequired! > 0) {
      final current = r.progressCurrent ?? 0;
      final remaining = (r.progressRequired! - current).clamp(0, r.progressRequired!).toDouble();
      if (remaining > 0) missing.add(_fmt(remaining) + ' ' + (r.progressUnit ?? 'units') + ' still needed');
    }

    if (r.type == RequirementType.certification) {
      missing.add('Current certification has not yet satisfied this requirement');
    }

    if (linked.isEmpty && r.type != RequirementType.certification && r.type != RequirementType.taskBook) {
      missing.add('No supporting personal evidence is linked yet');
    }

    if (mastery != null) {
      if (mastery.status == 'NEEDS_IMPROVEMENT') {
        missing.add(mastery.latestScore == null
            ? 'Latest department skill evaluation needs improvement'
            : 'Latest graded skill score is ' + mastery.latestScore!.round().toString() + '% and below the department proficiency standard');
      } else if (mastery.status == 'REASSESS') {
        missing.add('Department-verified skill evidence is due for reassessment');
      }
    } else if (r.type == RequirementType.practical || r.type == RequirementType.taskBook) {
      missing.add('No current department-verified skill evaluation is matched');
    }

    if (missing.isEmpty) missing.add('Final completion or verification is still required');
    return missing;
  }

  static (String, String) _action(Requirement r, List<String> missing, DepartmentSkillMasteryItem? mastery) {
    if (mastery?.status == 'NEEDS_IMPROVEMENT' || mastery?.status == 'REASSESS') {
      return ('Complete a current department skill reassessment for ' + mastery!.skillName + '.', 'Reassess skill');
    }
    switch (r.type) {
      case RequirementType.taskBook:
        return ('Complete the next unfinished task-book item and request evaluation when ready.', 'Open task book');
      case RequirementType.experience:
      case RequirementType.numericProgress:
        return ('Log the next relevant experience so Roadmap can update this requirement.', 'Log progress');
      case RequirementType.certification:
        return ('Add or update the certification that satisfies this requirement.', 'Update certificate');
      case RequirementType.practical:
        return ('Complete a practical skills evaluation and retain the evaluator result as evidence.', 'Complete evaluation');
      case RequirementType.trainingCourse:
      case RequirementType.course:
      case RequirementType.education:
        return ('Complete the required course and save the completion evidence.', 'Open requirement');
      case RequirementType.promotionalTest:
      case RequirementType.interview:
      case RequirementType.custom:
        return ('Open this requirement and complete the next missing item.', 'Open requirement');
    }
  }

  static String _recordDetail(CareerRecord record) {
    final verified = record.details['verification'] == 'department_verified' || record.tags.contains('department-verified');
    return record.date.month.toString() + '/' + record.date.day.toString() + '/' + record.date.year.toString() +
        (record.hours == null ? '' : ' · ' + record.hours!.toStringAsFixed(1) + ' hr') +
        ' · ' + (verified ? 'department verified' : 'personal evidence');
  }

  static String _masteryDetail(DepartmentSkillMasteryItem mastery) {
    return mastery.status.toLowerCase().replaceAll('_', ' ') +
        (mastery.latestScore == null ? '' : ' · ' + mastery.latestScore!.round().toString() + '%') +
        ' · ' + mastery.trend.toLowerCase().replaceAll('_', ' ') +
        (mastery.lastEvaluatedAt == null ? '' : ' · ' + mastery.lastEvaluatedAt!.month.toString() + '/' + mastery.lastEvaluatedAt!.day.toString() + '/' + mastery.lastEvaluatedAt!.year.toString()) +
        ' · department verified';
  }

  static String _fmt(double value) => value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
}
