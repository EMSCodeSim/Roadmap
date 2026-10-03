import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/competency_map.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';

class CompetencyMapPage extends StatefulWidget {
  const CompetencyMapPage({super.key});

  @override
  State<CompetencyMapPage> createState() => _CompetencyMapPageState();
}

class _CompetencyMapPageState extends State<CompetencyMapPage> {
  final CareerRecordStore _recordsStore = CareerRecordStore();
  final ResponderRoadmapApi _api = ResponderRoadmapApi();

  List<CareerRecord> _records = const [];
  DepartmentSkillMastery? _mastery;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final records = await _recordsStore.load();
    DepartmentSkillMastery? mastery;
    try {
      if (await _api.hasStoredToken) mastery = await _api.getMySkillMastery();
    } catch (_) {
      // The competency map remains useful from personal evidence alone.
    }
    if (!mounted) return;
    setState(() {
      _records = records;
      _mastery = mastery;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roadmap = app.roadmap;
    if (roadmap == null) {
      return Scaffold(
        appBar: const FirefighterRoadmapAppBar(subtitle: 'Competencies'),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.goalSetup),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Choose a career goal'),
          ),
        ),
      );
    }

    final map = CompetencyMapEngine.build(
      roadmap: roadmap,
      records: _records,
      skillMastery: _mastery,
    );
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const FirefighterRoadmapAppBar(subtitle: 'Competency Map'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                children: [
                  Text(
                    '${map.goalTitle} competency map',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'A goal-specific view of where your evidence is strong, current, developing, stale, or missing. This describes the evidence around each competency, not your overall performance.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SummaryChip(
                        label: 'Strong',
                        count: map.count(CompetencyFreshness.strong),
                        icon: Icons.workspace_premium_outlined,
                      ),
                      _SummaryChip(
                        label: 'Current',
                        count: map.count(CompetencyFreshness.current),
                        icon: Icons.check_circle_outline,
                      ),
                      _SummaryChip(
                        label: 'Developing',
                        count: map.count(CompetencyFreshness.developing),
                        icon: Icons.trending_up,
                      ),
                      _SummaryChip(
                        label: 'Stale',
                        count: map.count(CompetencyFreshness.stale),
                        icon: Icons.history_toggle_off,
                      ),
                      _SummaryChip(
                        label: 'Missing',
                        count: map.count(CompetencyFreshness.missing),
                        icon: Icons.remove_circle_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Freshness window: ${map.freshnessDays} days' +
                        (_mastery == null
                            ? ' · personal evidence only'
                            : ' · department Skill Mastery included'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...map.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CompetencyCard(
                        item: item,
                        onTap: () => _showDetail(context, item),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showDetail(BuildContext context, CompetencyMapItem item) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final unfinished =
            item.requirements.where((requirement) => !requirement.isComplete);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.92,
          minChildSize: 0.45,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  _StatusBadge(item: item),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.nextFocus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 18),
              _DetailMetric(
                label: 'Requirements',
                value:
                    '${item.completedRequirements}/${item.totalRequirements}',
              ),
              _DetailMetric(
                label: 'Evidence',
                value: '${item.evidenceCount} total · ${item.recentEvidenceCount} current',
              ),
              _DetailMetric(
                label: 'Verified',
                value: item.verifiedEvidenceCount.toString(),
              ),
              const SizedBox(height: 18),
              Text(
                'Supporting evidence',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              if (item.evidence.isEmpty)
                Text(
                  'No evidence is currently matched to this competency.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                )
              else
                ...item.evidence.map(
                  (evidence) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      evidence.verified
                          ? Icons.verified_outlined
                          : Icons.description_outlined,
                    ),
                    title: Text(evidence.title),
                    subtitle: Text(evidence.detail),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Roadmap requirements',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              ...item.requirements.map(
                (requirement) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    requirement.isComplete
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(requirement.requirement.name),
                  subtitle: Text(
                    requirement.isComplete ? 'Complete' : 'Still needed',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    AppRouter.openRequirement(
                      context,
                      requirement.requirement,
                      goalId: context.read<AppState>().roadmap?.goal.id,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (item.mastery.any((skill) =>
                  skill.status == 'REASSESS' ||
                  skill.status == 'NEEDS_IMPROVEMENT'))
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go(AppRoutes.department);
                  },
                  icon: const Icon(Icons.apartment_outlined),
                  label: const Text('Open Department for reassessment'),
                )
              else if (unfinished.isNotEmpty)
                FilledButton.icon(
                  onPressed: () {
                    final target = unfinished.first;
                    Navigator.of(sheetContext).pop();
                    AppRouter.openRequirement(
                      context,
                      target.requirement,
                      goalId: context.read<AppState>().roadmap?.goal.id,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('Work on ${unfinished.first.requirement.name}'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go(AppRoutes.personalLog);
                  },
                  icon: const Icon(Icons.add_task_outlined),
                  label: const Text('Add current evidence'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CompetencyCard extends StatelessWidget {
  final CompetencyMapItem item;
  final VoidCallback onTap;

  const _CompetencyCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  _StatusBadge(item: item),
                ],
              ),
              const SizedBox(height: 7),
              LinearProgressIndicator(
                value: item.requirementProgress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 7),
              Text(
                '${item.completedRequirements}/${item.totalRequirements} requirements · ${item.evidenceCount} evidence · ${item.verifiedEvidenceCount} verified',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 7),
              Text(
                item.nextFocus,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CompetencyMapItem item;
  const _StatusBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = switch (item.status) {
      CompetencyFreshness.strong => Icons.workspace_premium_outlined,
      CompetencyFreshness.current => Icons.check_circle_outline,
      CompetencyFreshness.developing => Icons.trending_up,
      CompetencyFreshness.stale => Icons.history_toggle_off,
      CompetencyFreshness.missing => Icons.remove_circle_outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(
            item.statusLabel,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 17),
      label: Text('$label $count'),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;
  const _DetailMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
