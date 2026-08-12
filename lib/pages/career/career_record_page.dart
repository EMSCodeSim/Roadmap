import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/career_stats.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/models/prefill.dart';

class CareerRecordPage extends StatefulWidget {
  const CareerRecordPage({super.key});

  @override
  State<CareerRecordPage> createState() => _CareerRecordPageState();
}

class _CareerRecordPageState extends State<CareerRecordPage> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loading = true;

  bool _careerView = false;
  late int _year = DateTime.now().year;
  CareerRecordType? _typeFilter;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loaded = await _store.load();
    loaded.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _records = loaded;
      _loading = false;
    });
  }

  List<CareerRecord> get _visible {
    final query = _search.text.trim().toLowerCase();
    Iterable<CareerRecord> items = _records;
    if (!_careerView) items = items.where((e) => e.date.year == _year);
    if (_typeFilter != null) items = items.where((e) => e.type == _typeFilter);
    if (query.isNotEmpty) {
      items = items.where((e) {
        final hay = '${e.title} ${e.category} ${e.summary ?? ''} ${e.roleOrAssignment ?? ''} ${e.tags.join(' ')}'
            .toLowerCase();
        return hay.contains(query);
      });
    }
    return items.toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visible = _visible;
    final stats = CareerStats.fromRecords(visible);
    final title = _careerView ? 'Career Record' : 'Career Record $_year';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Quick Log',
            onPressed: () async {
              await QuickLogLauncher.open(context);
              await _load();
            },
            icon: const Icon(Icons.add_task),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'legacy') context.push(AppRoutes.personalLogLegacy);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'legacy',
                child: Text('Open legacy Personal Log'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: AppSpacing.paddingLg,
            children: [
              _TopControls(
                careerView: _careerView,
                year: _year,
                onToggleView: (v) => setState(() => _careerView = v),
                onPickYear: _careerView
                    ? null
                    : () async {
                        final picked = await showModalBottomSheet<int>(
                          context: context,
                          showDragHandle: true,
                          builder: (sheetContext) => _YearPickerSheet(
                            selected: _year,
                            years: CareerStats.availableYears(_records),
                          ),
                        );
                        if (picked != null) setState(() => _year = picked);
                      },
                search: _search,
              ),
              const SizedBox(height: AppSpacing.md),
              _TypeFilterRow(
                selected: _typeFilter,
                onSelected: (t) => setState(() => _typeFilter = t),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_loading)
                const _LoadingCard()
              else ...[
                _StatsGrid(stats: stats),
                const SizedBox(height: AppSpacing.lg),
                Text('HISTORY',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: AppSpacing.sm),
                if (visible.isEmpty)
                  _EmptyState(onQuickLog: () async {
                    await QuickLogLauncher.open(context);
                    await _load();
                  })
                else
                  ...visible.map((r) => _RecordTile(
                        record: r,
                        onEdit: () => context.push(AppRoutes.personalLogLegacy,
                            extra: LogPrefill.fromRecord(r)),
                        onDelete: () async {
                          await _store.delete(r);
                          await _load();
                        },
                      )),
              ],
              const SizedBox(height: 28),
              Text(
                'Privacy reminder: keep entries professional and non-identifying. Do not store patient names, addresses, DOBs, MRNs, or other protected information.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopControls extends StatelessWidget {
  final bool careerView;
  final int year;
  final ValueChanged<bool> onToggleView;
  final VoidCallback? onPickYear;
  final TextEditingController search;
  const _TopControls(
      {required this.careerView,
      required this.year,
      required this.onToggleView,
      required this.onPickYear,
      required this.search});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('THIS YEAR')),
                    ButtonSegment(value: true, label: Text('CAREER')),
                  ],
                  selected: {careerView},
                  onSelectionChanged: (set) => onToggleView(set.first),
                ),
              ),
              if (!careerView) ...[
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: onPickYear,
                  icon: Icon(Icons.calendar_month, color: cs.onSecondaryContainer),
                  label: Text(year.toString(),
                      style: TextStyle(color: cs.onSecondaryContainer)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search calls, skills, training, goals, tasks…',
            filled: true,
          ),
        ),
      ],
    );
  }
}

class _TypeFilterRow extends StatelessWidget {
  final CareerRecordType? selected;
  final ValueChanged<CareerRecordType?> onSelected;
  const _TypeFilterRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'ALL',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          ...CareerRecordType.values.map((t) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _FilterChip(
                  label: t.shortLabel.toUpperCase(),
                  selected: selected == t,
                  onTap: () => onSelected(t),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color:
                  selected ? cs.primaryContainer : cs.outline.withValues(alpha: 0.16)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? cs.onPrimaryContainer : cs.onSurface),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final CareerStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = <_StatItem>[
      _StatItem('Calls', stats.calls.toString(), Icons.local_fire_department),
      _StatItem('Skill reps', stats.skillRepetitions.toString(), Icons.handyman),
      _StatItem('Training', stats.trainingLabel, Icons.school),
      _StatItem('Drive', stats.driveLabel, Icons.local_shipping),
      _StatItem('Teaching', stats.teachingLabel, Icons.record_voice_over),
      _StatItem('Leadership', stats.leadershipCount.toString(), Icons.groups),
      if (stats.achievements > 0)
        _StatItem('Achievements', stats.achievements.toString(), Icons.emoji_events),
      if (stats.awards > 0) _StatItem('Awards', stats.awards.toString(), Icons.military_tech),
      if (stats.projects > 0)
        _StatItem('Projects', stats.projects.toString(), Icons.assignment_turned_in),
      if (stats.taskBookUpdates > 0)
        _StatItem('Task Book', stats.taskBookUpdates.toString(), Icons.fact_check),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('SUMMARY',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            final crossAxisCount = wide ? 3 : 2;
            return GridView.builder(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: wide ? 2.35 : 2.1,
              ),
              itemBuilder: (context, index) => _StatCard(item: items[index]),
            );
          },
        ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem(this.label, this.value, this.icon);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, color: cs.onPrimaryContainer, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(item.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final CareerRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _RecordTile(
      {required this.record, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final countLabel = record.hours != null
        ? CareerStats.formatDurationHours(record.hours!)
        : (record.repetitions < 2 ? null : '${record.repetitions} reps');
    final subtitleBits = <String>[record.type.label];
    if (record.category.trim().isNotEmpty) subtitleBits.add(record.category);
    if (countLabel != null) subtitleBits.add(countLabel);
    if (record.outcome != null) subtitleBits.add(record.outcome!.label);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(_icon(record.type), color: cs.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitleBits.join(' • '),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                const SizedBox(height: 6),
                Text(CareerStats.formatDate(record.date),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _icon(CareerRecordType t) => switch (t) {
        CareerRecordType.operationalExperience => Icons.local_fire_department,
        CareerRecordType.skill => Icons.handyman,
        CareerRecordType.training => Icons.school,
        CareerRecordType.achievement => Icons.emoji_events,
        CareerRecordType.leadership => Icons.groups,
        CareerRecordType.teaching => Icons.record_voice_over,
        CareerRecordType.project => Icons.assignment,
        CareerRecordType.education => Icons.menu_book,
        CareerRecordType.taskBookEvidence => Icons.fact_check,
      };
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onQuickLog;
  const _EmptyState({required this.onQuickLog});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nothing here yet.',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            'Use Quick Log to capture calls, skills, training, drive time, leadership, awards, and Task Book progress without leaving what you’re doing.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onQuickLog,
              icon: Icon(Icons.add_task, color: cs.onPrimary),
              label: Text('Quick Log', style: TextStyle(color: cs.onPrimary)),
              style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg))),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _YearPickerSheet extends StatelessWidget {
  final int selected;
  final List<int> years;
  const _YearPickerSheet({required this.selected, required this.years});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safeYears = years.isEmpty
        ? [DateTime.now().year]
        : years;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select year',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: safeYears
                  .sorted((a, b) => b.compareTo(a))
                  .map((y) => ChoiceChip(
                        label: Text(y.toString()),
                        selected: y == selected,
                        onSelected: (_) => context.pop(y),
                        selectedColor: cs.primaryContainer,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

extension _SortedListX<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final copy = List<T>.from(this);
    copy.sort(compare);
    return copy;
  }
}
