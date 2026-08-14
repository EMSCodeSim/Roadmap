import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/state/app_state.dart';

class GoalReadinessPreview {
  final CareerGoal goal;
  final int completed;
  final int total;
  final int score;

  const GoalReadinessPreview({
    required this.goal,
    required this.completed,
    required this.total,
    required this.score,
  });
}

class SkillRefreshAlert {
  final String name;
  final DateTime lastDocumented;
  final int documentedCount;
  final int daysSince;

  const SkillRefreshAlert({
    required this.name,
    required this.lastDocumented,
    required this.documentedCount,
    required this.daysSince,
  });
}

class YearComparison {
  final int currentYear;
  final int previousYear;
  final int currentRecords;
  final int previousRecords;
  final double currentHours;
  final double previousHours;
  final int currentLeadership;
  final int previousLeadership;

  const YearComparison({
    required this.currentYear,
    required this.previousYear,
    required this.currentRecords,
    required this.previousRecords,
    required this.currentHours,
    required this.previousHours,
    required this.currentLeadership,
    required this.previousLeadership,
  });
}

class ArchivedCareerPath {
  final String goalId;
  final String title;
  final int linkedRecords;
  final int completedOverrides;
  final int trackedOverrides;
  final DateTime? lastActivity;

  const ArchivedCareerPath({
    required this.goalId,
    required this.title,
    required this.linkedRecords,
    required this.completedOverrides,
    required this.trackedOverrides,
    required this.lastActivity,
  });

  int get percent => trackedOverrides <= 0
      ? 0
      : ((completedOverrides / trackedOverrides) * 100).round();
}

class CareerLongevity {
  const CareerLongevity._();

  static List<GoalReadinessPreview> readinessAcrossGoals({
    required AppState app,
    required List<CareerRecord> records,
  }) {
    final currentCertIds = app.certifications
        .where((c) => c.status != CertificationStatus.expired)
        .map(
          (c) =>
              c.certificationDefinitionId ??
              FireOpsCatalog.matchCertificationDefinitionId(c.name),
        )
        .whereType<String>()
        .toSet();

    bool requirementSatisfied(Requirement r) {
      if (r.certificationDefinitionId != null)
        return currentCertIds.contains(r.certificationDefinitionId);
      if (r.type == RequirementType.experience ||
          r.type == RequirementType.numericProgress ||
          r.type == RequirementType.taskBook) {
        return records.any(
          (record) =>
              record.relatedRequirementId == r.id ||
              record.tags.any(
                (tag) => tag.toLowerCase().contains(r.name.toLowerCase()),
              ),
        );
      }
      return false;
    }

    final previews = FireOpsCatalog.goals().map((goal) {
      final required = goal.requirements
          .where((r) => r.defaultRequired)
          .toList();
      final completed = required.where(requirementSatisfied).length;
      final score = required.isEmpty
          ? 0
          : ((completed / required.length) * 100).round();
      return GoalReadinessPreview(
        goal: goal,
        completed: completed,
        total: required.length,
        score: score,
      );
    }).toList()..sort((a, b) => b.score.compareTo(a.score));
    return previews;
  }

  static YearComparison compareYears(List<CareerRecord> records, {int? year}) {
    final current = year ?? DateTime.now().year;
    final previous = current - 1;
    final currentItems = records.where((e) => e.date.year == current).toList();
    final previousItems = records
        .where((e) => e.date.year == previous)
        .toList();
    double hours(List<CareerRecord> items) =>
        items.fold(0, (sum, item) => sum + (item.hours ?? 0));
    int leadership(List<CareerRecord> items) => items
        .where(
          (e) =>
              e.type == CareerRecordType.leadership ||
              e.type == CareerRecordType.teaching ||
              e.type == CareerRecordType.project,
        )
        .length;
    return YearComparison(
      currentYear: current,
      previousYear: previous,
      currentRecords: currentItems.length,
      previousRecords: previousItems.length,
      currentHours: hours(currentItems),
      previousHours: hours(previousItems),
      currentLeadership: leadership(currentItems),
      previousLeadership: leadership(previousItems),
    );
  }

  static List<SkillRefreshAlert> skillRefreshAlerts(
    List<CareerRecord> records, {
    int staleDays = 365,
  }) {
    final grouped = <String, List<CareerRecord>>{};
    for (final record in records.where(
      (e) => e.type == CareerRecordType.skill,
    )) {
      final key = (record.trackingKey ?? record.title).trim();
      if (key.isEmpty) continue;
      (grouped[key] ??= []).add(record);
    }
    final now = DateTime.now();
    final alerts = <SkillRefreshAlert>[];
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => b.date.compareTo(a.date));
      final last = entry.value.first.date;
      final days = now.difference(last).inDays;
      if (days >= staleDays) {
        alerts.add(
          SkillRefreshAlert(
            name: entry.value.first.title,
            lastDocumented: last,
            documentedCount: entry.value.length,
            daysSince: days,
          ),
        );
      }
    }
    alerts.sort((a, b) => b.daysSince.compareTo(a.daysSince));
    return alerts;
  }

  static List<ArchivedCareerPath> archivedPaths({
    required AppState app,
    required List<CareerRecord> records,
  }) {
    final active = app.selectedGoal?.id;
    final goals = {for (final g in FireOpsCatalog.goals()) g.id: g.title};
    final ids = <String>{
      ...records.map((e) => e.relatedGoalId).whereType<String>(),
      ...app.pathOverrides.map((e) => e.goalId),
    }..removeWhere((id) => id.isEmpty || id == active);

    final result =
        ids.map((id) {
          final linked = records.where((e) => e.relatedGoalId == id).toList();
          final overrides = app.pathOverrides
              .where((e) => e.goalId == id)
              .toList();
          final completed = overrides
              .where(
                (e) =>
                    e.completed == true ||
                    ((e.taskBookTotalItems ?? 0) > 0 &&
                        e.taskBookCompletedItems == e.taskBookTotalItems),
              )
              .length;
          linked.sort((a, b) => b.date.compareTo(a.date));
          return ArchivedCareerPath(
            goalId: id,
            title:
                goals[id] ?? (id.startsWith('custom:') ? id.substring(7) : id),
            linkedRecords: linked.length,
            completedOverrides: completed,
            trackedOverrides: overrides.length,
            lastActivity: linked.isEmpty ? null : linked.first.date,
          );
        }).toList()..sort(
          (a, b) => (b.lastActivity ?? DateTime(1900)).compareTo(
            a.lastActivity ?? DateTime(1900),
          ),
        );
    return result;
  }

  static String buildStarStory(CareerRecord record) {
    final situation = (record.summary ?? '').trim();
    final role = (record.roleOrAssignment ?? '').trim();
    final result = (record.impact ?? '').trim();
    return [
      'STAR INTERVIEW STORY — ${record.title}',
      '',
      'SITUATION',
      situation.isEmpty
          ? 'Add the context: what was happening and why did it matter?'
          : situation,
      '',
      'TASK',
      role.isEmpty
          ? 'Add your responsibility or assignment in this situation.'
          : 'My role/responsibility: $role',
      '',
      'ACTION',
      situation.isEmpty ? 'Describe the specific actions you personally took.' : 'Refine the situation notes above into the specific actions you personally took. Focus on decisions, communication, and leadership behaviors.',
      '',
      'RESULT',
      result.isEmpty
          ? 'Add the measurable result, outcome, or lesson learned.'
          : result,
      '',
      'INTERVIEW CLOSE',
      'Explain what you learned and how this experience would influence how you perform in the position you are seeking.',
    ].join('\n');
  }

  static String buildResumePacket({
    required AppState app,
    required List<CareerRecord> records,
  }) {
    final buffer = StringBuffer();
    final roles = app.profile.currentRoles.join(' / ');
    final highlights =
        records
            .where(
              (e) =>
                  e.highlight ||
                  e.type == CareerRecordType.achievement ||
                  e.type == CareerRecordType.project,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final leadership = records
        .where(
          (e) =>
              e.type == CareerRecordType.leadership ||
              e.type == CareerRecordType.teaching,
        )
        .toList();
    final trainingHours = records
        .where((e) => e.type == CareerRecordType.training)
        .fold<double>(0, (s, e) => s + (e.hours ?? 0));

    buffer.writeln('CAREER RESUME / PROMOTION PACKET');
    buffer.writeln('Generated by FireOps Career Road');
    buffer.writeln();
    buffer.writeln('PROFESSIONAL PROFILE');
    buffer.writeln(
      '- Current role(s): ${roles.isEmpty ? 'Not recorded' : roles}',
    );
    buffer.writeln(
      '- Career goal: ${app.selectedGoal?.title ?? 'Not selected'}',
    );
    if (app.profile.yearsOfService != null)
      buffer.writeln('- Years of service: ${app.profile.yearsOfService}');
    buffer.writeln('- Documented career activities: ${records.length}');
    if (trainingHours > 0)
      buffer.writeln(
        '- Documented training hours: ${trainingHours.toStringAsFixed(1)}',
      );
    buffer.writeln();

    buffer.writeln('CURRENT CREDENTIALS');
    final certs = app.certifications
        .where((c) => c.status != CertificationStatus.expired)
        .toList();
    for (final cert in certs) {
      buffer.writeln('- ${app.certificationDisplayName(cert)}');
    }
    if (certs.isEmpty) buffer.writeln('- No current credentials recorded.');
    buffer.writeln();

    buffer.writeln('SELECTED CAREER HIGHLIGHTS');
    for (final item in highlights.take(10)) {
      final impact = (item.impact ?? '').trim();
      buffer.writeln('- ${item.title}${impact.isEmpty ? '' : ' — $impact'}');
    }
    if (highlights.isEmpty)
      buffer.writeln(
        '- Mark achievements, leadership examples, and projects as highlights to populate this section.',
      );
    buffer.writeln();

    buffer.writeln('LEADERSHIP / TEACHING EVIDENCE');
    for (final item in leadership.take(8)) {
      buffer.writeln(
        '- ${item.title}${(item.impact ?? '').trim().isEmpty ? '' : ' — ${item.impact!.trim()}'}',
      );
    }
    if (leadership.isEmpty)
      buffer.writeln('- No leadership or teaching examples recorded yet.');
    buffer.writeln();

    buffer.writeln(
      'Use this packet as source material for a tailored resume or promotional submission. Verify official dates, titles, credentials, and employment details before submitting.',
    );
    return buffer.toString().trim();
  }
}
