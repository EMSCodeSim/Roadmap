import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/advancement_analyzer.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class GrowthOverviewPage extends StatefulWidget {
  const GrowthOverviewPage({super.key});

  @override
  State<GrowthOverviewPage> createState() => _GrowthOverviewPageState();
}

class _GrowthOverviewPageState extends State<GrowthOverviewPage> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final records = await _store.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final analysis = AdvancementAnalyzer.analyze(app: app, records: _records);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Growth')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                children: [
                  _GrowthHero(
                    analysis: analysis,
                    onGoal: () => context.push(AppRoutes.goalSetup),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BestNextMoveCard(
                    recommendation: analysis.recommendation,
                    onAction: () => _handleRecommendation(analysis),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Promotion Readiness',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'A simple snapshot of the four areas that support your next move.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ReadinessRow(
                    icon: Icons.route_outlined,
                    label: 'Qualifications',
                    value: analysis.roadmapProgress,
                    valueText: analysis.totalRequirements == 0
                        ? 'No target'
                        : '${analysis.completedRequirements}/${analysis.totalRequirements}',
                    detail: 'Task Book requirements completed',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ReadinessRow(
                    icon: Icons.attach_file_outlined,
                    label: 'Experience Evidence',
                    value: analysis.evidenceProgress,
                    valueText: analysis.evidenceExpected == 0
                        ? '—'
                        : '${analysis.evidenceCovered}/${analysis.evidenceExpected}',
                    detail: 'Evidence-worthy requirements documented',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ReadinessRow(
                    icon: Icons.hub_outlined,
                    label: 'Leadership / Competencies',
                    value: analysis.competencyProgress,
                    valueText:
                        '${analysis.supportedCompetencies}/${analysis.totalCompetencies}',
                    detail: 'Professional competency areas supported',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ReadinessRow(
                    icon: Icons.auto_stories_outlined,
                    label: 'Interview Stories',
                    value: (analysis.storyReadyCount / 5)
                        .clamp(0.0, 1.0)
                        .toDouble(),
                    valueText: '${analysis.storyReadyCount}/5+',
                    detail: 'Reusable career stories ready',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _GrowthToolsCard(
                    onDetailedGrowth: () =>
                        context.push(AppRoutes.growthDetails),
                    onEvidence: () => context.push(AppRoutes.careerEvidence),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Growth is a personal preparation tool. Always verify promotional and credential requirements with your department, state, or certifying authority.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
    );
  }

  void _handleRecommendation(AdvancementAnalysis analysis) {
    switch (analysis.recommendation.kind) {
      case AdvancementActionKind.chooseGoal:
        context.push(AppRoutes.goalSetup);
      case AdvancementActionKind.workRoadmap:
        context.go(AppRoutes.myPath);
      case AdvancementActionKind.documentRequirement:
      case AdvancementActionKind.buildCompetency:
        context.push(AppRoutes.growthDetails);
      case AdvancementActionKind.maintainMomentum:
        context.go(AppRoutes.personalLog);
    }
  }
}

class _GrowthHero extends StatelessWidget {
  final AdvancementAnalysis analysis;
  final VoidCallback onGoal;

  const _GrowthHero({
    required this.analysis,
    required this.onGoal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasGoal = analysis.goalTitle != null;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: hasGoal ? analysis.readinessScore / 100 : 0,
                    strokeWidth: 7,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
                Text(
                  hasGoal ? '${analysis.readinessScore}%' : '—',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasGoal
                      ? analysis.goalTitle!
                      : 'Choose your next career goal',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.readinessLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 7),
                TextButton.icon(
                  onPressed: onGoal,
                  icon: Icon(
                    hasGoal ? Icons.edit_outlined : Icons.flag_outlined,
                    size: 18,
                  ),
                  label: Text(hasGoal ? 'Change goal' : 'Choose goal'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BestNextMoveCard extends StatelessWidget {
  final AdvancementRecommendation recommendation;
  final VoidCallback onAction;

  const _BestNextMoveCard({
    required this.recommendation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.near_me_outlined, color: cs.onPrimaryContainer),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'BEST NEXT MOVE',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            recommendation.title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            recommendation.reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward),
              label: Text(recommendation.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String valueText;
  final String detail;

  const _ReadinessRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueText,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: cs.onSecondaryContainer),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      valueText,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0).toDouble(),
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthToolsCard extends StatelessWidget {
  final VoidCallback onDetailedGrowth;
  final VoidCallback onEvidence;

  const _GrowthToolsCard({
    required this.onDetailedGrowth,
    required this.onEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Growth Tools',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            'Use these when you want to go deeper than the snapshot above.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insights_outlined),
            title: const Text('Detailed Growth & Promotion Prep'),
            subtitle: const Text(
              'Evidence gaps, competencies, story bank, and promotion brief',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onDetailedGrowth,
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Career Evidence'),
            subtitle: const Text(
              'Store detailed examples, outcomes, and supporting proof',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onEvidence,
          ),
        ],
      ),
    );
  }
}
