import 'dart:convert';

import 'package:file_picker/file_picker.dart';
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
import 'package:firepath/services/scored_skill_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';
import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/widgets/portfolio_backup_sheet.dart';

enum _CareerFilter {
  all,
  calls,
  skills,
  training,
  driving,
  exposures,
  leadership,
  achievements,
}

enum _RecordSort {
  newest,
  oldest,
  highestRanked,
  lowestRanked,
  title,
}

enum _RecordPeriod { month, year, custom, career }

extension _RecordSortX on _RecordSort {
  String get label => switch (this) {
        _RecordSort.newest => 'Newest first',
        _RecordSort.oldest => 'Oldest first',
        _RecordSort.highestRanked => 'Highest ranked',
        _RecordSort.lowestRanked => 'Lowest ranked',
        _RecordSort.title => 'Name A–Z',
      };
}

extension _CareerFilterX on _CareerFilter {
  String get label => switch (this) {
        _CareerFilter.all => 'ALL',
        _CareerFilter.calls => 'CALLS',
        _CareerFilter.skills => 'SKILLS',
        _CareerFilter.training => 'TRAINING',
        _CareerFilter.driving => 'DRIVING',
        _CareerFilter.exposures => 'EXPOSURES',
        _CareerFilter.leadership => 'LEADERSHIP',
        _CareerFilter.achievements => 'ACHIEVEMENTS',
      };
}

class CareerRecordV2Page extends StatefulWidget {
  final bool embedded;

  const CareerRecordV2Page({super.key, this.embedded = false});

  @override
  State<CareerRecordV2Page> createState() => _CareerRecordV2PageState();
}

class _CareerRecordV2PageState extends State<CareerRecordV2Page> {
  final CareerRecordStore _store = CareerRecordStore();
  final ScoredSkillStore _scoredSkillStore = ScoredSkillStore();
  final TextEditingController _search = TextEditingController();
  List<CareerRecord> _records = const [];
  List<ScoredSkillPreference> _scoredSkills = const [];
  bool _loading = true;
  _RecordPeriod _period = _RecordPeriod.career;
  DateTime _periodAnchor = DateTime.now();
  DateTimeRange? _customRange;
  _CareerFilter _filter = _CareerFilter.all;
  _RecordSort _sort = _RecordSort.newest;
  String? _activityTitle;

  Future<void> _pickFilter() async {
    final selected = await showModalBottomSheet<_CareerFilter>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filter records',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose one filter to keep the log clean and focused.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _CareerFilter.values
                      .map(
                        (filter) => ChoiceChip(
                          label: Text(filter.label),
                          selected: filter == _filter,
                          onSelected: (_) => Navigator.pop(sheetContext, filter),
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

    if (selected != null && mounted) setState(() => _filter = selected);
  }

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
    final scoredSkills = await _scoredSkillStore.load();
    records.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _records = records;
      _scoredSkills = scoredSkills;
      _loading = false;
    });
  }

  List<CareerRecord> get _periodRecords {
    return _records.where((record) {
      return switch (_period) {
        _RecordPeriod.career => true,
        _RecordPeriod.year => record.date.year == _periodAnchor.year,
        _RecordPeriod.month =>
          record.date.year == _periodAnchor.year &&
              record.date.month == _periodAnchor.month,
        _RecordPeriod.custom => _customRange == null ||
            (!record.date.isBefore(_startOfDay(_customRange!.start)) &&
                !record.date.isAfter(_endOfDay(_customRange!.end))),
      };
    }).toList();
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  String get _periodLabel => switch (_period) {
        _RecordPeriod.career => 'All time',
        _RecordPeriod.year => '${_periodAnchor.year}',
        _RecordPeriod.month =>
          '${_monthName(_periodAnchor.month)} ${_periodAnchor.year}',
        _RecordPeriod.custom => _customRange == null
            ? 'Choose dates'
            : '${CareerStats.formatDate(_customRange!.start)} – ${CareerStats.formatDate(_customRange!.end)}',
      };

  static String _monthName(int month) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][month - 1];

  static String _shortWeekday(int weekday) => const [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][weekday - 1];

  Future<void> _setPeriod(_RecordPeriod period) async {
    if (period == _RecordPeriod.custom) {
      final now = DateTime.now();
      final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(1970),
        lastDate: now,
        initialDateRange: _customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            ),
      );
      if (selected == null || !mounted) return;
      setState(() {
        _period = period;
        _customRange = selected;
      });
      return;
    }
    setState(() => _period = period);
  }

  void _movePeriod(int direction) {
    setState(() {
      if (_period == _RecordPeriod.month) {
        _periodAnchor = DateTime(
          _periodAnchor.year,
          _periodAnchor.month + direction,
          1,
        );
      } else if (_period == _RecordPeriod.year) {
        _periodAnchor = DateTime(_periodAnchor.year + direction);
      }
    });
  }

  List<MapEntry<String, List<CareerRecord>>> get _timelineGroups {
    final grouped = <String, List<CareerRecord>>{};
    for (final record in _visibleRecords) {
      final label = _period == _RecordPeriod.month
          ? '${_shortWeekday(record.date.weekday)}, ${_monthName(record.date.month).substring(0, 3)} ${record.date.day}'
          : '${_monthName(record.date.month)} ${record.date.year}';
      (grouped[label] ??= <CareerRecord>[]).add(record);
    }
    return grouped.entries.toList();
  }

  List<CareerRecord> get _visibleRecords {
    final query = _search.text.trim().toLowerCase();
    final records = _periodRecords.where((record) {
      if (!_matchesFilter(record)) return false;
      if (_activityTitle != null &&
          record.title.trim().toLowerCase() != _activityTitle!.toLowerCase()) {
        return false;
      }
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

    records.sort((a, b) => switch (_sort) {
          _RecordSort.newest => b.date.compareTo(a.date),
          _RecordSort.oldest => a.date.compareTo(b.date),
          _RecordSort.highestRanked =>
            _priorityOf(b).compareTo(_priorityOf(a)),
          _RecordSort.lowestRanked =>
            _priorityOf(a).compareTo(_priorityOf(b)),
          _RecordSort.title =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        });
    return records;
  }

  int _priorityOf(CareerRecord record) =>
      (record.details['priorityRank'] as num?)?.toInt() ?? 0;

  List<MapEntry<String, int>> get _activityCounts {
    final counts = <String, int>{};
    final labels = <String, String>{};
    for (final record in _periodRecords) {
      final title = record.title.trim();
      if (title.isEmpty) continue;
      final key = title.toLowerCase();
      labels[key] = labels[key] ?? title;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries = counts.entries
        .map((entry) => MapEntry(labels[entry.key]!, entry.value))
        .toList();
    entries.sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
    return entries;
  }

  Future<void> _pickSort() async {
    final selected = await showModalBottomSheet<_RecordSort>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _RecordSort.values
              .map(
                (sort) => RadioListTile<_RecordSort>(
                  value: sort,
                  groupValue: _sort,
                  title: Text(sort.label),
                  onChanged: (value) => Navigator.pop(sheetContext, value),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _sort = selected);
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
        // This screen is frequently opened via `context.go('/log')`, which can
        // replace the current route and leave no stack to pop. Always provide
        // a reliable way back to Home.
        leading: widget.embedded ? null : const AppBackButton.toHome(),
        subtitle: 'Records',
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
            tooltip: 'Quick Add',
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
      floatingActionButton: widget.embedded
          ? null
          : FloatingActionButton.extended(
              onPressed: _openQuickLog,
              icon: const Icon(Icons.add),
              label: const Text('Quick Add'),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Your detailed career log'),
                  subtitle: const Text(
                    'Use Quick Add to capture a record, then search, filter, and edit its details here.',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _PeriodControls(
                period: _period,
                label: _periodLabel,
                onPeriodChanged: _setPeriod,
                onPrevious: _period == _RecordPeriod.month ||
                        _period == _RecordPeriod.year
                    ? () => _movePeriod(-1)
                    : null,
                onNext: _period == _RecordPeriod.month ||
                        _period == _RecordPeriod.year
                    ? () => _movePeriod(1)
                    : null,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search all records',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.tonalIcon(
                        onPressed: _pickFilter,
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: Text('Filter: ${_filter.label}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _pickSort,
                        icon: const Icon(Icons.sort_rounded),
                        label: Text(_sort.label),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.insights_outlined),
                  title: Text(
                    '${_periodRecords.length} record${_periodRecords.length == 1 ? '' : 's'} in $_periodLabel',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${stats.calls} calls • ${stats.skillRepetitions} skill reps • ${stats.trainingLabel} training',
                  ),
                ),
              ),
              if (_activityCounts.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'LOGGED ACTIVITIES',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    if (_activityTitle != null)
                      TextButton(
                        onPressed: () => setState(() => _activityTitle = null),
                        child: const Text('Show all'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap an activity to show only those entries, then choose how to sort them.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _activityCounts
                      .map(
                        (entry) => FilterChip(
                          label: Text('${entry.key}  ${entry.value}'),
                          selected: _activityTitle?.toLowerCase() ==
                              entry.key.toLowerCase(),
                          onSelected: (selected) => setState(
                            () => _activityTitle = selected ? entry.key : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
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
                  '${_periodLabel.toUpperCase()} STATS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                _SummaryGrid(stats: stats),
                if (_scoredSkills.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SCORED SKILLS',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _chooseScoredSkills,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Choose'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Success percentages are shown only for the skills you choose to score.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (procedureStats.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'No measured attempts yet for your selected skills. Log a skill as Successful or Unsuccessful to start the score.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...procedureStats.take(12).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ProcedureRateCard(item: item),
                          ),
                        ),
                ] else ...[
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    onPressed: _chooseScoredSkills,
                    icon: const Icon(Icons.add_chart_outlined),
                    label: const Text('Choose skills to score'),
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  _activityTitle == null
                      ? 'TIMELINE'
                      : '${_activityTitle!.toUpperCase()} TIMELINE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                if (visible.isEmpty)
                  _EmptyHistory(onLog: _openQuickLog)
                else
                  ..._timelineGroups.expand(
                    (group) => [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                        child: Text(
                          group.key.toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ),
                      ...group.value.map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _RecordCard(
                            record: record,
                            onOpen: () => _editRecord(record),
                            onEdit: () => _editRecord(record),
                            onDelete: () => _deleteRecord(record),
                          ),
                        ),
                      ),
                    ],
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
    final enabled = {
      for (final skill in _scoredSkills) skill.keyName: skill.title,
    };
    final grouped = <String, List<CareerRecord>>{};
    for (final record in records) {
      final key = CareerStats.skillTrackingKey(record);
      if (key == null || !enabled.containsKey(key)) continue;
      if (record.outcome != CareerRecordOutcome.successful &&
          record.outcome != CareerRecordOutcome.unsuccessful &&
          record.outcome != CareerRecordOutcome.attempted) {
        continue;
      }
      (grouped[key] ??= <CareerRecord>[]).add(record);
    }
    final result = <_ProcedureStat>[];
    for (final entry in grouped.entries) {
      final measured = CareerStats.successFor(entry.value);
      if (measured.attempts <= 0) continue;
      result.add(
        _ProcedureStat(
          title: enabled[entry.key] ?? entry.value.first.title,
          keyName: entry.key,
          stats: measured,
        ),
      );
    }
    result.sort((a, b) => b.stats.attempts.compareTo(a.stats.attempts));
    return result;
  }

  Future<void> _chooseScoredSkills() async {
    const defaults = <String>[
      'IV / vascular access',
      'Airway management',
      'Intubation',
      'IO access',
      'Medication administration',
      'Patient assessment',
      'Pump operations',
      'Ground ladders',
      'Hose advancement',
      'Search and rescue',
    ];

    final titlesByKey = <String, String>{
      for (final title in defaults)
        ScoredSkillStore.keyForTitle(title): title,
      for (final record in _records)
        if (record.type == CareerRecordType.skill &&
            !CareerStats.isDrivingRecord(record))
          CareerStats.skillTrackingKey(record) ?? 
              ScoredSkillStore.keyForTitle(record.title): record.title,
      for (final item in _scoredSkills) item.keyName: item.title,
    };

    final selected = _scoredSkills.map((item) => item.keyName).toSet();
    final custom = TextEditingController();

    final result = await showModalBottomSheet<List<ScoredSkillPreference>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              18 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose scored skills',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Only selected skills show a success percentage. Other skills still count as repetitions without a score.',
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: titlesByKey.entries.map((entry) {
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selected.contains(entry.key),
                        title: Text(entry.value),
                        subtitle: Text(entry.key),
                        onChanged: (value) => setSheetState(() {
                          if (value == true) {
                            selected.add(entry.key);
                          } else {
                            selected.remove(entry.key);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: custom,
                        decoration: const InputDecoration(
                          labelText: 'Add another skill',
                          hintText: 'Example: CPAP placement',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Add skill',
                      onPressed: () {
                        final title = custom.text.trim();
                        if (title.isEmpty) return;
                        final key = ScoredSkillStore.keyForTitle(title);
                        setSheetState(() {
                          titlesByKey[key] = title;
                          selected.add(key);
                          custom.clear();
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    sheetContext,
                    titlesByKey.entries
                        .where((entry) => selected.contains(entry.key))
                        .map(
                          (entry) => ScoredSkillPreference(
                            keyName: entry.key,
                            title: entry.value,
                          ),
                        )
                        .toList(growable: false),
                  ),
                  child: const Text('Save scored skills'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    custom.dispose();

    if (result == null || !mounted) return;
    await _scoredSkillStore.save(result);
    if (!mounted) return;
    setState(() => _scoredSkills = result);
  }

  Future<void> _openQuickLog() async {
    await QuickLogLauncher.open(context);
    await _load();
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
  final _RecordPeriod period;
  final String label;
  final ValueChanged<_RecordPeriod> onPeriodChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PeriodControls({
    required this.period,
    required this.label,
    required this.onPeriodChanged,
    required this.onPrevious,
    required this.onNext,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_RecordPeriod>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: _RecordPeriod.month,
                label: Text('MONTH'),
              ),
              ButtonSegment(
                value: _RecordPeriod.year,
                label: Text('YEAR'),
              ),
              ButtonSegment(
                value: _RecordPeriod.custom,
                label: Text('CUSTOM'),
              ),
              ButtonSegment(
                value: _RecordPeriod.career,
                label: Text('ALL'),
              ),
            ],
            selected: {period},
            onSelectionChanged: (selection) => onPeriodChanged(selection.first),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Previous period',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: period == _RecordPeriod.custom
                      ? () => onPeriodChanged(_RecordPeriod.custom)
                      : null,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Next period',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
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
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  '${item.stats.successful} successful • ${item.stats.unsuccessful} unsuccessful • ${item.stats.attempts} attempts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _recordColor(record);
    final amount = record.hours != null
        ? CareerStats.formatDurationHours(record.hours!)
        : record.repetitions > 1
            ? '${record.repetitions} attempts/reps'
            : null;
    final details = <String>[
      record.category,
      if (amount != null) amount,
      if (record.outcome != null) record.outcome!.label,
      if (_priority(record) > 0) 'Rank ${_priority(record)}/5',
    ].where((value) => value.trim().isNotEmpty).join(' • ');

    final photoCount =
        (record.details['photoAttachments'] as List?)?.length ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_icon(record), color: accent, size: 23),
              ),
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
                    if ((record.summary ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.summary!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.3,
                            ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          CareerStats.formatDate(record.date),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        if (_priority(record) > 0) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(
                            '${_priority(record)}/5',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber.shade900,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (photoCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Badge(
                    label: Text('$photoCount'),
                    child: const Icon(Icons.photo_library_outlined, size: 20),
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: 'Record options',
                onSelected: (value) {
                  if (value == 'open') onOpen();
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'open', child: Text('Open full log')),
                  PopupMenuItem(value: 'edit', child: Text('Edit details')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _priority(CareerRecord record) =>
      (record.details['priorityRank'] as num?)?.toInt() ?? 0;

  static Color _recordColor(CareerRecord record) {
    if (CareerStats.isExposureRecord(record)) return const Color(0xFFEA580C);
    if (CareerStats.isDrivingRecord(record)) return const Color(0xFFD97706);
    return switch (record.type) {
      CareerRecordType.operationalExperience => const Color(0xFFDC2626),
      CareerRecordType.skill => const Color(0xFF0D9488),
      CareerRecordType.training => const Color(0xFF2563EB),
      CareerRecordType.achievement => const Color(0xFFCA8A04),
      CareerRecordType.leadership => const Color(0xFF7C3AED),
      CareerRecordType.teaching => const Color(0xFF7C3AED),
      CareerRecordType.project => const Color(0xFF6366F1),
      CareerRecordType.education => const Color(0xFF0284C7),
      CareerRecordType.taskBookEvidence => const Color(0xFF475569),
    };
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
              label: const Text('Quick Add'),
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
  late final TextEditingController _role =
      TextEditingController(text: widget.record.roleOrAssignment ?? '');
  late final TextEditingController _impact =
      TextEditingController(text: widget.record.impact ?? '');
  late final TextEditingController _evidence =
      TextEditingController(text: widget.record.evidenceReference ?? '');
  late final TextEditingController _tags =
      TextEditingController(text: widget.record.tags.join(', '));
  late List<Map<String, dynamic>> _photos =
      ((widget.record.details['photoAttachments'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
  late CareerRecordOutcome? _outcome = widget.record.outcome;
  late bool _highlight = widget.record.highlight;
  late int _priorityRank =
      (widget.record.details['priorityRank'] as num?)?.toInt() ?? 0;
  late DateTime _date = widget.record.date;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _count.dispose();
    _hours.dispose();
    _note.dispose();
    _role.dispose();
    _impact.dispose();
    _evidence.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Full log details'),
      content: SizedBox(
        width: 620,
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
                initialValue: _outcome,
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
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _highlight,
                onChanged: (value) => setState(() => _highlight = value ?? false),
                title: const Text('Show as a career milestone on Timeline'),
                controlAffinity: ListTileControlAffinity.leading,
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
                controller: _role,
                decoration: const InputDecoration(
                  labelText: 'Your role or assignment',
                  hintText: 'Lead medic, driver, instructor, acting officer',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Detailed narrative',
                  hintText: 'What happened, what you did, and what you learned',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _impact,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Result or impact',
                  hintText: 'Outcome, improvement, recognition, or lesson',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _evidence,
                decoration: const InputDecoration(
                  labelText: 'Supporting reference',
                  hintText: 'Course number, incident number, certificate, or document',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'leadership, airway, driver training',
                  helperText: 'Separate tags with commas',
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'IMPORTANCE RANK',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Not ranked'),
                    selected: _priorityRank == 0,
                    onSelected: (_) => setState(() => _priorityRank = 0),
                  ),
                  ...List.generate(5, (index) {
                    final rank = index + 1;
                    return ChoiceChip(
                      avatar: Icon(
                        rank <= _priorityRank
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 18,
                      ),
                      label: Text(
                        rank == 1 ? '1 Low' : rank == 5 ? '5 High' : '$rank',
                      ),
                      selected: rank == _priorityRank,
                      onSelected: (_) => setState(() => _priorityRank = rank),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'PHOTOS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _photos.length >= 6 ? null : _addPhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add photos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_photos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Add up to 6 photos of certificates, training, equipment, or other supporting evidence. Do not attach patient-identifying information.',
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_photos.length, (index) {
                    final photo = _photos[index];
                    final encoded = photo['data'] as String? ?? '';
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: encoded.isEmpty
                              ? const SizedBox(
                                  width: 92,
                                  height: 92,
                                  child: ColoredBox(color: Colors.black12),
                                )
                              : Image.memory(
                                  base64Decode(encoded),
                                  width: 92,
                                  height: 92,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    width: 92,
                                    height: 92,
                                    child: ColoredBox(color: Colors.black12),
                                  ),
                                ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: IconButton.filled(
                            tooltip: 'Remove photo',
                            visualDensity: VisualDensity.compact,
                            iconSize: 16,
                            onPressed: () => setState(() => _photos.removeAt(index)),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    );
                  }),
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
          child: const Text('Save full log'),
        ),
      ],
    );
  }

  Future<void> _addPhotos() async {
    final remaining = 6 - _photos.length;
    if (remaining <= 0) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) return;

    final additions = <Map<String, dynamic>>[];
    var skippedLarge = false;
    for (final file in result.files.take(remaining)) {
      final bytes = file.bytes;
      if (bytes == null) continue;
      if (bytes.length > 5 * 1024 * 1024) {
        skippedLarge = true;
        continue;
      }
      additions.add({
        'name': file.name,
        'data': base64Encode(bytes),
        'addedAt': DateTime.now().toIso8601String(),
      });
    }
    setState(() => _photos.addAll(additions));
    if (skippedLarge && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos larger than 5 MB were skipped.')),
      );
    }
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
        roleOrAssignment:
            _role.text.trim().isEmpty ? null : _role.text.trim(),
        summary: _note.text.trim().isEmpty ? null : _note.text.trim(),
        impact: _impact.text.trim().isEmpty ? null : _impact.text.trim(),
        evidenceReference:
            _evidence.text.trim().isEmpty ? null : _evidence.text.trim(),
        hours: hours,
        repetitions: count,
        tags: _tags.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList(),
        relatedGoalId: widget.record.relatedGoalId,
        relatedRequirementId: widget.record.relatedRequirementId,
        relatedTaskId: widget.record.relatedTaskId,
        highlight: _highlight,
        trackingKey: widget.record.trackingKey,
        outcome: _outcome,
        details: {
          ...widget.record.details,
          'photoAttachments': _photos,
          'priorityRank': _priorityRank,
          'fullLog': true,
        },
        createdAt: widget.record.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
