import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/competency_evidence_bridge.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

enum CompetencyFreshness { strong, current, developing, stale, missing }

class CompetencyEvidenceSummary {
  final String title;
  final String detail;
  final DateTime date;
  final bool verified;
  const CompetencyEvidenceSummary({
    required this.title,
    required this.detail,
    required this.date,
    required this.verified,
  });
}

class CompetencyMapItem {
  final String id;
  final String name;
  final CompetencyFreshness status;
  final int completedRequirements;
  final int totalRequirements;
  final int evidenceCount;
  final int recentEvidenceCount;
  final int verifiedEvidenceCount;
  final DateTime? latestEvidenceAt;
  final List<RoadmapRequirement> requirements;
  final List<CompetencyEvidenceSummary> evidence;
  final List<DepartmentSkillMasteryItem> mastery;
  final String nextFocus;

  const CompetencyMapItem({
    required this.id,
    required this.name,
    required this.status,
    required this.completedRequirements,
    required this.totalRequirements,
    required this.evidenceCount,
    required this.recentEvidenceCount,
    required this.verifiedEvidenceCount,
    required this.latestEvidenceAt,
    required this.requirements,
    required this.evidence,
    required this.mastery,
    required this.nextFocus,
  });

  double get requirementProgress =>
      totalRequirements == 0 ? 0 : completedRequirements / totalRequirements;

  String get statusLabel => switch (status) {
        CompetencyFreshness.strong => 'Strong',
        CompetencyFreshness.current => 'Current',
        CompetencyFreshness.developing => 'Developing',
        CompetencyFreshness.stale => 'Stale',
        CompetencyFreshness.missing => 'Missing',
      };
}

class CompetencyMap {
  final String goalTitle;
  final int freshnessDays;
  final List<CompetencyMapItem> items;

  const CompetencyMap({
    required this.goalTitle,
    required this.freshnessDays,
    required this.items,
  });

  int count(CompetencyFreshness status) =>
      items.where((item) => item.status == status).length;
}

class CompetencyMapEngine {
  CompetencyMapEngine._();

  static CompetencyMap build({
    required Roadmap roadmap,
    required List<CareerRecord> records,
    DepartmentSkillMastery? skillMastery,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final freshnessDays = skillMastery?.reassessmentDays ?? 180;
    final freshCutoff = clock.subtract(Duration(days: freshnessDays));

    final grouped = <String, List<RoadmapRequirement>>{};
    final display = <String, String>{};

    for (final item in roadmap.included) {
      final category = item.requirement.category.trim().isEmpty
          ? 'General'
          : item.requirement.category.trim();
      final key = _normalize(category);
      (grouped[key] ??= <RoadmapRequirement>[]).add(item);
      display.putIfAbsent(key, () => category);
    }

    final result = <CompetencyMapItem>[];

    for (final entry in grouped.entries) {
      final requirements = entry.value;
      final competencyName = display[entry.key] ?? 'General';
      final requirementIds =
          requirements.map((item) => item.requirement.id).toSet();

      final matchingRecords = records.where((record) {
        if (record.details['possibleHealthExposure'] == true) return false;
        if (record.relatedRequirementId != null &&
            requirementIds.contains(record.relatedRequirementId)) {
          return true;
        }
        if (record.relatedGoalId != null &&
            record.relatedGoalId != roadmap.goal.id) {
          return false;
        }
        return _recordMatchesCompetency(record, competencyName, requirements);
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final matchingMastery = (skillMastery?.skills ??
              const <DepartmentSkillMasteryItem>[])
          .where((skill) => requirements.any(
                (item) => CompetencyEvidenceBridge.skillSupportsRequirement(
                  skill.skillName,
                  item,
                ),
              ))
          .toList()
        ..sort((a, b) => (b.lastEvaluatedAt ?? DateTime(1970))
            .compareTo(a.lastEvaluatedAt ?? DateTime(1970)));

      final recentRecords = matchingRecords
          .where((record) => !record.date.isBefore(freshCutoff))
          .toList();
      final recentMastery = matchingMastery
          .where((skill) =>
              skill.lastEvaluatedAt != null &&
              !skill.lastEvaluatedAt!.isBefore(freshCutoff))
          .toList();

      final completed =
          requirements.where((item) => item.isComplete).length;
      final verifiedRecords = matchingRecords.where((record) =>
          record.details['verification'] == 'department_verified' ||
          record.tags.contains('department-verified'));
      final currentMastery = matchingMastery
          .where((skill) => skill.status == 'PROFICIENT')
          .toList();
      final needsImprovement = matchingMastery
          .any((skill) => skill.status == 'NEEDS_IMPROVEMENT');
      final staleMastery =
          matchingMastery.any((skill) => skill.status == 'REASSESS');

      final allEvidenceDates = <DateTime>[
        ...matchingRecords.map((record) => record.date),
        ...matchingMastery
            .map((skill) => skill.lastEvaluatedAt)
            .whereType<DateTime>(),
      ]..sort((a, b) => b.compareTo(a));
      final latestEvidence =
          allEvidenceDates.isEmpty ? null : allEvidenceDates.first;

      final evidenceCount = matchingRecords.length + matchingMastery.length;
      final recentCount = recentRecords.length + recentMastery.length;
      final verifiedCount = verifiedRecords.length + matchingMastery.length;

      final status = _status(
        completed: completed,
        total: requirements.length,
        evidenceCount: evidenceCount,
        recentEvidenceCount: recentCount,
        currentMasteryCount: currentMastery.length,
        needsImprovement: needsImprovement,
        staleMastery: staleMastery,
        latestEvidence: latestEvidence,
        freshCutoff: freshCutoff,
      );

      final evidence = <CompetencyEvidenceSummary>[
        ...matchingMastery.map((skill) => CompetencyEvidenceSummary(
              title: skill.skillName,
              detail: _masteryDetail(skill),
              date: skill.lastEvaluatedAt ?? DateTime(1970),
              verified: true,
            )),
        ...matchingRecords.map((record) => CompetencyEvidenceSummary(
              title: record.title,
              detail: _recordDetail(record),
              date: record.date,
              verified: record.details['verification'] ==
                      'department_verified' ||
                  record.tags.contains('department-verified'),
            )),
      ]..sort((a, b) => b.date.compareTo(a.date));

      result.add(
        CompetencyMapItem(
          id: entry.key,
          name: competencyName,
          status: status,
          completedRequirements: completed,
          totalRequirements: requirements.length,
          evidenceCount: evidenceCount,
          recentEvidenceCount: recentCount,
          verifiedEvidenceCount: verifiedCount,
          latestEvidenceAt: latestEvidence,
          requirements: requirements,
          evidence: evidence.take(20).toList(growable: false),
          mastery: matchingMastery,
          nextFocus: _nextFocus(
            requirements: requirements,
            status: status,
            needsImprovement: needsImprovement,
            staleMastery: staleMastery,
          ),
        ),
      );
    }

    result.sort((a, b) {
      int rank(CompetencyFreshness status) => switch (status) {
            CompetencyFreshness.missing => 0,
            CompetencyFreshness.stale => 1,
            CompetencyFreshness.developing => 2,
            CompetencyFreshness.current => 3,
            CompetencyFreshness.strong => 4,
          };
      final byStatus = rank(a.status).compareTo(rank(b.status));
      if (byStatus != 0) return byStatus;
      return a.name.compareTo(b.name);
    });

    return CompetencyMap(
      goalTitle: roadmap.goal.title,
      freshnessDays: freshnessDays,
      items: result,
    );
  }

  static CompetencyFreshness _status({
    required int completed,
    required int total,
    required int evidenceCount,
    required int recentEvidenceCount,
    required int currentMasteryCount,
    required bool needsImprovement,
    required bool staleMastery,
    required DateTime? latestEvidence,
    required DateTime freshCutoff,
  }) {
    if (needsImprovement) return CompetencyFreshness.developing;
    if (staleMastery ||
        (latestEvidence != null && latestEvidence.isBefore(freshCutoff))) {
      return CompetencyFreshness.stale;
    }
    if (evidenceCount == 0) return CompetencyFreshness.missing;
    if (completed == total &&
        total > 0 &&
        recentEvidenceCount >= 2 &&
        currentMasteryCount > 0) {
      return CompetencyFreshness.strong;
    }
    if (recentEvidenceCount > 0 &&
        (completed == total || currentMasteryCount > 0)) {
      return CompetencyFreshness.current;
    }
    return CompetencyFreshness.developing;
  }

  static String _nextFocus({
    required List<RoadmapRequirement> requirements,
    required CompetencyFreshness status,
    required bool needsImprovement,
    required bool staleMastery,
  }) {
    if (needsImprovement) {
      return 'Rebuild proficiency with another evaluated practice or reassessment.';
    }
    if (staleMastery || status == CompetencyFreshness.stale) {
      return 'Refresh this competency with current practice or a new evaluation.';
    }
    final unfinished =
        requirements.where((item) => !item.isComplete).toList(growable: false);
    if (unfinished.isNotEmpty) {
      return 'Complete ${unfinished.first.requirement.name}.';
    }
    if (status == CompetencyFreshness.missing) {
      return 'Add current evidence that demonstrates this competency.';
    }
    if (status == CompetencyFreshness.developing) {
      return 'Add another meaningful observation, practice record, or verified evaluation.';
    }
    return 'Maintain this competency with periodic evidence and reassessment.';
  }

  static bool _recordMatchesCompetency(
    CareerRecord record,
    String competencyName,
    List<RoadmapRequirement> requirements,
  ) {
    final recordText = _normalize([
      record.title,
      record.category,
      record.summary ?? '',
      record.impact ?? '',
      ...record.tags,
    ].join(' '));
    final competency = _normalize(competencyName);
    if (competency.isNotEmpty && recordText.contains(competency)) return true;
    return requirements.any((item) {
      final name = _normalize(item.requirement.name);
      if (name.isNotEmpty && recordText.contains(name)) return true;
      final keys = CompetencyEvidenceBridge.keysForRequirement(item);
      return keys.any((key) => key.length >= 4 && recordText.contains(key));
    });
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  static String _recordDetail(CareerRecord record) {
    final verified = record.details['verification'] == 'department_verified' ||
        record.tags.contains('department-verified');
    final parts = <String>[
      '${record.date.month}/${record.date.day}/${record.date.year}',
      if (record.hours != null) '${record.hours!.toStringAsFixed(1)} hr',
      verified ? 'department verified' : 'personal evidence',
    ];
    return parts.join(' · ');
  }

  static String _masteryDetail(DepartmentSkillMasteryItem skill) {
    final parts = <String>[
      skill.status.toLowerCase().replaceAll('_', ' '),
      if (skill.latestScore != null) '${skill.latestScore!.round()}%',
      skill.trend.toLowerCase().replaceAll('_', ' '),
      'department verified',
    ];
    return parts.join(' · ');
  }
}
