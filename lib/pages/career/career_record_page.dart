import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/career_stats.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

enum _RecordFilter {
  all,
  calls,
  skills,
  training,
  driving,
  leadership,
  teaching,
  achievements,
  projects,
  taskBook,
  education,
}

extension on _RecordFilter {
  String get label => switch (this) {
        _RecordFilter.all => 'ALL',
        _RecordFilter.calls => 'CALLS',
        _RecordFilter.skills => 'SKILLS',
        _RecordFilter.training => 'TRAINING',
        _RecordFilter.driving => 'DRIVING',
        _RecordFilter.leadership => 'LEADERSHIP',
        _RecordFilter.teaching => 'TEACHING',
        _RecordFilter.achievements => 'ACHIEVEMENTS',
        _RecordFilter.projects => 'PROJECTS',
        _RecordFilter.taskBook => 'TASK BOOK',
        _RecordFilter.education => 'EDUCATION',
      };
}

class CareerRecordPage extends StatefulWidget {
  const CareerRecordPage({super.key});

  @override
  State<CareerRecordPage> createState() => _CareerRecordPageState();
}

class _CareerRecordPageState extends State<CareerRecordPage> {
  final CareerRecordStore _store = CareerRecordStore();
  final TextEditingController _search = TextEditingController();

  List<CareerRecord> _records = const [];
  bool _loading = true;
  bool _careerView = false;
  late int _year = DateTime.now().year;
  _RecordFilter _filter = _RecordFilter.all;

  @override
  void initState() {
    super.initState();
    _search.addListener(_refreshSearch);
    _load();
  }

  @override
  void dispose() {
    _search.removeListener(_refreshSearch);
    _search.dispose();
    super.dispose();
  }

  void _refreshSearch() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
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
    if (!_careerView) items = items.where((record) => record.date.year == _year);
    items = items.where(_matchesFilter);
    if (query.isNotEmpty) {
      items = items.where((record) {
        final haystack = [
          record.title,
          record.category,
          record.summary ?? '',
          record.roleOrAssignment ?? '',
          record.tags.join(' '),
          record.relatedGoalId ?? '',
          record.relatedRequirementId ?? '',
          record.relatedTaskId ?? '',
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      });
    }
    return items.toList();
  }

  bool _matchesFilter(CareerRecord record) => switch (_filter) {
        _RecordFilter.all => true,
        _RecordFilter.calls =>
          record.type == CareerRecordType.operationalExperience,
        _RecordFilter.skills => record.type == CareerRecordType.skill &&
            !CareerStats.isDrivingRecord(record),
        _RecordFilter.training => record.type == CareerRecordType.training,
        _RecordFilter.driving => CareerStats.isDrivingRecord(record),
        _RecordFilter.leadership => record.type == CareerRecordType.leadership,
        _RecordFilter.teaching => record.type == CareerRecordType.teaching,
        _RecordFilter.achievements =>
          record.type == CareerRecordType.achievement,
        _RecordFilter.projects => record.type == CareerRecordType.project,
        _RecordFilter.taskBook =>
          record.type == CareerRecordType.taskBookEvidence ||
              record.relatedRequirementId != null,
        _RecordFilter.education => record.type == CareerRecordType.education,
      };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final visible = _visible;
    final stats = CareerStats.fromRecords(visible);

    return Scaffold(
      appBar: AppBar(
        title: Text(_careerView ? 'Career Record' : 'Career Record $_year'),
        actions: [
          IconButton(
            tooltip: 'Quick Log',
            onPressed: _openQuickLog,
            icon: const Icon(Icons.add_task),
          ),
          PopupMenuButton<String>(
            tooltip: 'Career record tools',
            onSelected: (value) {
              if (value == 'advanced') {
                context.push(AppRoutes.personalLogLegacy);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'advanced',
                child: ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('Advanced log tools'),
                  subtitle: Text('Quick actions, backup, restore, and evidence'),
                ),
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
                search: _search,
                onToggleView: (value) => setState(() => _careerView = value),
                onPickYear: _careerView ? null : _pickYear,
              ),
              const SizedBox(height: AppSpacing.md),
              _FilterRow(
                selected: _filter,
                onSelected: (filter) => setState(() => _filter = filter),
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
                  _EmptyState(onQuickLog: _openQuickLog)
                else
                  ...visible.map((record) => _RecordTile(
                        record: record,
                        taskBookLabel: _taskBookLabel(app, record),
                        onEdit: () => _editRecord(record),
                        onDelete: () => _deleteRecord(record),
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

  Future<void> _openQuickLog() async {
    await QuickLogLauncher.open(context);
    await _load();
  }

  Future<void> _pickYear() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _YearPickerSheet(
        selected: _year,
        years: CareerStats.availableYears(_records),
      ),
    );
    if (picked != null && mounted) setState(() => _year = picked);
  }

  String? _taskBookLabel(AppState app, CareerRecord record) {
    if (record.relatedRequirementId == null) return null;
    final roadmap = app.roadmap;
    if (roadmap == null || roadmap.goal.id != record.relatedGoalId) {
      return 'Task Book linked';
    }
    final match = roadmap.all
        .where((item) => item.requirement.id == record.relatedRequirementId)
        .firstOrNull;
    return match == null
        ? 'Task Book linked'
        : '${roadmap.goal.title} • ${match.requirement.name}';
  }

  Future<void> _deleteRecord(CareerRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete career record?'),
        content: Text(
          '${record.title} from ${CareerStats.formatDate(record.date)} will be permanently removed from this device.',
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

    final deleted = await _store.delete(record);
    if (!deleted) {
      _showMessage('This record could not be deleted. No other records changed.');
      return;
    }

    await _adjustNumericProgress(record, -1);
    final remaining = await _store.load();
    await _resetTaskPracticeIfNeeded(record, remaining);
    if (!mounted) return;
    setState(() {
      _records = remaining..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _editRecord(CareerRecord existing) async {
    final result = await showDialog<CareerRecord>(
      context: context,
      builder: (dialogContext) => _RecordEditorDialog(record: existing),
    );
    if (result == null) return;

    final saved = await _store.upsert(result);
    if (!saved) {
      _showMessage('Changes could not be saved. The original record is unchanged.');
      return;
    }

    if (existing.date.year != result.date.year) {
      final removed = await _store.delete(existing);
      if (!removed) {
        _showMessage(
            'Changes were saved, but the old yearly copy could not be removed. Review the history for a duplicate.');
      }
    }

    await _adjustNumericProgress(existing, -1);
    await _adjustNumericProgress(result, 1);
    await _load();
  }

  Future<void> _adjustNumericProgress(
      CareerRecord record, double direction) async {
    if (!record.tags.contains('task-book-progress-applied')) return;
    final goalId = record.relatedGoalId;
    final requirementId = record.relatedRequirementId;
    if (goalId == null || requirementId == null) return;
    final app = context.read<AppState>();
    final roadmap = app.roadmap;
    if (roadmap == null || roadmap.goal.id != goalId) return;
    final requirement = roadmap.all
        .where((item) => item.requirement.id == requirementId)
        .map((item) => item.requirement)
        .firstOrNull;
    if (requirement?.type != RequirementType.numericProgress ||
        requirement?.progressRequired == null ||
        requirement!.progressRequired! <= 0) {
      return;
    }
    final delta = record.hours ?? record.repetitions.toDouble();
    final next = (requirement.progressCurrent ?? 0) + (delta * direction);
    await app.setNumericProgress(
      goalId: goalId,
      requirementId: requirementId,
      current: next < 0 ? 0 : next,
      required: requirement.progressRequired!,
      unit: requirement.progressUnit,
    );
  }

  Future<void> _resetTaskPracticeIfNeeded(
      CareerRecord deleted, List<CareerRecord> remaining) async {
    final goalId = deleted.relatedGoalId;
    final requirementId = deleted.relatedRequirementId;
    final taskId = deleted.relatedTaskId;
    if (goalId == null || requirementId == null || taskId == null) return;
    if (remaining.any((record) =>
        record.relatedGoalId == goalId &&
        record.relatedRequirementId == requirementId &&
        record.relatedTaskId == taskId)) {
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RecordEditorDialog extends StatefulWidget {
  final CareerRecord record;
  const _RecordEditorDialog({required this.record});

  @override
  State<_RecordEditorDialog> createState() => _RecordEditorDialogState();
}

class _RecordEditorDialogState extends State<_RecordEditorDialog> {
  late CareerRecordType _type = widget.record.type;
  late DateTime _date = widget.record.date;
  late CareerRecordOutcome? _outcome = widget.record.outcome;
  late final TextEditingController _title =
      TextEditingController(text: widget.record.title);
  late final TextEditingController _category =
      TextEditingController(text: widget.record.category);
  late final TextEditingController _role =
      TextEditingController(text: widget.record.roleOrAssignment ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.record.summary ?? '');
  late final TextEditingController _hours = TextEditingController(
      text: widget.record.hours?.toString() ?? '');
  late final TextEditingController _repetitions =
      TextEditingController(text: widget.record.repetitions.toString());

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _role.dispose();
    _note.dispose();
    _hours.dispose();
    _repetitions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit career record'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<CareerRecordType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: CareerRecordType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _category,
                decoration:
                    const InputDecoration(labelText: 'Category (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _repetitions,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Count / reps'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _hours,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Hours (optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _role,
                decoration:
                    const InputDecoration(labelText: 'Role / assignment (optional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CareerRecordOutcome?>(
                value: _outcome,
                decoration:
                    const InputDecoration(labelText: 'Outcome (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Not tracked')),
                  ...CareerRecordOutcome.values.map((outcome) =>
                      DropdownMenuItem(
                          value: outcome, child: Text(outcome.label))),
                ],
                onChanged: (value) => setState(() => _outcome = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(CareerStats.formatDate(_date)),
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
          child: const Text('Save changes'),
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
    if (picked == null) return;
    setState(() => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ));
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final reps = int.tryParse(_repetitions.text.trim()) ?? 1;
    final hoursText = _hours.text.trim();
    final hours = hoursText.isEmpty ? null : double.tryParse(hoursText);
    if (reps <= 0 || (hoursText.isNotEmpty && (hours == null || hours <= 0))) {
      return;
    }
    Navigator.pop(
      context,
      CareerRecord(
        id: widget.record.id,
        type: _type,
        title: title,
        category: _category.text.trim(),
        date: _date,
        roleOrAssignment: _role.text.trim().isEmpty ? null : _role.text.trim(),
        summary: _note.text.trim().isEmpty ? null : _note.text.trim(),
        impact: widget.record.impact,
        evidenceReference: widget.record.evidenceReference,
        hours: hours,
        repetitions: reps,
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

class _TopControls extends StatelessWidget {
  final bool careerView;
  final int year;
  final ValueChanged<bool> onToggleView;
  final VoidCallback? onPickYear;
  final TextEditingController search;

  const _TopControls({
    required this.careerView,
    required this.year,
    required this.onToggleView,
    required this.onPickYear,
    required this.search,
  });

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
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('THIS YEAR')),
                  ButtonSegment(value: true, label: Text('CAREER')),
                ],
                selected: {careerView},
                onSelectionChanged: (selection) =>
                    onToggleView(selection.first),
              ),
              if (!careerView)
                FilledButton.tonalIcon(
                  onPressed: onPickYear,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(year.toString()),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search calls, skills, training, goals, tasks…',
            filled: true,
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _RecordFilter selected;
  final ValueChanged<_RecordFilter> onSelected;

  const _FilterRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _RecordFilter.values
            .map((filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: selected == filter,
                    onSelected: (_) => onSelected(filter),
                  ),
                ))
            .toList(),
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
      if (stats.calls > 0)
        _StatItem('Calls', '${stats.calls}', Icons.local_fire_department),
      if (stats.skillRepetitions > 0)
        _StatItem('Skill reps', '${stats.skillRepetitions}', Icons.handyman),
      if (stats.trainingHours > 0)
        _StatItem('Training', stats.trainingLabel, Icons.school),
      if (stats.driveHours > 0)
        _StatItem('Drive time', stats.driveLabel, Icons.local_shipping),
      if (stats.teachingHours > 0)
        _StatItem('Teaching', stats.teachingLabel, Icons.record_voice_over),
      if (stats.leadershipCount > 0)
        _StatItem('Leadership', '${stats.leadershipCount}', Icons.groups),
      if (stats.achievements > 0)
        _StatItem('Achievements', '${stats.achievements}', Icons.emoji_events),
      if (stats.awards > 0)
        _StatItem('Awards', '${stats.awards}', Icons.military_tech),
      if (stats.projects > 0)
        _StatItem('Projects', '${stats.projects}', Icons.assignment_turned_in),
      if (stats.taskBookUpdates > 0)
        _StatItem('Task Book', '${stats.taskBookUpdates}', Icons.fact_check),
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
        if (items.isEmpty)
          Text('No activity recorded for this view yet.',
              style: Theme.of(context).textTheme.bodyMedium)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 3 : 2;
              return GridView.builder(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: columns == 3 ? 2.5 : 2.05,
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
          Icon(item.icon, color: cs.primary),
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
  final String? taskBookLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordTile({
    required this.record,
    required this.taskBookLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amount = record.hours != null
        ? CareerStats.formatDurationHours(record.hours!)
        : record.repetitions > 1
            ? '${record.repetitions} reps'
            : null;
    final details = <String>[
      record.type.label,
      if (record.category.trim().isNotEmpty) record.category,
      if (amount != null) amount,
      if (record.outcome != null) record.outcome!.label,
    ];

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
          Icon(_recordIcon(record), color: cs.primary),
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
                Text(details.join(' • '),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                if (taskBookLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(taskBookLabel!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.primary, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 5),
                Text(CareerStats.formatDate(record.date),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
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

  static IconData _recordIcon(CareerRecord record) {
    if (CareerStats.isDrivingRecord(record)) return Icons.local_shipping;
    return switch (record.type) {
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
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onQuickLog;
  const _EmptyState({required this.onQuickLog});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nothing here yet.',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
              'Use Quick Log to capture calls, skills, training, drive time, leadership, achievements, and Task Book progress.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onQuickLog,
            icon: const Icon(Icons.add_task),
            label: const Text('Quick Log'),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
}

class _YearPickerSheet extends StatelessWidget {
  final int selected;
  final List<int> years;

  const _YearPickerSheet({required this.selected, required this.years});

  @override
  Widget build(BuildContext context) {
    final available = years.isEmpty ? [DateTime.now().year] : years;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select year',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: available
                  .map((year) => ChoiceChip(
                        label: Text('$year'),
                        selected: year == selected,
                        onSelected: (_) => context.pop(year),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
