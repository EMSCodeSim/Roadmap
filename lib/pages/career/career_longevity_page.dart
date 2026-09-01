import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/career_longevity.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';

class CareerLongevityPage extends StatefulWidget {
  const CareerLongevityPage({super.key});

  @override
  State<CareerLongevityPage> createState() => _CareerLongevityPageState();
}

class _CareerLongevityPageState extends State<CareerLongevityPage> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _store.load();
    records.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final readiness = CareerLongevity.readinessAcrossGoals(
      app: app,
      records: _records,
    ).take(6).toList();
    final comparison = CareerLongevity.compareYears(_records);
    final decay = CareerLongevity.skillRefreshAlerts(_records).take(6).toList();
    final archives = CareerLongevity.archivedPaths(
      app: app,
      records: _records,
    ).take(8).toList();
    final stories = _records
        .where(
          (e) =>
              e.highlight ||
              e.type == CareerRecordType.leadership ||
              e.type == CareerRecordType.project ||
              e.type == CareerRecordType.achievement,
        )
        .take(8)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toCareerIntelligence(),
        title: const Text('Long-Term Career Tools'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  _Hero(cs: cs),
                  const SizedBox(height: 20),
                  _SectionTitle('WHAT AM I READY FOR?'),
                  const SizedBox(height: 8),
                  if (readiness.isEmpty)
                    const _EmptyCard(
                      text:
                          'Add certifications and career activity to compare future paths.',
                    )
                  else
                    ...readiness.map(
                      (item) => _ReadinessCard(
                        item: item,
                        activeGoalId: app.selectedGoal?.id,
                      ),
                    ),
                  const SizedBox(height: 22),
                  _SectionTitle('YEAR OVER YEAR'),
                  const SizedBox(height: 8),
                  _YearComparisonCard(comparison: comparison),
                  const SizedBox(height: 22),
                  _SectionTitle('SKILL REFRESH'),
                  const SizedBox(height: 8),
                  if (decay.isEmpty)
                    const _EmptyCard(
                      text:
                          'No documented skills are currently more than a year old.',
                    )
                  else
                    ...decay.map((item) => _SkillAlertCard(item: item)),
                  const SizedBox(height: 22),
                  _SectionTitle('ARCHIVED CAREER PATHS'),
                  const SizedBox(height: 8),
                  if (archives.isEmpty)
                    const _EmptyCard(
                      text:
                          'Past goals will appear here after you change career paths while keeping linked records or Task Book progress.',
                    )
                  else
                    ...archives.map((item) => _ArchiveCard(item: item)),
                  const SizedBox(height: 22),
                  _SectionTitle('INTERVIEW STORY BUILDER'),
                  const SizedBox(height: 8),
                  if (stories.isEmpty)
                    const _EmptyCard(
                      text:
                          'Mark leadership, project, achievement, or other strong examples as career highlights to build interview stories.',
                    )
                  else
                    ...stories.map(
                      (record) => _StoryCard(
                        record: record,
                        onTap: () => _showText(
                          'STAR Story',
                          CareerLongevity.buildStarStory(record),
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  _SectionTitle('EXPORT PACKETS'),
                  const SizedBox(height: 8),
                  _ActionCard(
                    icon: Icons.description_outlined,
                    title: 'Resume / Promotion Source Packet',
                    text:
                        'Build reusable source material from your roles, credentials, training, highlights, leadership, and projects.',
                    button: 'Build packet',
                    onTap: () => _showText(
                      'Resume / Promotion Packet',
                      CareerLongevity.buildResumePacket(
                        app: app,
                        records: _records,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Readiness previews are personal planning estimates based on the information recorded in Career Road. They are not official eligibility determinations. Always verify requirements with your department, state, or certifying authority.',
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

  Future<void> _showText(String title, String text) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard.')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ColorScheme cs;
  const _Hero({required this.cs});
  @override
  Widget build(BuildContext context) => Container(
    padding: AppSpacing.paddingLg,
    decoration: BoxDecoration(
      color: cs.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your career keeps moving.',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Use years of preserved data to compare future paths, notice stale skills, reopen old goals, and turn real experience into interview and resume material.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w900,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class _ReadinessCard extends StatelessWidget {
  final GoalReadinessPreview item;
  final String? activeGoalId;
  const _ReadinessCard({required this.item, required this.activeGoalId});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = item.goal.id == activeGoalId;
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: item.score / 100,
                    strokeWidth: 6,
                  ),
                  Text(
                    '${item.score}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.goal.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.completed}/${item.total} core requirements matched${active ? ' • active goal' : ''}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearComparisonCard extends StatelessWidget {
  final YearComparison comparison;
  const _YearComparisonCard({required this.comparison});
  String deltaNum(num current, num previous) {
    final delta = current - previous;
    if (delta == 0) return 'same';
    return delta > 0
        ? '+${delta.toStringAsFixed(delta is double ? 1 : 0)}'
        : delta.toStringAsFixed(delta is double ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: AppSpacing.paddingMd,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.14),
      ),
    ),
    child: Column(
      children: [
        _CompareRow(
          label: 'Documented activities',
          current: '${comparison.currentRecords}',
          previous: '${comparison.previousRecords}',
          delta: deltaNum(
            comparison.currentRecords,
            comparison.previousRecords,
          ),
        ),
        const Divider(),
        _CompareRow(
          label: 'Documented hours',
          current: comparison.currentHours.toStringAsFixed(1),
          previous: comparison.previousHours.toStringAsFixed(1),
          delta: deltaNum(comparison.currentHours, comparison.previousHours),
        ),
        const Divider(),
        _CompareRow(
          label: 'Leadership / teaching / projects',
          current: '${comparison.currentLeadership}',
          previous: '${comparison.previousLeadership}',
          delta: deltaNum(
            comparison.currentLeadership,
            comparison.previousLeadership,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${comparison.currentYear} compared with ${comparison.previousYear}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String current;
  final String previous;
  final String delta;
  const _CompareRow({
    required this.label,
    required this.current,
    required this.previous,
    required this.delta,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(
        '$previous → $current',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(width: 10),
      Text(
        delta,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _SkillAlertCard extends StatelessWidget {
  final SkillRefreshAlert item;
  const _SkillAlertCard({required this.item});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.history_toggle_off),
      title: Text(item.name),
      subtitle: Text(
        'Last documented ${item.daysSince} days ago • ${item.documentedCount} career record${item.documentedCount == 1 ? '' : 's'}',
      ),
      trailing: const Text(
        'REFRESH',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}

class _ArchiveCard extends StatelessWidget {
  final ArchivedCareerPath item;
  const _ArchiveCard({required this.item});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.archive_outlined),
      title: Text(item.title),
      subtitle: Text(
        '${item.linkedRecords} linked records • ${item.trackedOverrides} tracked requirements${item.lastActivity == null ? '' : ' • last activity ${item.lastActivity!.month}/${item.lastActivity!.year}'}',
      ),
      trailing: item.trackedOverrides > 0
          ? Text(
              '${item.percent}%',
              style: const TextStyle(fontWeight: FontWeight.w900),
            )
          : null,
    ),
  );
}

class _StoryCard extends StatelessWidget {
  final CareerRecord record;
  final VoidCallback onTap;
  const _StoryCard({required this.record, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.auto_stories_outlined),
      title: Text(record.title),
      subtitle: Text(record.type.label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String button;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.button,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: AppSpacing.paddingMd,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.14),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(text),
        const SizedBox(height: 12),
        FilledButton(onPressed: onTap, child: Text(button)),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: AppSpacing.paddingMd,
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Text(text),
  );
}
