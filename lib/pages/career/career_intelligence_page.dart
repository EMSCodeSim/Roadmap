import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_intelligence.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class CareerIntelligencePage extends StatefulWidget {
  const CareerIntelligencePage({super.key});

  @override
  State<CareerIntelligencePage> createState() => _CareerIntelligencePageState();
}

class _CareerIntelligencePageState extends State<CareerIntelligencePage> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loading = true;
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _store.load();
    records.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    final years = records.map((e) => e.date.year).toSet();
    setState(() {
      _records = records;
      _loading = false;
      if (years.isNotEmpty && !years.contains(_year)) {
        _year = years.reduce((a, b) => a > b ? a : b);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final snapshot = CareerIntelligence.analyze(_records);
    final years = _records.map((e) => e.date.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Career Intelligence')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                children: [
                  Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your career record should tell you something.',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Career Intelligence turns years of logs, evidence, achievements, and advancement work into useful patterns for reviews, interviews, and your next move.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.65,
                    children: [
                      _MetricCard(
                        label: 'Career records',
                        value: '${snapshot.totalRecords}',
                        icon: Icons.inventory_2_outlined,
                      ),
                      _MetricCard(
                        label: 'Years documented',
                        value: '${snapshot.yearsDocumented}',
                        icon: Icons.timeline_outlined,
                      ),
                      _MetricCard(
                        label: 'Documented hours',
                        value: snapshot.totalHours.toStringAsFixed(1),
                        icon: Icons.schedule_outlined,
                      ),
                      _MetricCard(
                        label: 'Career highlights',
                        value: '${snapshot.highlightCount}',
                        icon: Icons.star_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'WHAT YOUR RECORD SAYS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InsightCard(
                    icon: Icons.trending_up,
                    title: snapshot.strongestArea == null
                        ? 'Build your career record'
                        : 'Strongest documented area',
                    text: snapshot.strongestArea == null
                        ? 'Log meaningful work, training, leadership, projects, and achievements so Career Road can identify useful patterns.'
                        : '${snapshot.strongestArea!.type.label} is currently your most documented area with ${snapshot.strongestArea!.count} records.',
                  ),
                  const SizedBox(height: 10),
                  _InsightCard(
                    icon: Icons.explore_outlined,
                    title: 'Development opportunity',
                    text: snapshot.developmentGap == null
                        ? 'Keep building a balanced record across operational work, leadership, teaching, projects, and achievements.'
                        : 'You have relatively little ${snapshot.developmentGap!.type.label.toLowerCase()} evidence. Intentionally capture strong examples here as they happen.',
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'CAREER TOOLS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ToolCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Annual Career Review',
                    description: 'Turn one year of work into a clean summary of activity, highlights, strengths, and next-year priorities.',
                    trailing: years.isEmpty
                        ? null
                        : DropdownButton<int>(
                            value: years.contains(_year) ? _year : years.first,
                            underline: const SizedBox.shrink(),
                            items: years
                                .map(
                                  (year) => DropdownMenuItem(
                                    value: year,
                                    child: Text('$year'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _year = value ?? _year),
                          ),
                    onTap: years.isEmpty
                        ? null
                        : () => _showText(
                            title: '$_year Annual Career Review',
                            text: CareerIntelligence.buildAnnualReview(
                              app: app,
                              records: _records,
                              year: _year,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  _ToolCard(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Promotion Portfolio',
                    description: 'Build a promotion-ready snapshot from your credentials, evidence gaps, competencies, and strongest career stories.',
                    onTap: () => _showText(
                      title: 'Promotion Portfolio',
                      text: CareerIntelligence.buildPromotionPortfolio(
                        app: app,
                        records: _records,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ToolCard(
                    icon: Icons.timeline_outlined,
                    title: 'Long-Term Career Tools',
                    description: 'Compare future career paths, review past goals, catch stale skills, build STAR interview stories, and create resume source material.',
                    onTap: () => context.push(AppRoutes.careerLongevity),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'CAREER HIGHLIGHTS',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ),
                      Text(
                        'timeline',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.highlights.isEmpty)
                    _InsightCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'No highlights yet',
                      text: 'Mark important leadership examples, achievements, projects, and meaningful career moments so they remain easy to find years later.',
                    )
                  else
                    ...snapshot.highlights
                        .take(10)
                        .map((record) => _TimelineItem(record: record)),
                  const SizedBox(height: 12),
                  Text(
                    'Career Intelligence is a personal professional-development aid. It does not replace official department personnel, training, credential, or promotional records.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _showText({required String title, required String text}) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: Theme.of(dialogContext).textTheme.bodyMedium
                  ?.copyWith(height: 1.5),
            ),
          ),
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.text,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final CareerRecord record;
  const _TimelineItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 48,
                color: cs.outline.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.date.month}/${record.date.day}/${record.date.year}',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  record.title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if ((record.impact ?? '').trim().isNotEmpty)
                  Text(
                    record.impact!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
