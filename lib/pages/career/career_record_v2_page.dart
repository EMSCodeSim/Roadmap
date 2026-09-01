import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/career_stats.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';
import 'package:firepath/widgets/portfolio_backup_sheet.dart';

enum _CareerFilter {
  all,
  calls,
  skills,
  training,
  driving,
  taskBook,
  exposures,
  leadership,
  achievements,
}

extension _CareerFilterX on _CareerFilter {
  String get label => switch (this) {
        _CareerFilter.all => 'ALL',
        _CareerFilter.calls => 'CALLS',
        _CareerFilter.skills => 'SKILLS',
        _CareerFilter.training => 'TRAINING',
        _CareerFilter.driving => 'DRIVING',
        _CareerFilter.taskBook => 'TASK BOOK',
        _CareerFilter.exposures => 'EXPOSURES',
        _CareerFilter.leadership => 'LEADERSHIP',
        _CareerFilter.achievements => 'ACHIEVEMENTS',
      };
}

class CareerRecordV2Page extends StatefulWidget {
  const CareerRecordV2Page({super.key});

  @override
  State<CareerRecordV2Page> createState() => _CareerRecordV2PageState();
}

class _CareerRecordV2PageState extends State<CareerRecordV2Page> {
  final CareerRecordStore _store = CareerRecordStore();
  final TextEditingController _search = TextEditingController();
  List<CareerRecord> _records = const [];
  bool _loading = true;
  bool _career = false;
  int _year = DateTime.now().year;
  _CareerFilter _filter = _CareerFilter.all;

  @override
  void initState() {
    super.initState();
    _search.addListener(_refresh);
    QuickLogLauncher.recordRevision.addListener(_onQuickLogChanged);
    _load();
  }

  @override
  void dispose() {
    QuickLogLauncher.recordRevision.removeListener(_onQuickLogChanged);
    _search.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onQuickLogChanged() {
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

  List<CareerRecord> get _periodRecords => _career
      ? _records
      : _records.where((record) => record.date.year == _year).toList();

  List<CareerRecord> get _visibleRecords {
    final query = _search.text.trim().toLowerCase();
    return _periodRecords.where((record) {
      if (!_matchesFilter(record)) return false;
      if (query.isEmpty) return true;
      final text = [
        record.title,
        record.category,
        record.summary ?? '',
        record.roleOrAssignment ?? '',
        record.trackingKey ?? '',
        ...record.tags,
      ].join(' ').toLowerCase();
      return text.contains(query);
    }).toList();
  }

  bool _matchesFilter(CareerRecord record) => switch (_filter) {
        _CareerFilter.all => true,
        _CareerFilter.calls =>
          record.type == CareerRecordType.operationalExperience &&
              !CareerStats.isExposureRecord(record),
        _CareerFilter.skills =>
          record.type == CareerRecordType.skill &&
              !CareerStats.isDrivingRecord(record),
        _CareerFilter.training => record.type == CareerRecordType.training,
        _CareerFilter.driving => CareerStats.isDrivingRecord(record),
        _CareerFilter.taskBook =>
          record.type == CareerRecordType.taskBookEvidence ||
              record.tags.contains('task-book'),
        _CareerFilter.exposures => CareerStats.isExposureRecord(record),
        _CareerFilter.leadership =>
          record.type == CareerRecordType.leadership ||
              record.type == CareerRecordType.teaching,
        _CareerFilter.achievements =>
          record.type == CareerRecordType.achievement ||
              record.type == CareerRecordType.project,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stats = CareerStats.fromRecords(_periodRecords);
    final procedureStats = _procedureStats(_periodRecords);
    final visible = _visibleRecords;

    return Scaffold(
      appBar: FirefighterRoadmapAppBar(
        subtitle: 'Log',
        actions: [
          IconButton(
            tooltip: 'Quick Log setup',
            onPressed: () async {
              await context.push(AppRoutes.quickLogSetup);
              await _load();
            },
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Quick Log',
            onPressed: _openQuickLog,
            icon: const Icon(Icons.add_task),
          ),
          PopupMenuButton<String>(
            tooltip: 'More career record tools',
            onSelected: (value) {
              if (value == 'backup') {
                PortfolioBackupSheet.show(context, onRestored: _load);
              } else if (value == 'advanced') {
                context.push(AppRoutes.personalLogClassic);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: Icon(Icons.backup_outlined),
                  title: Text('Backup & restore'),
                  subtitle: Text('Save or restore a portfolio file'),
                ),
              ),
              PopupMenuItem(
                value: 'advanced',
                child: ListTile(
                  leading: Icon(Icons.inventory_2_outlined),
                  title: Text('Classic log tools'),
                  subtitle: Text('Evidence and older log views'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQuickLog,
        icon: const Icon(Icons.add),
        label: const Text('Quick Log'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _PeriodControls(
                career: _career,
                year: _year,
                onCareerChanged: (value) => setState(() => _career = value),
                onYearTap: _career ? null : _pickYear,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search your career record',
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _CareerFilter.values
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter.label),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                Text(
                  _career ? 'CAREER SUMMARY' : '$_year SUMMARY',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                _SummaryGrid(stats: stats),
                if (procedureStats.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'PROCEDURE SUCCESS',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ),
                      Text(
                        'measured attempts',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...procedureStats.take(8).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ProcedureRateCard(item: item),
                        ),
                      ),
                ],
                const SizedBox(height: 22),
                Text(
                  'HISTORY',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                if (visible.isEmpty)
                  _EmptyHistory(onLog: _openQuickLog)
                else
                  ...visible.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _RecordCard(
                        record: record,
                        onEdit: () => _editRecord(record),
                        onDelete: () => _deleteRecord(record),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 22),
              Text(
                'Privacy: this is a professional career record, not an ePCR. Do not enter patient names, DOBs, addresses, medical record numbers, or other identifying information.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ProcedureStat> _procedureStats(List<CareerRecord> records) {
    final grouped = <String, List<CareerRecord>>{};
    for (final record in records) {
      final key = record.trackingKey;
      if (key == null || key.isEmpty) continue;
      if (record.outcome != CareerRecordOutcome.successful &&
          record.outcome != CareerRecordOutcome.unsuccessful) {
        continue;
      }
      (grouped[key] ??= <CareerRecord>[]).add(record);
    }
    final result = <_ProcedureStat>[];
    for (final entry in grouped.entries) {
      final measured = CareerStats.successFor(entry.value, trackingKey: entry.key);
      if (measured.attempts <= 0) continue;
      final latest = [...entry.value]
        ..sort((a, b) => b.date.compareTo(a.date));
      result.add(
        _ProcedureStat(
          title: latest.first.title,
          keyName: entry.key,
          stats: measured,
        ),
      );
    }
    result.sort((a, b) => b.stats.attempts.compareTo(a.stats.attempts));
    return result;
  }

  Future<void> _openQuickLog() async {
    await QuickLogLauncher.open(context);
    await _load();
  }

  Future<void> _pickYear() async {
    final years = CareerStats.availableYears(_records);
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final options = years.isEmpty ? [DateTime.now().year] : years;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose year',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options
                      .map(
                        (year) => ChoiceChip(
                          label: Text('$year'),
                          selected: year == _year,
                          onSelected: (_) => Navigator.pop(sheetContext, year),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) setState(() => _year = selected);
  }

  Future<void> _deleteRecord(CareerRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete career record?'),
        content: Text(
          '${record.title} from ${CareerStats.formatDate(record.date)} will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!await _store.delete(record)) return;
    await _adjustNumericProgress(record, -1);
    final remaining = await _store.load();
    await _resetTaskPracticeIfNeeded(record, remaining);
    await _load();
  }

  Future<void> _editRecord(CareerRecord existing) async {
    final result = await showDialog<CareerRecord>(
      context: context,
      builder: (dialogContext) => _CareerRecordEditor(record: existing),
    );
    if (result == null) return;
    if (existing.date.year != result.date.year) {
      if (!await _store.delete(existing)) return;
    }
    if (!await _store.upsert(result)) return;
    await _adjustNumericProgress(existing, -1);
    await _adjustNumericProgress(result, 1);
    await _load();
  }

  Future<void> _adjustNumericProgress(
    CareerRecord record,
    double direction,
  ) async {
    if (!record.tags.contains('task-book-progress-applied')) return;
    final goalId = record.relatedGoalId;
    final requirementId = record.relatedRequirementId;
    if (goalId == null || requirementId == null) return;
    final app = context.read<AppState>();
    final roadmap = app.roadmap;
    if (roadmap == null || roadmap.goal.id != goalId) return;
    final matches = roadmap.all
        .where((item) => item.requirement.id == requirementId)
        .toList();
    if (matches.isEmpty) return;
    final requirement = matches.first.requirement;
    if (requirement.type != RequirementType.numericProgress ||
        requirement.progressRequired == null ||
        requirement.progressRequired! <= 0) {
      return;
    }
    final delta = record.hours ?? record.repetitions.toDouble();
    final next = (requirement.progressCurrent ?? 0) + delta * direction;
    await app.setNumericProgress(
      goalId: goalId,
      requirementId: requirementId,
      current: next < 0 ? 0 : next,
      required: requirement.progressRequired!,
      unit: requirement.progressUnit,
    );
  }

  Future<void> _resetTaskPracticeIfNeeded(
    CareerRecord deleted,
    List<CareerRecord> remaining,
  ) async {
    final goalId = deleted.relatedGoalId;
    final requirementId = deleted.relatedRequirementId;
    final taskId = deleted.relatedTaskId;
    if (goalId == null || requirementId == null || taskId == null) return;
    if (remaining.any(
      (record) =>
          record.relatedGoalId == goalId &&
          record.relatedRequirementId == requirementId &&
          record.relatedTaskId == taskId,
    )) {
      return;
    }
    final app = context.read<AppState>();
    final status = app.taskStatusFor(
      goalId: goalId,
      requirementId: requirementId,
      taskId: taskId,
    );
    if (status == TaskBookTaskStatus.practicing) {
      await app.setTaskStatus(
        goalId: goalId,
        requirementId: requirementId,
        taskId: taskId,
        status: TaskBookTaskStatus.notStarted,
      );
    }
  }
}

class _PeriodControls extends StatelessWidget {
  final bool career;
  final int year;
  final ValueChanged<bool> onCareerChanged;
  final VoidCallback? onYearTap;

  const _PeriodControls({
    required this.career,
    required this.year,
    required this.onCareerChanged,
    required this.onYearTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('THIS YEAR')),
              ButtonSegment(value: true, label: Text('CAREER')),
            ],
            selected: {career},
            onSelectionChanged: (selection) =>
                onCareerChanged(selection.first),
          ),
          if (!career)
            SizedBox(
              height: 48,
              child: FilledButton.tonalIcon(
                onPressed: onYearTap,
                icon: const Icon(Icons.calendar_month),
                label: Text('$year'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final CareerStats stats;
  const _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final metrics = <_SummaryMetric>[
      _SummaryMetric(
        'Calls',
        '${stats.calls}',
        Icons.local_fire_department_outlined,
      ),
      _SummaryMetric(
        'Skill reps',
        '${stats.skillRepetitions}',
        Icons.handyman_outlined,
      ),
      _SummaryMetric('Training', stats.trainingLabel, Icons.school_outlined),
      _SummaryMetric(
        'Drive time',
        stats.driveLabel,
        Icons.local_shipping_outlined,
      ),
      _SummaryMetric(
        'Exposures',
        '${stats.totalExposures}',
        Icons.health_and_safety_outlined,
        detail:
            '${stats.medicalExposures} medical • ${stats.hazardExposures} hazard',
      ),
      _SummaryMetric(
        'Leadership',
        '${stats.leadershipCount}',
        Icons.groups_outlined,
      ),
    ].where((metric) => metric.value != '0' && metric.value != '0 hr').toList();

    if (metrics.isEmpty) {
      return const Text('Nothing logged for this period yet.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns == 3 ? 2.25 : 1.65,
          ),
          itemBuilder: (context, index) => _SummaryCard(metric: metrics[index]),
        );
      },
    );
  }
}

class _SummaryMetric {
  final String label;
  final String value;
  final IconData icon;
  final String? detail;
  const _SummaryMetric(this.label, this.value, this.icon, {this.detail});
}

class _SummaryCard extends StatelessWidget {
  final _SummaryMetric metric;
  const _SummaryCard({required this.metric});

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: cs.primary, size: 23),
          const SizedBox(height: 5),
          Text(
            metric.value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(metric.label, style: Theme.of(context).textTheme.labelMedium),
          if (metric.detail != null)
            Text(
              metric.detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _ProcedureStat {
  final String title;
  final String keyName;
  final CareerSuccessStats stats;
  const _ProcedureStat({
    required this.title,
    required this.keyName,
    required this.stats,
  });
}

class _ProcedureRateCard extends StatelessWidget {
  final _ProcedureStat item;
  const _ProcedureRateCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.stats.successful} successful • ${item.stats.unsuccessful} unsuccessful • ${item.stats.attempts} attempts',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${item.stats.percent ?? 0}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final CareerRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amount = record.hours != null
        ? CareerStats.formatDurationHours(record.hours!)
        : record.repetitions > 1
            ? '${record.repetitions} attempts/reps'
            : null;
    final details = <String>[
      record.category,
      if (amount != null) amount,
      if (record.outcome != null) record.outcome!.label,
    ].where((value) => value.trim().isNotEmpty).join(' • ');

    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(_icon(record), color: cs.primary, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                Text(
                  CareerStats.formatDate(record.date),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Record options',
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

  static IconData _icon(CareerRecord record) {
    if (CareerStats.isMedicalExposureRecord(record)) {
      return Icons.medical_services_outlined;
    }
    if (CareerStats.isHazardExposureRecord(record)) {
      return Icons.health_and_safety_outlined;
    }
    if (CareerStats.isDrivingRecord(record)) {
      return Icons.local_shipping_outlined;
    }
    return switch (record.type) {
      CareerRecordType.operationalExperience =>
        Icons.local_fire_department_outlined,
      CareerRecordType.skill => Icons.handyman_outlined,
      CareerRecordType.training => Icons.school_outlined,
      CareerRecordType.achievement => Icons.emoji_events_outlined,
      CareerRecordType.leadership => Icons.groups_outlined,
      CareerRecordType.teaching => Icons.record_voice_over_outlined,
      CareerRecordType.project => Icons.assignment_outlined,
      CareerRecordType.education => Icons.menu_book_outlined,
      CareerRecordType.taskBookEvidence => Icons.fact_check_outlined,
    };
  }
}

class _EmptyHistory extends StatelessWidget {
  final VoidCallback onLog;
  const _EmptyHistory({required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nothing matches this view yet.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onLog,
              icon: const Icon(Icons.add_task),
              label: const Text('Quick Log'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerRecordEditor extends StatefulWidget {
  final CareerRecord record;
  const _CareerRecordEditor({required this.record});

  @override
  State<_CareerRecordEditor> createState() => _CareerRecordEditorState();
}

class _CareerRecordEditorState extends State<_CareerRecordEditor> {
  late final TextEditingController _title =
      TextEditingController(text: widget.record.title);
  late final TextEditingController _category =
      TextEditingController(text: widget.record.category);
  late final TextEditingController _count =
      TextEditingController(text: widget.record.repetitions.toString());
  late final TextEditingController _hours =
      TextEditingController(text: widget.record.hours?.toString() ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.record.summary ?? '');
  late CareerRecordOutcome? _outcome = widget.record.outcome;
  late DateTime _date = widget.record.date;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _count.dispose();
    _hours.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit career record'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Activity'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _count,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Attempts / reps'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _hours,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Hours'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CareerRecordOutcome?>(
                value: _outcome,
                decoration: const InputDecoration(labelText: 'Outcome'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Not tracked'),
                  ),
                  ...CareerRecordOutcome.values.map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _outcome = value),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(CareerStats.formatDate(_date)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      ),
    );
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final count = int.tryParse(_count.text.trim()) ?? 1;
    final hoursText = _hours.text.trim();
    final hours = hoursText.isEmpty ? null : double.tryParse(hoursText);
    if (count <= 0 ||
        (hoursText.isNotEmpty && (hours == null || hours <= 0))) {
      return;
    }
    Navigator.pop(
      context,
      CareerRecord(
        id: widget.record.id,
        type: widget.record.type,
        title: title,
        category: _category.text.trim(),
        date: _date,
        roleOrAssignment: widget.record.roleOrAssignment,
        summary: _note.text.trim().isEmpty ? null : _note.text.trim(),
        impact: widget.record.impact,
        evidenceReference: widget.record.evidenceReference,
        hours: hours,
        repetitions: count,
        tags: widget.record.tags,
        relatedGoalId: widget.record.relatedGoalId,
        relatedRequirementId: widget.record.relatedRequirementId,
        relatedTaskId: widget.record.relatedTaskId,
        highlight: widget.record.highlight,
        trackingKey: widget.record.trackingKey,
        outcome: _outcome,
        createdAt: widget.record.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
