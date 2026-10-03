import 'package:flutter/material.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/advancement_analyzer.dart';
import 'package:firepath/services/career_progress_history.dart';
import 'package:firepath/services/career_coach.dart';
import 'package:firepath/services/career_coach_preferences.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/gap_explanation.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/state/app_state.dart';

class CareerPulseCard extends StatefulWidget {
  final AppState app;
  final ValueChanged<AdvancementAnalysis> onPrimaryAction;
  final VoidCallback onOpenAdvance;
  final VoidCallback onOpenCompetencyMap;
  final ValueChanged<GapExplanation> onGapAction;
  final VoidCallback onOpenDepartment;
  final ValueChanged<RoadmapRequirement> onOpenRequirement;

  const CareerPulseCard({
    super.key,
    required this.app,
    required this.onPrimaryAction,
    required this.onOpenAdvance,
    required this.onOpenCompetencyMap,
    required this.onGapAction,
    required this.onOpenDepartment,
    required this.onOpenRequirement,
  });

  @override
  State<CareerPulseCard> createState() => _CareerPulseCardState();
}

class _CareerPulseCardState extends State<CareerPulseCard> {
  final CareerRecordStore _recordsStore = CareerRecordStore();
  final CareerProgressHistoryStore _historyStore = CareerProgressHistoryStore();
  final ResponderRoadmapApi _api = ResponderRoadmapApi();
  final CareerCoachPreferences _coachPreferences = CareerCoachPreferences();
  List<CareerRecord> _records = const [];
  CareerProgressTrend? _trend;
  DepartmentSkillMastery? _skillMastery;
  List<CareerCoachPrompt> _coachPrompts = const [];
  bool _loading = true;
  String? _goalId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CareerPulseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextGoal = widget.app.selectedGoal?.id;
    if (_goalId != nextGoal ||
        oldWidget.app.roadmap?.completedCount !=
            widget.app.roadmap?.completedCount) {
      _load();
    }
  }

  Future<void> _load() async {
    final records = await _recordsStore.load();
    DepartmentSkillMastery? skillMastery;
    try {
      if (await _api.hasStoredToken) skillMastery = await _api.getMySkillMastery();
    } catch (_) {
      // Department mastery is supplemental; Home remains useful offline.
    }
    final analysis =
        AdvancementAnalyzer.analyze(app: widget.app, records: records);
    final dismissed = await _coachPreferences.loadDismissed();
    final coachPrompts = CareerCoachEngine.build(
      app: widget.app,
      records: records,
      skillMastery: skillMastery,
    ).where((prompt) => !dismissed.containsKey(prompt.id)).toList();
    final goalId = widget.app.selectedGoal?.id;
    CareerProgressTrend? trend;
    if (goalId != null) {
      trend = await _historyStore.record(
        current: CareerProgressPoint(
          capturedAt: DateTime.now(),
          goalId: goalId,
          readinessScore: analysis.readinessScore,
          completedRequirements: analysis.completedRequirements,
          totalRequirements: analysis.totalRequirements,
          evidenceCovered: analysis.evidenceCovered,
          evidenceExpected: analysis.evidenceExpected,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _records = records;
      _trend = trend;
      _skillMastery = skillMastery;
      _coachPrompts = coachPrompts;
      _goalId = goalId;
      _loading = false;
    });
  }

  Future<void> _dismissCoach(CareerCoachPrompt prompt) async {
    await _coachPreferences.dismiss(prompt.id);
    if (!mounted) return;
    setState(() {
      _coachPrompts =
          _coachPrompts.where((item) => item.id != prompt.id).toList();
    });
  }

  Future<void> _actOnCoach(CareerCoachPrompt prompt) async {
    if (prompt.kind == CareerCoachKind.competencyGap) {
      widget.onOpenCompetencyMap();
      return;
    }
    if (prompt.kind == CareerCoachKind.skillReassessment ||
        prompt.kind == CareerCoachKind.skillImprovement) {
      widget.onOpenDepartment();
      return;
    }
    if (prompt.kind == CareerCoachKind.evidenceSuggestion &&
        prompt.recordId != null &&
        prompt.requirement != null) {
      final matches = _records.where((record) => record.id == prompt.recordId);
      if (matches.isEmpty) return;
      final record = matches.first;
      final goalId = widget.app.roadmap?.goal.id;
      if (goalId == null) return;
      final updated = record.copyWith(
        relatedGoalId: goalId,
        relatedRequirementId: prompt.requirement!.requirement.id,
        details: {
          ...record.details,
          'linkedByCareerCoach': true,
          'linkedAt': DateTime.now().toIso8601String(),
        },
        updatedAt: DateTime.now(),
      );
      final saved = await _recordsStore.upsert(updated);
      if (!saved || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${record.title} now supports ${prompt.requirement!.requirement.name}.',
          ),
        ),
      );
      await _load();
      return;
    }
    if (prompt.requirement != null) {
      widget.onOpenRequirement(prompt.requirement!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.app.selectedGoal;
    if (goal == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final analysis =
        AdvancementAnalyzer.analyze(app: widget.app, records: _records);
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent =
        _records.where((record) => !record.date.isBefore(cutoff)).toList();
    final recentHours = recent.fold<double>(
      0,
      (sum, record) => sum + (record.hours ?? 0),
    );
    final verified = _records.where((record) {
      return record.details['verification'] == 'department_verified' ||
          record.tags.contains('department-verified');
    }).length;
    GapExplanation? gap;
    final recommendationId = analysis.recommendation.requirementId;
    final roadmap = widget.app.roadmap;
    if (recommendationId != null && roadmap != null) {
      final matches = roadmap.included.where(
        (item) => item.requirement.id == recommendationId,
      );
      if (matches.isNotEmpty) {
        gap = GapExplanationEngine.explain(
          app: widget.app,
          item: matches.first,
          records: _records,
          skillMastery: _skillMastery,
        );
      }
    }

    final delta = _trend?.readinessDelta30Days;
    final trendText = delta == null
        ? 'Progress trend starts today'
        : delta > 0
            ? '+' + delta.toString() + ' points over 30 days'
            : delta < 0
                ? delta.toString() + ' points over 30 days'
                : 'No readiness change over 30 days';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: _loading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CAREER PULSE',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            analysis.goalTitle ?? goal.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            analysis.readinessLabel + ' · ' + trendText,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      analysis.readinessScore.toString() + '%',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Dimension(
                  label: 'Qualifications',
                  value: analysis.roadmapProgress,
                  detail: analysis.completedRequirements.toString() +
                      '/' +
                      analysis.totalRequirements.toString(),
                ),
                const SizedBox(height: 8),
                _Dimension(
                  label: 'Evidence',
                  value: analysis.evidenceProgress,
                  detail: analysis.evidenceCovered.toString() +
                      '/' +
                      analysis.evidenceExpected.toString(),
                ),
                const SizedBox(height: 8),
                _Dimension(
                  label: 'Competencies',
                  value: analysis.competencyProgress,
                  detail: analysis.supportedCompetencies.toString() +
                      '/' +
                      analysis.totalCompetencies.toString(),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT BEST STEP',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        analysis.recommendation.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        analysis.recommendation.reason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => widget.onPrimaryAction(analysis),
                          child: Text(analysis.recommendation.actionLabel),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_coachPrompts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'CAREER COACH',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                        ),
                        const SizedBox(height: 6),
                        ..._coachPrompts.take(2).map(
                              (prompt) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cs.surface.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: cs.outline.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              prompt.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(fontWeight: FontWeight.w900),
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Dismiss for two weeks',
                                            onPressed: () => _dismissCoach(prompt),
                                            icon: const Icon(Icons.close_rounded, size: 18),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        prompt.detail,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: cs.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        'Why am I seeing this?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        prompt.why,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              height: 1.35,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: FilledButton.tonal(
                                          onPressed: () => _actOnCoach(prompt),
                                          child: Text(prompt.actionLabel),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
                if (gap != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHY THIS GAP',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gap.whyItMatters,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                        if (gap.evidence.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Evidence already counted',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          ...gap.evidence.take(3).map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        item.verified
                                            ? Icons.verified_outlined
                                            : Icons.check_circle_outline,
                                        size: 17,
                                        color: item.verified ? cs.primary : cs.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          item.title + ' · ' + item.detail,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Still missing',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        ...gap.stillMissing.take(3).map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  '• ' + item,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                        const SizedBox(height: 8),
                        Text(
                          'Fastest way to close it',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          gap.bestAction,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => widget.onGapAction(gap!),
                            icon: const Icon(Icons.task_alt_outlined),
                            label: Text(gap.actionLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  recent.length.toString() +
                      ' activities · ' +
                      recentHours.toStringAsFixed(1) +
                      ' hr in 30 days' +
                      (verified > 0
                          ? ' · ' + verified.toString() + ' verified'
                          : ''),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (_skillMastery != null && _skillMastery!.skills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Department Skill Mastery: ' +
                        _skillMastery!.skills.where((s) => s.status == 'PROFICIENT').length.toString() +
                        ' proficient · ' +
                        _skillMastery!.skills.where((s) => s.status == 'REASSESS').length.toString() +
                        ' reassess · ' +
                        _skillMastery!.skills.where((s) => s.status == 'NEEDS_IMPROVEMENT').length.toString() +
                        ' needs improvement',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onOpenCompetencyMap,
                      icon: const Icon(Icons.hub_outlined, size: 18),
                      label: const Text('Competency Map'),
                    ),
                    TextButton.icon(
                      onPressed: widget.onOpenAdvance,
                      icon: const Icon(Icons.insights_outlined, size: 18),
                      label: const Text('Full growth analysis'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Dimension extends StatelessWidget {
  final String label;
  final double value;
  final String detail;

  const _Dimension({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              detail,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0).toDouble(),
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
