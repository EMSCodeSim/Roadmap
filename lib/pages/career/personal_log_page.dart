import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/quick_log_tracker.dart';
import 'package:firepath/models/quick_log_template.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/quick_log_preferences_store.dart';
import 'package:firepath/widgets/portfolio_backup_sheet.dart';

class PersonalLogPage extends StatefulWidget {
  final LogPrefill? prefill;
  const PersonalLogPage({super.key, this.prefill});

  @override
  State<PersonalLogPage> createState() => _PersonalLogPageState();
}

class _PersonalLogPageState extends State<PersonalLogPage> {
  final CareerRecordStore _store = CareerRecordStore();
  final QuickLogPreferencesStore _preferences = QuickLogPreferencesStore();
  final TextEditingController _searchController = TextEditingController();

  List<CareerRecord> _records = <CareerRecord>[];
  QuickLogConfig _config = QuickLogConfig(
    rolePreset: QuickLogRolePreset.firefighter,
    pinnedKeys: QuickLogCatalog.defaultsFor(QuickLogRolePreset.firefighter),
    customTrackers: const [],
  );
  bool _loading = true;
  int? _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final records = await _store.load();
    final preferences = await _preferences.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _config = _configFromPreferences(preferences);
      _loading = false;
    });

    final prefill = widget.prefill;
    if (prefill != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openLogEditor(
          initialTitle: prefill.title,
          initialCategory: prefill.category,
          relatedGoalId: prefill.relatedGoalId,
          relatedRequirementId: prefill.relatedRequirementId,
          initialTags: prefill.tags,
        );
      });
    }
  }

  static QuickLogConfig _configFromPreferences(
    QuickLogPreferences preferences,
  ) {
    final customTrackers = preferences.customTemplates
        .map(
          (template) => QuickLogTracker(
            keyName: template.id,
            title: template.title,
            category: template.category,
            type: template.type,
            iconName: template.iconKey,
            tracksOutcome: template.tracksOutcome,
            custom: template.isCustom,
          ),
        )
        .where(
          (tracker) =>
              tracker.keyName.isNotEmpty && tracker.title.trim().isNotEmpty,
        )
        .toList();

    return QuickLogConfig(
      rolePreset: _guessRolePreset(preferences.pinnedIds),
      pinnedKeys: preferences.pinnedIds,
      customTrackers: customTrackers,
    );
  }

  static QuickLogPreferences _preferencesFromConfig(
    QuickLogConfig config, {
    required List<String> quickActionKeys,
  }) {
    final customTemplates = config.customTrackers
        .where((tracker) => tracker.custom)
        .map(
          (tracker) => QuickLogTemplate(
            id: tracker.keyName,
            title: tracker.title,
            category: tracker.category,
            type: tracker.type,
            tracksOutcome: tracker.tracksOutcome,
            iconKey: tracker.iconName,
            isCustom: true,
          ),
        )
        .toList();

    return QuickLogPreferences(
      pinnedIds: config.pinnedKeys,
      customTemplates: customTemplates,
      quickActionKeys: quickActionKeys,
    );
  }

  static QuickLogRolePreset? _guessRolePreset(List<String> pinnedIds) {
    for (final preset in QuickLogRolePreset.values) {
      final defaults = QuickLogCatalog.defaultsFor(preset);
      if (listEquals(defaults, pinnedIds)) return preset;
    }
    return null;
  }

  List<QuickLogTracker> get _pinnedTrackers => _config.pinnedKeys
      .map((key) => QuickLogCatalog.byKey(key, _config.customTrackers))
      .whereType<QuickLogTracker>()
      .toList();

  Future<void> _quickLog(QuickLogTracker tracker) async {
    CareerRecordOutcome? outcome;
    if (tracker.tracksOutcome) {
      outcome = await _pickOutcome(tracker.title);
      if (outcome == null) return;
    }
    final now = DateTime.now();
    final record = CareerRecord(
      id: now.microsecondsSinceEpoch.toRadixString(36),
      type: tracker.type,
      title: tracker.title,
      category: tracker.category,
      date: now,
      roleOrAssignment: null,
      summary: null,
      impact: null,
      evidenceReference: null,
      hours: null,
      repetitions: 1,
      tags: const ['quick-log'],
      relatedGoalId: null,
      relatedRequirementId: null,
      highlight: false,
      trackingKey: tracker.keyName,
      outcome: outcome,
      createdAt: now,
      updatedAt: now,
    );
    final saved = await _store.upsert(record);
    if (!mounted) return;
    if (!saved) {
      _showSaveFailure();
      return;
    }
    setState(() {
      _records = [..._records, record]
        ..sort((a, b) => b.date.compareTo(a.date));
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${tracker.title}${outcome == null ? '' : ' • ${outcome.label}'} logged.',
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => _deleteRecord(record, confirm: false),
        ),
      ),
    );
  }

  Future<CareerRecordOutcome?> _pickOutcome(String title) {
    return showModalBottomSheet<CareerRecordOutcome>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'How did this attempt go?',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(sheetContext, CareerRecordOutcome.successful),
                icon: const Icon(Icons.check_circle_outline),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Successful'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(
                  sheetContext,
                  CareerRecordOutcome.unsuccessful,
                ),
                icon: const Icon(Icons.cancel_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Unsuccessful'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    Navigator.pop(sheetContext, CareerRecordOutcome.attempted),
                child: const Text('Log attempt without outcome'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This entry could not be saved. Your existing log was not changed.',
        ),
      ),
    );
  }

  Future<void> _deleteRecord(CareerRecord record, {bool confirm = true}) async {
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete log entry?'),
          content: Text(
            '${record.title} from ${_formatDate(record.date)} will be removed.',
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
      if (ok != true) return;
    }
    final saved = await _store.delete(record);
    if (!mounted) return;
    if (!saved) {
      _showSaveFailure();
      return;
    }
    setState(
      () => _records = _records.where((e) => e.id != record.id).toList(),
    );
  }

  Future<void> _openLogEditor({
    CareerRecord? existing,
    String? initialTitle,
    String? initialCategory,
    String? relatedGoalId,
    String? relatedRequirementId,
    List<String>? initialTags,
  }) async {
    var type = existing?.type ?? CareerRecordType.operationalExperience;
    var selectedDate = existing?.date ?? DateTime.now();
    CareerRecordOutcome? outcome = existing?.outcome;
    final title = TextEditingController(
      text: existing?.title ?? (initialTitle ?? ''),
    );
    final category = TextEditingController(
      text: existing?.category ?? (initialCategory ?? ''),
    );
    final count = TextEditingController(
      text: existing?.repetitions.toString() ?? '1',
    );
    final note = TextEditingController(text: existing?.summary ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<CareerRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Log past or custom activity' : 'Edit log entry',
          ),
          content: SizedBox(
            width: 560,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Keep entries professional and non-identifying. Do not enter patient names, addresses, DOBs, or other protected information.',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<CareerRecordType>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: CareerRecordType.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setDialogState(() => type = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: title,
                      autofocus: existing == null,
                      decoration: const InputDecoration(
                        labelText: 'What are you tracking?',
                        hintText: 'Pediatric IV, vehicle fire, rope rescue…',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Add a name.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: category,
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDate,
                                firstDate: DateTime(1970),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null)
                                setDialogState(() => selectedDate = picked);
                            },
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                            ),
                            label: Text(_formatDate(selectedDate)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: count,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Count',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CareerRecordOutcome?>(
                      value: outcome,
                      decoration: const InputDecoration(
                        labelText: 'Outcome (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<CareerRecordOutcome?>(
                          value: null,
                          child: Text('Not tracked'),
                        ),
                        ...CareerRecordOutcome.values.map(
                          (value) => DropdownMenuItem<CareerRecordOutcome?>(
                            value: value,
                            child: Text(value.label),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => outcome = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: note,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Quick note (optional)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final parsedCount = int.tryParse(count.text.trim());
                final now = DateTime.now();
                final cleanTitle = title.text.trim();
                final tags =
                    existing?.tags ??
                    (initialTags == null || initialTags.isEmpty
                        ? const ['quick-log', 'custom-log']
                        : initialTags);
                Navigator.pop(
                  dialogContext,
                  CareerRecord(
                    id:
                        existing?.id ??
                        now.microsecondsSinceEpoch.toRadixString(36),
                    type: type,
                    title: cleanTitle,
                    category: category.text.trim().isEmpty
                        ? type.label
                        : category.text.trim(),
                    date: selectedDate,
                    roleOrAssignment: existing?.roleOrAssignment,
                    summary: note.text.trim().isEmpty ? null : note.text.trim(),
                    impact: existing?.impact,
                    evidenceReference: existing?.evidenceReference,
                    hours: existing?.hours,
                    repetitions: parsedCount != null && parsedCount > 0
                        ? parsedCount
                        : 1,
                    tags: tags,
                    relatedGoalId: existing?.relatedGoalId ?? relatedGoalId,
                    relatedRequirementId:
                        existing?.relatedRequirementId ?? relatedRequirementId,
                    highlight: existing?.highlight ?? false,
                    trackingKey:
                        existing?.trackingKey ?? _trackingKeyFor(cleanTitle),
                    outcome: outcome,
                    createdAt: existing?.createdAt ?? now,
                    updatedAt: now,
                  ),
                );
              },
              child: Text(existing == null ? 'Save' : 'Save changes'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    category.dispose();
    count.dispose();
    note.dispose();

    if (result == null) return;
    if (existing != null && existing.date.year != result.date.year) {
      final deleted = await _store.delete(existing);
      if (!deleted) {
        if (mounted) _showSaveFailure();
        return;
      }
    }
    final saved = await _store.upsert(result);
    if (!mounted) return;
    if (!saved) {
      _showSaveFailure();
      return;
    }
    setState(() {
      final next = _records.where((e) => e.id != result.id).toList()
        ..add(result);
      next.sort((a, b) => b.date.compareTo(a.date));
      _records = next;
    });
  }

  Future<void> _customizeQuickLog() async {
    var role = _config.rolePreset;
    var pinned = List<String>.from(_config.pinnedKeys);
    var custom = List<QuickLogTracker>.from(_config.customTrackers);

    final result = await showDialog<QuickLogConfig>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final pinnedTrackers = pinned
              .map((key) => QuickLogCatalog.byKey(key, custom))
              .whereType<QuickLogTracker>()
              .toList();
          return Dialog.fullscreen(
            child: SafeArea(
              child: Column(
                children: [
                  AppBar(
                    title: const Text('Customize Quick Log'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(
                          dialogContext,
                          QuickLogConfig(
                            rolePreset: role,
                            pinnedKeys: pinned,
                            customTrackers: custom,
                          ),
                        ),
                        child: const Text('SAVE'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Start with a role',
                          style: Theme.of(dialogContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a starting set, then make it yours.',
                          style: Theme.of(dialogContext).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: QuickLogRolePreset.values.map((preset) {
                            return ChoiceChip(
                              label: Text(preset.label),
                              selected: role == preset,
                              onSelected: (_) {
                                setDialogState(() {
                                  role = preset;
                                  pinned = QuickLogCatalog.defaultsFor(preset);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Pinned buttons',
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                final tracker = await _chooseTracker(
                                  dialogContext,
                                  pinned,
                                  custom,
                                );
                                if (tracker == null) return;
                                setDialogState(() {
                                  if (tracker.custom &&
                                      !custom.any(
                                        (e) => e.keyName == tracker.keyName,
                                      ))
                                    custom.add(tracker);
                                  if (!pinned.contains(tracker.keyName))
                                    pinned.add(tracker.keyName);
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Drag to put your most-used actions first. Aim for 6–10 buttons.',
                          style: Theme.of(dialogContext).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        if (pinnedTrackers.isEmpty)
                          const ListTile(
                            title: Text('No Quick Log buttons pinned yet.'),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pinnedTrackers.length,
                            onReorder: (oldIndex, newIndex) {
                              setDialogState(() {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final key = pinned.removeAt(oldIndex);
                                pinned.insert(newIndex, key);
                              });
                            },
                            itemBuilder: (context, index) {
                              final tracker = pinnedTrackers[index];
                              return ListTile(
                                key: ValueKey(tracker.keyName),
                                leading: Icon(_trackerIcon(tracker.iconName)),
                                title: Text(tracker.title),
                                subtitle: Text(tracker.category),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Remove',
                                      onPressed: () => setDialogState(
                                        () => pinned.remove(tracker.keyName),
                                      ),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    const Icon(Icons.drag_handle),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == null) return;
    try {
      final existing = await _preferences.load();
      await _preferences.save(
        _preferencesFromConfig(
          result,
          quickActionKeys: existing.quickActionKeys.isEmpty
              ? QuickLogPreferencesStore.defaultQuickActionKeys
              : existing.quickActionKeys,
        ),
      );
      if (!mounted) return;
      setState(() => _config = result);
    } catch (e) {
      debugPrint('Failed to save Quick Log preferences: $e');
      if (mounted) _showSaveFailure();
    }
  }

  Future<QuickLogTracker?> _chooseTracker(
    BuildContext parentContext,
    List<String> pinned,
    List<QuickLogTracker> custom,
  ) async {
    return showDialog<QuickLogTracker>(
      context: parentContext,
      builder: (dialogContext) {
        final available = QuickLogCatalog.builtIns
            .where((tracker) => !pinned.contains(tracker.keyName))
            .toList();
        return AlertDialog(
          title: const Text('Add Quick Log button'),
          content: SizedBox(
            width: 520,
            height: 430,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final customTracker = await _createCustomTracker(
                      dialogContext,
                    );
                    if (customTracker != null && dialogContext.mounted)
                      Navigator.pop(dialogContext, customTracker);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create custom tracker'),
                ),
                const SizedBox(height: 10),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final tracker = available[index];
                      return ListTile(
                        leading: Icon(_trackerIcon(tracker.iconName)),
                        title: Text(tracker.title),
                        subtitle: Text(tracker.category),
                        onTap: () => Navigator.pop(dialogContext, tracker),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<QuickLogTracker?> _createCustomTracker(
    BuildContext parentContext,
  ) async {
    var type = CareerRecordType.skill;
    var tracksOutcome = false;
    final title = TextEditingController();
    final category = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<QuickLogTracker>(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Create custom tracker'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Button name',
                    hintText: 'Pediatric IV, aerial setup, rope rescue…',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Add a name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: category,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CareerRecordType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: CareerRecordType.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => type = value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: tracksOutcome,
                  onChanged: (value) =>
                      setDialogState(() => tracksOutcome = value),
                  title: const Text('Track success / failure'),
                  subtitle: const Text(
                    'Best for procedures and skills with a measurable attempt outcome.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final cleanTitle = title.text.trim();
                Navigator.pop(
                  dialogContext,
                  QuickLogTracker(
                    keyName:
                        '${_trackingKeyFor(cleanTitle)}.${DateTime.now().millisecondsSinceEpoch}',
                    title: cleanTitle,
                    category: category.text.trim().isEmpty
                        ? type.label
                        : category.text.trim(),
                    type: type,
                    iconName: type == CareerRecordType.operationalExperience
                        ? 'fire'
                        : 'add_task',
                    tracksOutcome: tracksOutcome,
                    custom: true,
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    category.dispose();
    return result;
  }

  List<int> get _years {
    final years = <int>{
      DateTime.now().year,
      ..._records.map((record) => record.date.year),
    }.toList()..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<CareerRecord> get _yearRecords => _records
      .where(
        (record) => _selectedYear == null || record.date.year == _selectedYear,
      )
      .toList();

  List<CareerRecord> get _visibleRecords {
    final q = _searchController.text.trim().toLowerCase();
    return _yearRecords.where((record) {
      if (q.isEmpty) return true;
      final text = [
        record.title,
        record.category,
        record.type.label,
        record.outcome?.label ?? '',
        record.summary ?? '',
        record.date.year.toString(),
        ...record.tags,
      ].join(' ').toLowerCase();
      return text.contains(q);
    }).toList();
  }

  List<_LogAggregate> get _aggregates {
    final q = _searchController.text.trim().toLowerCase();
    final map = <String, _LogAggregate>{};
    for (final record in _yearRecords) {
      final key = record.trackingKey ?? _trackingKeyFor(record.title);
      final item = map.putIfAbsent(
        key,
        () => _LogAggregate(
          keyName: key,
          title: record.title,
          category: record.category,
          type: record.type,
        ),
      );
      item.total += record.repetitions;
      if (record.outcome == CareerRecordOutcome.successful)
        item.successful += record.repetitions;
      if (record.outcome == CareerRecordOutcome.unsuccessful)
        item.unsuccessful += record.repetitions;
      if (item.lastDate == null || record.date.isAfter(item.lastDate!))
        item.lastDate = record.date;
    }
    final values = map.values.where((item) {
      if (q.isEmpty) return true;
      return '${item.title} ${item.category} ${item.type.label}'
          .toLowerCase()
          .contains(q);
    }).toList()..sort((a, b) => b.total.compareTo(a.total));
    return values;
  }

  int _countForTracker(QuickLogTracker tracker, int year) {
    return _records
        .where(
          (record) =>
              record.date.year == year &&
              (record.trackingKey == tracker.keyName ||
                  _trackingKeyFor(record.title) == tracker.keyName),
        )
        .fold<int>(0, (sum, record) => sum + record.repetitions);
  }

  String? _successLabelForTracker(QuickLogTracker tracker, int year) {
    if (!tracker.tracksOutcome) return null;
    var success = 0;
    var unsuccessful = 0;
    for (final record in _records.where(
      (record) =>
          record.date.year == year && record.trackingKey == tracker.keyName,
    )) {
      if (record.outcome == CareerRecordOutcome.successful)
        success += record.repetitions;
      if (record.outcome == CareerRecordOutcome.unsuccessful)
        unsuccessful += record.repetitions;
    }
    final measured = success + unsuccessful;
    if (measured == 0) return null;
    return '$success / $measured • ${(success / measured * 100).round()}%';
  }

  Future<void> _showTrend(_LogAggregate item) async {
    final totals = <int, _LogAggregate>{};
    for (final record in _records.where(
      (e) => (e.trackingKey ?? _trackingKeyFor(e.title)) == item.keyName,
    )) {
      final aggregate = totals.putIfAbsent(
        record.date.year,
        () => _LogAggregate(
          keyName: item.keyName,
          title: record.title,
          category: record.category,
          type: record.type,
        ),
      );
      aggregate.total += record.repetitions;
      if (record.outcome == CareerRecordOutcome.successful)
        aggregate.successful += record.repetitions;
      if (record.outcome == CareerRecordOutcome.unsuccessful)
        aggregate.unsuccessful += record.repetitions;
    }
    final years = totals.keys.toList()..sort((a, b) => b.compareTo(a));
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.title,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Career history by year',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...years.take(12).map((year) {
                final row = totals[year]!;
                final measured = row.successful + row.unsuccessful;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '$year',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: measured == 0
                      ? null
                      : Text(
                          '${row.successful} successful • ${row.unsuccessful} unsuccessful • ${(row.successful / measured * 100).round()}%',
                        ),
                  trailing: Text(
                    '${row.total}',
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentYear = DateTime.now().year;
    final trackers = _pinnedTrackers;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final todayRecords =
        _records.where((r) => isSameDay(r.date, today)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final yearRecords = _records
        .where((r) => r.date.year == currentYear)
        .toList();
    int sumType(CareerRecordType t) => yearRecords
        .where((r) => r.type == t)
        .fold<int>(
          0,
          (sum, r) => sum + (r.repetitions < 1 ? 1 : r.repetitions),
        );
    final calls = sumType(CareerRecordType.operationalExperience);
    final skills = sumType(CareerRecordType.skill);
    final trainings = sumType(CareerRecordType.training);
    final achievements = sumType(CareerRecordType.achievement);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toLog(),

        title: const Text('Personal Log'),
        actions: [
          IconButton(
            tooltip: 'Customize Quick Log',
            onPressed: _customizeQuickLog,
            icon: const Icon(Icons.tune),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'custom') _openLogEditor();
              if (value == 'backup') {
                PortfolioBackupSheet.show(context, onRestored: _load);
              }
              if (value == 'evidence') context.push(AppRoutes.careerEvidence);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'custom',
                child: ListTile(
                  leading: Icon(Icons.history_toggle_off_outlined),
                  title: Text('Past / custom entry'),
                ),
              ),
              PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: Icon(Icons.backup_outlined),
                  title: Text('Backup / Restore'),
                ),
              ),
              PopupMenuItem(
                value: 'evidence',
                child: ListTile(
                  leading: Icon(Icons.auto_stories_outlined),
                  title: Text('Detailed Evidence'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Log',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_config.rolePreset?.label ?? 'Custom'} setup • tap once to log routine activity',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _customizeQuickLog,
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Customize'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (trackers.isEmpty)
                    _ActionCard(
                      icon: Icons.add_circle_outline,
                      title: 'Build your Quick Log',
                      subtitle:
                          'Choose the skills and events you want available every shift.',
                      onTap: _customizeQuickLog,
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.5,
                          ),
                      itemCount: trackers.length,
                      itemBuilder: (context, index) {
                        final tracker = trackers[index];
                        return _QuickLogCard(
                          tracker: tracker,
                          count: _countForTracker(tracker, currentYear),
                          successLabel: _successLabelForTracker(
                            tracker,
                            currentYear,
                          ),
                          onTap: () => _quickLog(tracker),
                        );
                      },
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (todayRecords.isEmpty)
                    Text(
                      'Nothing logged today yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    )
                  else
                    ...todayRecords.map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: _RecentRecord(
                          record: record,
                          onEdit: () => _openLogEditor(existing: record),
                          onDelete: () => _deleteRecord(record),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'This Year',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      '$currentYear Career Activity\n$calls Calls • $skills Skills • $trainings Trainings • $achievements Achievements',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _openFullHistory,
                      child: const Text('View Full History'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openLogEditor(),
                      icon: const Icon(Icons.add),
                      label: const Text('Log past / custom activity'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Privacy reminder: do not enter patient names, addresses, DOBs, or other identifying information.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _openFullHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Full History',
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        onPressed: () => sheetContext.pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Trends',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          DropdownButton<int?>(
                            value: _selectedYear,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('All time'),
                              ),
                              ..._years.map(
                                (year) => DropdownMenuItem<int?>(
                                  value: year,
                                  child: Text('$year'),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedYear = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search',
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_aggregates.isEmpty)
                        Text(
                          'Nothing logged for this view yet.',
                          style: Theme.of(sheetContext).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        )
                      else
                        ..._aggregates
                            .take(20)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _AggregateCard(
                                  item: item,
                                  onTap: () => _showTrend(item),
                                ),
                              ),
                            ),
                      const SizedBox(height: 18),
                      Text(
                        'Entries',
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      if (_visibleRecords.isEmpty)
                        Text(
                          'No entries for this filter.',
                          style: Theme.of(sheetContext).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        )
                      else
                        ..._visibleRecords
                            .take(60)
                            .map(
                              (record) => Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: _RecentRecord(
                                  record: record,
                                  onEdit: () =>
                                      _openLogEditor(existing: record),
                                  onDelete: () => _deleteRecord(record),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _trackingKeyFor(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    return normalized.isEmpty ? 'custom.activity' : 'custom.$normalized';
  }

  static IconData _trackerIcon(String name) => switch (name) {
    'vaccines' => Icons.vaccines_outlined,
    'medical' => Icons.medical_services_outlined,
    'air' => Icons.air_outlined,
    'heart' => Icons.monitor_heart_outlined,
    'monitor' => Icons.monitor_heart_outlined,
    'medication' => Icons.medication_outlined,
    'structure' => Icons.home_work_outlined,
    'car' => Icons.directions_car_filled_outlined,
    'fire' => Icons.local_fire_department_outlined,
    'crash' => Icons.car_crash_outlined,
    'water' => Icons.water_drop_outlined,
    'ladder' => Icons.stairs_outlined,
    'tools' => Icons.handyman_outlined,
    'search' => Icons.search,
    'truck' => Icons.fire_truck_outlined,
    'hydrant' => Icons.water_outlined,
    'route' => Icons.route_outlined,
    'checklist' => Icons.fact_check_outlined,
    'groups' => Icons.groups_outlined,
    'command' => Icons.record_voice_over_outlined,
    'school' => Icons.school_outlined,
    'person' => Icons.person_outline,
    'project' => Icons.work_outline,
    'community' => Icons.diversity_3_outlined,
    _ => Icons.add_task_outlined,
  };

  static String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';
}

class _QuickLogCard extends StatelessWidget {
  final QuickLogTracker tracker;
  final int count;
  final String? successLabel;
  final VoidCallback onTap;

  const _QuickLogCard({
    required this.tracker,
    required this.count,
    required this.successLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    _PersonalLogPageState._trackerIcon(tracker.iconName),
                    color: cs.primary,
                    size: 25,
                  ),
                  const Spacer(),
                  const Icon(Icons.add_circle_outline, size: 22),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tracker.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                '$count this year',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (successLabel != null)
                Text(
                  successLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogAggregate {
  final String keyName;
  final String title;
  final String category;
  final CareerRecordType type;
  int total = 0;
  int successful = 0;
  int unsuccessful = 0;
  DateTime? lastDate;

  _LogAggregate({
    required this.keyName,
    required this.title,
    required this.category,
    required this.type,
  });
}

class _AggregateCard extends StatelessWidget {
  final _LogAggregate item;
  final VoidCallback onTap;
  const _AggregateCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final measured = item.successful + item.unsuccessful;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.category}${item.lastDate == null ? '' : ' • last ${_PersonalLogPageState._formatDate(item.lastDate!)}'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (measured > 0)
                      Text(
                        '${item.successful} successful • ${item.unsuccessful} unsuccessful • ${(item.successful / measured * 100).round()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${item.total}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 7),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _RecentRecord extends StatelessWidget {
  final CareerRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _RecentRecord({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_PersonalLogPageState._formatDate(record.date)} • ${record.category}${record.outcome == null ? '' : ' • ${record.outcome!.label}'}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                if ((record.summary ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      record.summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          if (record.repetitions > 1)
            Text(
              '×${record.repetitions}',
              style: const TextStyle(fontWeight: FontWeight.w900),
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
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class _EmptyLogCard extends StatelessWidget {
  const _EmptyLogCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Nothing logged for this view yet. Use Quick Log above, or add a past/custom activity.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
