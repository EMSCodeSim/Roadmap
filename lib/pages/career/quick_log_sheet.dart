import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/apparatus_profile.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/quick_log_template.dart';
import 'package:firepath/models/quick_log_tracker.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/apparatus_profile_store.dart';
import 'package:firepath/services/career_stats.dart';
import 'package:firepath/services/quick_log_preferences_store.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

enum QuickLogMode {
  taskBookProgress,
  callIncident,
  skill,
  training,
  driveTime,
  leadership,
  teaching,
  awardRecognition,
  achievement,
  project,
  education,
  custom,
}

extension QuickLogModeX on QuickLogMode {
  String get label => switch (this) {
        QuickLogMode.taskBookProgress => 'TASK BOOK PROGRESS',
        QuickLogMode.callIncident => 'CALL / INCIDENT',
        QuickLogMode.skill => 'SKILL',
        QuickLogMode.training => 'TRAINING',
        QuickLogMode.driveTime => 'DRIVE TIME',
        QuickLogMode.leadership => 'LEADERSHIP',
        QuickLogMode.teaching => 'TEACHING / INSTRUCTOR',
        QuickLogMode.awardRecognition => 'AWARD / RECOGNITION',
        QuickLogMode.achievement => 'ACHIEVEMENT',
        QuickLogMode.project => 'PROJECT',
        QuickLogMode.education => 'EDUCATION',
        QuickLogMode.custom => 'CUSTOM',
      };

  IconData get icon => switch (this) {
        QuickLogMode.taskBookProgress => Icons.fact_check_outlined,
        QuickLogMode.callIncident => Icons.local_fire_department_outlined,
        QuickLogMode.skill => Icons.handyman_outlined,
        QuickLogMode.training => Icons.school_outlined,
        QuickLogMode.driveTime => Icons.local_shipping_outlined,
        QuickLogMode.leadership => Icons.groups_outlined,
        QuickLogMode.teaching => Icons.record_voice_over_outlined,
        QuickLogMode.awardRecognition => Icons.military_tech_outlined,
        QuickLogMode.achievement => Icons.emoji_events_outlined,
        QuickLogMode.project => Icons.assignment_outlined,
        QuickLogMode.education => Icons.menu_book_outlined,
        QuickLogMode.custom => Icons.tune_outlined,
      };
}

class QuickLogSheet extends StatefulWidget {
  final LogPrefill? prefill;

  const QuickLogSheet({super.key, required this.prefill});

  @override
  State<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<QuickLogSheet> {
  final CareerRecordStore _recordStore = CareerRecordStore();
  final QuickLogPreferencesStore _preferencesStore = QuickLogPreferencesStore();

  List<CareerRecord> _records = const [];
  QuickLogConfig _config = QuickLogConfig(
    rolePreset: QuickLogRolePreset.firefighter,
    pinnedKeys: QuickLogCatalog.defaultsFor(QuickLogRolePreset.firefighter),
    customTrackers: const <QuickLogTracker>[],
  );
  bool _loading = true;
  QuickLogMode? _mode;
  CareerRecord? _seed;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final preferences = await _preferencesStore.load();
      final records = await _recordStore.load();
      records.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _config = _configFromPreferences(preferences);
        _records = records;
        _loading = false;
        if (widget.prefill?.relatedRequirementId != null ||
            widget.prefill?.relatedTaskId != null) {
          _mode = QuickLogMode.taskBookProgress;
        }
      });
    } catch (e) {
      debugPrint('QuickLog init failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  static QuickLogConfig _configFromPreferences(
      QuickLogPreferences preferences) {
    final custom = preferences.customTemplates
        .map((template) => QuickLogTracker(
              keyName: template.id,
              title: template.title,
              category: template.category,
              type: template.type,
              iconName: template.iconKey,
              tracksOutcome: template.tracksOutcome,
              custom: template.isCustom,
            ))
        .toList();
    return QuickLogConfig(
      rolePreset: _guessRolePreset(preferences.pinnedIds),
      pinnedKeys: preferences.pinnedIds,
      customTrackers: custom,
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

  List<CareerRecord> get _recentRecords => _records.take(5).toList();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: _mode == null
            ? _Chooser(
                loading: _loading,
                pinned: _pinnedTrackers,
                recent: _recentRecords,
                onPickMode: (mode) => setState(() {
                  _seed = null;
                  _mode = mode;
                }),
                onPickPinned: _openPinnedTracker,
                onPickRecent: _repeatRecord,
              )
            : _QuickLogForm(
                mode: _mode!,
                prefill: widget.prefill,
                seed: _seed,
                onBack: () => setState(() {
                  _seed = null;
                  _mode = null;
                }),
                onSaveRecord: _recordStore.upsert,
              ),
      ),
    );
  }

  void _openPinnedTracker(QuickLogTracker tracker) {
    final now = DateTime.now();
    setState(() {
      _mode = _modeForTracker(tracker);
      _seed = CareerRecord(
        id: '',
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
        relatedTaskId: null,
        highlight: false,
        trackingKey: tracker.keyName,
        outcome: null,
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  void _repeatRecord(CareerRecord record) {
    setState(() {
      _mode = _modeForRecord(record);
      _seed = record;
    });
  }

  static QuickLogMode _modeForTracker(QuickLogTracker tracker) {
    if (tracker.keyName == 'fire.driver') return QuickLogMode.driveTime;
    return switch (tracker.type) {
      CareerRecordType.operationalExperience => QuickLogMode.callIncident,
      CareerRecordType.skill => QuickLogMode.skill,
      CareerRecordType.training => QuickLogMode.training,
      CareerRecordType.achievement => QuickLogMode.achievement,
      CareerRecordType.leadership => QuickLogMode.leadership,
      CareerRecordType.teaching => QuickLogMode.teaching,
      CareerRecordType.project => QuickLogMode.project,
      CareerRecordType.education => QuickLogMode.education,
      CareerRecordType.taskBookEvidence => QuickLogMode.taskBookProgress,
    };
  }

  static QuickLogMode _modeForRecord(CareerRecord record) {
    if (CareerStats.isDrivingRecord(record)) return QuickLogMode.driveTime;
    if (CareerStats.isAwardRecord(record)) return QuickLogMode.awardRecognition;
    return switch (record.type) {
      CareerRecordType.operationalExperience => QuickLogMode.callIncident,
      CareerRecordType.skill => QuickLogMode.skill,
      CareerRecordType.training => QuickLogMode.training,
      CareerRecordType.achievement => QuickLogMode.achievement,
      CareerRecordType.leadership => QuickLogMode.leadership,
      CareerRecordType.teaching => QuickLogMode.teaching,
      CareerRecordType.project => QuickLogMode.project,
      CareerRecordType.education => QuickLogMode.education,
      CareerRecordType.taskBookEvidence => QuickLogMode.taskBookProgress,
    };
  }
}

class _Chooser extends StatelessWidget {
  final bool loading;
  final List<QuickLogTracker> pinned;
  final List<CareerRecord> recent;
  final ValueChanged<QuickLogMode> onPickMode;
  final ValueChanged<QuickLogTracker> onPickPinned;
  final ValueChanged<CareerRecord> onPickRecent;

  const _Chooser({
    required this.loading,
    required this.pinned,
    required this.recent,
    required this.onPickMode,
    required this.onPickPinned,
    required this.onPickRecent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('quick_log_chooser'),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        Text('Quick Log',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Record the work now. Organize it for your career later.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant)),
        if (loading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
        if (pinned.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SectionLabel('QUICK ACTIONS'),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 380;
              final cols = isNarrow ? 2 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                itemCount: pinned.length,
                itemBuilder: (context, index) {
                  final tracker = pinned[index];
                  return SizedBox(
                    height: 56,
                    child: FilledButton.tonalIcon(
                      onPressed: () => onPickPinned(tracker),
                      icon: Icon(_trackerIcon(tracker.iconName), size: 18),
                      label: Text(
                        tracker.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel('RECENT — TAP TO REPEAT'),
          const SizedBox(height: 8),
          ...recent.map((record) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(record.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_recentSubtitle(record)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onPickRecent(record),
              )),
        ],
        const SizedBox(height: 20),
        _SectionLabel('WHAT ARE YOU LOGGING?'),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.65,
          ),
          itemCount: QuickLogMode.values.length,
          itemBuilder: (context, index) {
            final mode = QuickLogMode.values[index];
            return InkWell(
              onTap: () => onPickMode(mode),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(mode.icon, color: cs.primary, size: 25),
                    const SizedBox(height: 8),
                    Text(
                      mode.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static String _recentSubtitle(CareerRecord record) {
    final amount = record.hours != null
        ? CareerStats.formatDurationHours(record.hours!)
        : record.repetitions > 1
            ? '${record.repetitions} reps'
            : record.type.shortLabel;
    return record.category.trim().isEmpty
        ? amount
        : '${record.category} • $amount';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
}

class _DriveApparatusPicker extends StatelessWidget {
  final List<ApparatusProfile> saved;
  final ValueChanged<ApparatusProfile> onSelected;
  final VoidCallback onCustom;

  const _DriveApparatusPicker({required this.saved, required this.onSelected, required this.onCustom});

  @override
  Widget build(BuildContext context) {
    final defaults = ApparatusKind.values
        .where((kind) => kind != ApparatusKind.custom)
        .map((kind) => ApparatusProfile(id: 'default.${kind.name}', name: kind.label, kind: kind));
    final choices = [...saved, ...defaults];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _SectionLabel('SELECT APPARATUS'),
      const SizedBox(height: 8),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: choices.length,
        itemBuilder: (context, index) {
          final profile = choices[index];
          return FilledButton.tonalIcon(
            onPressed: () => onSelected(profile),
            icon: Icon(_apparatusIcon(profile.kind), size: 19),
            label: Text(profile.name, overflow: TextOverflow.ellipsis),
          );
        },
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: onCustom, icon: const Icon(Icons.add), label: const Text('Add custom apparatus')),
    ]);
  }
}

class _SelectedApparatusCard extends StatelessWidget {
  final ApparatusProfile profile;
  final VoidCallback onChange;
  const _SelectedApparatusCard({required this.profile, required this.onChange});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: .18))),
        leading: Icon(_apparatusIcon(profile.kind)),
        title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(profile.kind.label),
        trailing: TextButton(onPressed: onChange, child: const Text('Change')),
      );
}

class _ToggleWrap extends StatelessWidget {
  final List<Widget> children;
  const _ToggleWrap({required this.children});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: children);
}

class _DriveToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  const _DriveToggle(this.label, this.selected, this.onChanged);
  @override
  Widget build(BuildContext context) => FilterChip(
        selected: selected,
        onSelected: onChanged,
        avatar: Icon(selected ? Icons.check : Icons.add, size: 17),
        label: Text(label),
      );
}

IconData _apparatusIcon(ApparatusKind kind) => switch (kind) {
      ApparatusKind.medic => Icons.medical_services_outlined,
      ApparatusKind.engine => Icons.local_fire_department_outlined,
      ApparatusKind.brush => Icons.terrain_outlined,
      ApparatusKind.tender => Icons.water_drop_outlined,
      ApparatusKind.truck => Icons.fire_truck_outlined,
      ApparatusKind.rescue => Icons.health_and_safety_outlined,
      ApparatusKind.command => Icons.campaign_outlined,
      ApparatusKind.custom => Icons.local_shipping_outlined,
    };

class _QuickLogForm extends StatefulWidget {
  final QuickLogMode mode;
  final LogPrefill? prefill;
  final CareerRecord? seed;
  final VoidCallback onBack;
  final Future<bool> Function(CareerRecord) onSaveRecord;

  const _QuickLogForm({
    required this.mode,
    required this.prefill,
    required this.seed,
    required this.onBack,
    required this.onSaveRecord,
  });

  @override
  State<_QuickLogForm> createState() => _QuickLogFormState();
}

class _QuickLogFormState extends State<_QuickLogForm> {
  final _apparatusStore = ApparatusProfileStore();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _note = TextEditingController();
  final _role = TextEditingController();
  final _hours = TextEditingController();
  final _reps = TextEditingController(text: '1');
  final _startMiles = TextEditingController();
  final _endMiles = TextEditingController();
  final _gallons = TextEditingController();
  final _cycles = TextEditingController();

  List<ApparatusProfile> _savedApparatus = const [];
  ApparatusProfile? _apparatus;
  bool _emergent = false;
  bool _patientTransport = false;
  bool _returnEmergent = false;
  bool _backing = false;
  bool _spotter = false;
  bool _evaluated = false;
  bool _pumpOperations = false;
  bool _offRoad = false;
  bool _pumpAndRoll = false;
  bool _aerialSetup = false;

  CareerRecordOutcome? _outcome;
  DateTime _date = DateTime.now();
  LogPrefill? _taskLink;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.seed;
    if (seed != null) {
      _title.text = seed.title;
      _category.text = seed.category;
      _note.text = seed.summary ?? '';
      _role.text = seed.roleOrAssignment ?? '';
      if (seed.hours != null) _hours.text = seed.hours!.toString();
      if (seed.repetitions > 0) _reps.text = seed.repetitions.toString();
      _outcome = seed.outcome;
    }
    _taskLink = widget.prefill;
    if (widget.mode == QuickLogMode.driveTime) {
      _restoreDriveDetails(seed?.details ?? const <String, dynamic>{});
      _loadApparatus();
    }
    if ((widget.prefill?.title ?? '').trim().isNotEmpty) {
      _title.text = widget.prefill!.title;
    }
    if ((widget.prefill?.category ?? '').trim().isNotEmpty) {
      _category.text = widget.prefill!.category!;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _note.dispose();
    _role.dispose();
    _hours.dispose();
    _reps.dispose();
    _startMiles.dispose();
    _endMiles.dispose();
    _gallons.dispose();
    _cycles.dispose();
    super.dispose();
  }

  CareerRecordType get _recordType => switch (widget.mode) {
        QuickLogMode.taskBookProgress => CareerRecordType.taskBookEvidence,
        QuickLogMode.callIncident => CareerRecordType.operationalExperience,
        QuickLogMode.skill => CareerRecordType.skill,
        QuickLogMode.training => CareerRecordType.training,
        QuickLogMode.driveTime => CareerRecordType.skill,
        QuickLogMode.leadership => CareerRecordType.leadership,
        QuickLogMode.teaching => CareerRecordType.teaching,
        QuickLogMode.awardRecognition => CareerRecordType.achievement,
        QuickLogMode.achievement => CareerRecordType.achievement,
        QuickLogMode.project => CareerRecordType.project,
        QuickLogMode.education => CareerRecordType.education,
        QuickLogMode.custom => CareerRecordType.skill,
      };

  Requirement? _linkedRequirement(AppState state) {
    final id = _taskLink?.relatedRequirementId;
    final goalId = _taskLink?.relatedGoalId;
    final roadmap = state.roadmap;
    if (id == null || goalId == null || roadmap?.goal.id != goalId) return null;
    return roadmap!.all
        .where((item) => item.requirement.id == id)
        .map((item) => item.requirement)
        .firstOrNull;
  }

  bool _usesHours(AppState state) {
    if (widget.mode == QuickLogMode.training ||
        widget.mode == QuickLogMode.driveTime ||
        widget.mode == QuickLogMode.teaching ||
        widget.mode == QuickLogMode.education) {
      return true;
    }
    final requirement = _linkedRequirement(state);
    final unit = (requirement?.progressUnit ?? '').toLowerCase();
    return requirement?.type == RequirementType.numericProgress &&
        (unit.contains('hour') || unit.contains('time'));
  }

  bool _usesReps(AppState state) {
    if (_usesHours(state)) return false;
    return widget.mode == QuickLogMode.skill ||
        widget.mode == QuickLogMode.taskBookProgress;
  }

  bool get _tracksOutcome => widget.mode == QuickLogMode.skill;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final usesHours = _usesHours(state);
    final usesReps = _usesReps(state);

    return ListView(
      key: ValueKey('quick_log_form_${widget.mode.name}'),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _saving ? null : widget.onBack,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Back',
            ),
            Expanded(
              child: Text(widget.mode.label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        if (widget.mode == QuickLogMode.driveTime && _apparatus == null) ...[
          _DriveApparatusPicker(
            saved: _savedApparatus,
            onSelected: _selectApparatus,
            onCustom: _createCustomApparatus,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the rig first. The log will show only fields that apply.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
        ] else ...[
        if (widget.mode == QuickLogMode.taskBookProgress || _taskLink != null) ...[
          const SizedBox(height: 8),
          _TaskBookLinkCard(
            prefill: _taskLink,
            onChoose: _chooseTaskBookTarget,
            onClear: _taskLink == null
                ? null
                : () => setState(() => _taskLink = null),
          ),
        ] else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _chooseTaskBookTarget,
              icon: const Icon(Icons.link),
              label: const Text('Link to Task Book'),
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (widget.mode == QuickLogMode.driveTime) ...[
          _SelectedApparatusCard(
            profile: _apparatus!,
            onChange: () => setState(() => _apparatus = null),
          ),
          const SizedBox(height: 12),
          _buildDriveFields(),
        ] else ...[
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: _titleLabel(widget.mode),
            hintText: _titleHint(widget.mode),
          ),
        ),
        const SizedBox(height: 12),
        if (_categoryEnabled(widget.mode)) ...[
          TextField(
            controller: _category,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: _categoryLabel(widget.mode),
              hintText: widget.mode == QuickLogMode.driveTime
                  ? 'Engine, truck, tender…'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (usesReps) ...[
          TextField(
            controller: _reps,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Repetitions',
              hintText: '1',
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (usesHours) ...[
          TextField(
            controller: _hours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Duration (hours)',
              hintText: '1.5',
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_tracksOutcome) ...[
          DropdownButtonFormField<CareerRecordOutcome?>(
            value: _outcome,
            decoration: const InputDecoration(labelText: 'Outcome (optional)'),
            items: [
              const DropdownMenuItem(value: null, child: Text('No outcome')),
              ...CareerRecordOutcome.values
                  .where((o) => o != CareerRecordOutcome.completed)
                  .map((o) =>
                      DropdownMenuItem(value: o, child: Text(o.label))),
            ],
            onChanged: (value) => setState(() => _outcome = value),
          ),
          const SizedBox(height: 12),
        ],
        if (_roleEnabled(widget.mode)) ...[
          TextField(
            controller: _role,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(labelText: 'Role / assignment (optional)'),
          ),
          const SizedBox(height: 12),
        ],
        ],
        InkWell(
          onTap: _saving ? null : _pickDate,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Date'),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 8),
                Text(CareerStats.formatDate(_date)),
                const Spacer(),
                const Text('Change'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        const SizedBox(height: 8),
        Text(
          'Keep entries professional and non-identifying. Do not enter patient names, addresses, DOBs, MRNs, or other protected information.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _saving ? null : () => _save(state),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_saving
                ? 'Saving…'
                : widget.mode == QuickLogMode.driveTime
                    ? 'Save Drive Log'
                    : 'Save'),
          ),
        ),
        ],
      ],
    );
  }

  Future<void> _loadApparatus() async {
    final saved = await _apparatusStore.load();
    if (mounted) setState(() => _savedApparatus = saved);
  }

  void _restoreDriveDetails(Map<String, dynamic> details) {
    final kindName = details['apparatusKind'] as String?;
    final name = details['apparatusName'] as String?;
    if (kindName != null && name != null) {
      ApparatusKind kind = ApparatusKind.custom;
      try { kind = ApparatusKind.values.byName(kindName); } catch (_) {}
      _apparatus = ApparatusProfile(id: 'repeat', name: name, kind: kind);
    }
    _startMiles.text = '${details['startMiles'] ?? ''}';
    _endMiles.text = '${details['endMiles'] ?? ''}';
    _gallons.text = '${details['gallonsMoved'] ?? ''}';
    _cycles.text = '${details['shuttleCycles'] ?? ''}';
    _emergent = details['emergent'] == true;
    _patientTransport = details['patientTransport'] == true;
    _returnEmergent = details['returnEmergent'] == true;
    _backing = details['backing'] == true;
    _spotter = details['spotter'] == true;
    _evaluated = details['evaluated'] == true;
    _pumpOperations = details['pumpOperations'] == true;
    _offRoad = details['offRoad'] == true;
    _pumpAndRoll = details['pumpAndRoll'] == true;
    _aerialSetup = details['aerialSetup'] == true;
  }

  void _selectApparatus(ApparatusProfile profile) {
    setState(() {
      _apparatus = profile;
      _title.text = '${profile.name} driving';
      _category.text = profile.kind.label;
    });
  }

  Future<void> _createCustomApparatus() async {
    final name = TextEditingController();
    ApparatusKind kind = ApparatusKind.custom;
    final profile = await showDialog<ApparatusProfile>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add apparatus'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Unit name', hintText: 'Medic 184')),
            const SizedBox(height: 12),
            DropdownButtonFormField<ApparatusKind>(
              value: kind,
              decoration: const InputDecoration(labelText: 'Apparatus type'),
              items: ApparatusKind.values.map((item) =>
                DropdownMenuItem(value: item, child: Text(item.label))).toList(),
              onChanged: (value) => setDialogState(() => kind = value ?? kind),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              if (name.text.trim().isEmpty) return;
              final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
              Navigator.pop(dialogContext, ApparatusProfile(id: now, name: name.text.trim(), kind: kind));
            }, child: const Text('Save apparatus')),
          ],
        ),
      ),
    );
    name.dispose();
    if (profile == null || !mounted) return;
    final updated = [..._savedApparatus, profile];
    await _apparatusStore.save(updated);
    if (!mounted) return;
    setState(() => _savedApparatus = updated);
    _selectApparatus(profile);
  }

  Widget _buildDriveFields() {
    final kind = _apparatus!.kind;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: TextField(controller: _startMiles,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Starting miles'))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: _endMiles,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Ending miles'))),
      ]),
      const SizedBox(height: 12),
      TextField(controller: _hours,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Drive time (hours)', hintText: '0.75')),
      const SizedBox(height: 12),
      _SectionLabel('ACTIVITY'),
      const SizedBox(height: 6),
      _ToggleWrap(children: [
        _DriveToggle('Emergent response', _emergent, (v) => setState(() => _emergent = v)),
        _DriveToggle('Backing performed', _backing, (v) => setState(() => _backing = v)),
        _DriveToggle('Spotter used', _spotter, (v) => setState(() => _spotter = v)),
        _DriveToggle('Evaluated drive', _evaluated, (v) => setState(() => _evaluated = v)),
        if (kind == ApparatusKind.medic) ...[
          _DriveToggle('Patient transported', _patientTransport, (v) => setState(() => _patientTransport = v)),
          _DriveToggle('Return emergent', _returnEmergent, (v) => setState(() => _returnEmergent = v)),
        ],
        if (kind == ApparatusKind.engine)
          _DriveToggle('Pump operations', _pumpOperations, (v) => setState(() => _pumpOperations = v)),
        if (kind == ApparatusKind.brush) ...[
          _DriveToggle('Off-road driving', _offRoad, (v) => setState(() => _offRoad = v)),
          _DriveToggle('Pump-and-roll', _pumpAndRoll, (v) => setState(() => _pumpAndRoll = v)),
        ],
        if (kind == ApparatusKind.truck)
          _DriveToggle('Aerial setup', _aerialSetup, (v) => setState(() => _aerialSetup = v)),
      ]),
      if (kind == ApparatusKind.tender) ...[
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _gallons, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Gallons moved'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _cycles, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Shuttle cycles'))),
        ]),
      ],
    ]);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ));
  }

  Future<void> _chooseTaskBookTarget() async {
    final state = context.read<AppState>();
    final roadmap = state.roadmap;
    if (roadmap == null) {
      _message('Choose a career goal before linking Task Book progress.');
      return;
    }

    final choices = <_TaskChoice>[];
    final ordered = <RoadmapRequirement>[
      if (roadmap.nextStep != null) roadmap.nextStep!,
      ...roadmap.missing.where(
          (item) => item.requirement.id != roadmap.nextStep?.requirement.id),
    ];

    for (final item in ordered) {
      final requirement = item.requirement;
      final tasks = [
        ...TaskBookLibrary.tasksForRequirement(requirement),
        ...state.customTasksFor(
          goalId: roadmap.goal.id,
          requirementId: requirement.id,
        ),
      ];
      if (tasks.isEmpty) {
        choices.add(_TaskChoice(
          title: requirement.name,
          subtitle: 'Requirement',
          prefill: LogPrefill(
            title: requirement.name,
            category: requirement.name,
            relatedGoalId: roadmap.goal.id,
            relatedRequirementId: requirement.id,
            relatedTaskId: null,
            tags: const ['task-book', 'progress'],
          ),
        ));
        continue;
      }
      for (final task in tasks) {
        final status = state.taskStatusFor(
          goalId: roadmap.goal.id,
          requirementId: requirement.id,
          taskId: task.id,
        );
        if (status == TaskBookTaskStatus.complete) continue;
        choices.add(_TaskChoice(
          title: task.title,
          subtitle: requirement.name,
          prefill: LogPrefill(
            title: task.title,
            category: requirement.name,
            relatedGoalId: roadmap.goal.id,
            relatedRequirementId: requirement.id,
            relatedTaskId: task.id,
            tags: const ['task-book', 'practice'],
          ),
        ));
      }
    }

    if (!mounted) return;
    final selected = await showModalBottomSheet<LogPrefill>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _TaskPickerSheet(
        goalTitle: roadmap.goal.title,
        choices: choices,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _taskLink = selected;
      _title.text = selected.title;
      _category.text = selected.category ?? '';
    });
  }

  Future<void> _save(AppState state) async {
    final record = _buildRecord(state);
    if (record == null) return;
    setState(() => _saving = true);

    try {
      final saved = await widget.onSaveRecord(record);
      if (!saved) {
        _message('This entry could not be saved. Your existing record was not changed.');
        return;
      }

      var taskBookUpdated = false;
      try {
        taskBookUpdated = await _applyTaskBookProgress(state, record);
      } catch (e) {
        debugPrint('QuickLog Task Book update failed: $e');
      }

      if (!mounted) return;
      final suffix = taskBookUpdated ? ' • Task Book updated' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${record.title}$suffix'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      debugPrint('QuickLog save failed: $e');
      if (mounted) _message('Could not save this entry. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  CareerRecord? _buildRecord(AppState state) {
    if (widget.mode == QuickLogMode.driveTime && _apparatus == null) {
      _message('Choose an apparatus before saving.');
      return null;
    }
    final title = _title.text.trim();
    if (title.isEmpty) {
      _message('Add a title before saving.');
      return null;
    }

    final usesHours = _usesHours(state);
    final usesReps = _usesReps(state);
    final hours = double.tryParse(_hours.text.trim());
    final reps = int.tryParse(_reps.text.trim()) ?? 1;
    if (usesHours && (hours == null || hours <= 0)) {
      _message('Enter a duration greater than 0 hours.');
      return null;
    }
    if (usesReps && reps <= 0) {
      _message('Enter at least 1 repetition.');
      return null;
    }

    final now = DateTime.now();
    final tags = <String>{
      'quick-log',
      ...?widget.seed?.tags,
      ...?_taskLink?.tags,
    };
    final linkedRequirement = _linkedRequirement(state);
    if (_taskLink != null) tags.add('task-book-linked');
    if (linkedRequirement?.type == RequirementType.numericProgress) {
      tags.add('task-book-progress-applied');
    }

    final driveDetails = widget.mode == QuickLogMode.driveTime
        ? _driveDetails()
        : (widget.seed?.details ?? const <String, dynamic>{});
    if (widget.mode == QuickLogMode.driveTime) {
      tags.add('apparatus:${_apparatus!.kind.name}');
      if (_emergent) tags.add('emergent');
      if (_patientTransport) tags.add('patient-transport');
    }

    return CareerRecord(
      id: now.microsecondsSinceEpoch.toRadixString(36),
      type: _recordType,
      title: title,
      category: _category.text.trim().isEmpty
          ? _defaultCategory(widget.mode)
          : _category.text.trim(),
      date: _date,
      roleOrAssignment:
          _role.text.trim().isEmpty ? null : _role.text.trim(),
      summary: _note.text.trim().isEmpty ? null : _note.text.trim(),
      impact: null,
      evidenceReference: null,
      hours: usesHours ? hours : null,
      repetitions: usesReps ? reps : 1,
      tags: tags.toList(),
      relatedGoalId: _taskLink?.relatedGoalId,
      relatedRequirementId: _taskLink?.relatedRequirementId,
      relatedTaskId: _taskLink?.relatedTaskId,
      highlight: false,
      trackingKey: widget.seed?.trackingKey ?? _trackingKey(widget.mode),
      outcome: _outcome,
      details: driveDetails,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> _driveDetails() {
    final start = double.tryParse(_startMiles.text.trim());
    final end = double.tryParse(_endMiles.text.trim());
    final details = <String, dynamic>{
      'apparatusId': _apparatus!.id,
      'apparatusName': _apparatus!.name,
      'apparatusKind': _apparatus!.kind.name,
      if (start != null) 'startMiles': start,
      if (end != null) 'endMiles': end,
      if (start != null && end != null && end >= start) 'totalMiles': end - start,
      'emergent': _emergent,
      'patientTransport': _patientTransport,
      'returnEmergent': _returnEmergent,
      'backing': _backing,
      'spotter': _spotter,
      'evaluated': _evaluated,
      'pumpOperations': _pumpOperations,
      'offRoad': _offRoad,
      'pumpAndRoll': _pumpAndRoll,
      'aerialSetup': _aerialSetup,
    };
    final gallons = double.tryParse(_gallons.text.trim());
    final cycles = int.tryParse(_cycles.text.trim());
    if (gallons != null) details['gallonsMoved'] = gallons;
    if (cycles != null) details['shuttleCycles'] = cycles;
    return details;
  }

  Future<bool> _applyTaskBookProgress(
      AppState state, CareerRecord record) async {
    final goalId = record.relatedGoalId;
    final requirementId = record.relatedRequirementId;
    if (goalId == null || requirementId == null) return false;
    final roadmap = state.roadmap;
    if (roadmap == null || roadmap.goal.id != goalId) return false;

    var changed = false;
    final taskId = record.relatedTaskId;
    if (taskId != null) {
      final status = state.taskStatusFor(
        goalId: goalId,
        requirementId: requirementId,
        taskId: taskId,
      );
      if (status == TaskBookTaskStatus.notStarted) {
        await state.setTaskStatus(
          goalId: goalId,
          requirementId: requirementId,
          taskId: taskId,
          status: TaskBookTaskStatus.practicing,
        );
        changed = true;
      }
    }

    final requirement = roadmap.all
        .where((item) => item.requirement.id == requirementId)
        .map((item) => item.requirement)
        .firstOrNull;
    if (requirement?.type == RequirementType.numericProgress &&
        requirement!.progressRequired != null &&
        requirement.progressRequired! > 0) {
      final delta = record.hours ?? record.repetitions.toDouble();
      if (delta > 0) {
        await state.setNumericProgress(
          goalId: goalId,
          requirementId: requirementId,
          current: (requirement.progressCurrent ?? 0) + delta,
          required: requirement.progressRequired!,
          unit: requirement.progressUnit,
        );
        changed = true;
      }
    }

    return changed;
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static bool _categoryEnabled(QuickLogMode mode) => switch (mode) {
        QuickLogMode.skill => false,
        QuickLogMode.training => false,
        _ => true,
      };

  static bool _roleEnabled(QuickLogMode mode) => switch (mode) {
        QuickLogMode.callIncident ||
        QuickLogMode.leadership ||
        QuickLogMode.teaching ||
        QuickLogMode.project => true,
        _ => false,
      };

  static String _titleLabel(QuickLogMode mode) => switch (mode) {
        QuickLogMode.callIncident => 'Incident type',
        QuickLogMode.skill => 'Skill',
        QuickLogMode.training => 'Training / drill',
        QuickLogMode.driveTime => 'Driving activity',
        QuickLogMode.leadership => 'Leadership activity',
        QuickLogMode.teaching => 'Class / topic',
        QuickLogMode.awardRecognition => 'Award / recognition',
        QuickLogMode.achievement => 'Achievement',
        QuickLogMode.project => 'Project',
        QuickLogMode.education => 'Education',
        QuickLogMode.taskBookProgress => 'Task / activity',
        QuickLogMode.custom => 'Title',
      };

  static String _titleHint(QuickLogMode mode) => switch (mode) {
        QuickLogMode.callIncident => 'Structure fire, EMS call, vehicle accident…',
        QuickLogMode.skill => 'IV attempt, drafting, ground ladder…',
        QuickLogMode.training => 'Pump operations, search drill…',
        QuickLogMode.driveTime => 'Apparatus driving',
        QuickLogMode.leadership => 'Acting officer, crew mentoring…',
        QuickLogMode.teaching => 'Pump class',
        QuickLogMode.awardRecognition => 'Commendation',
        QuickLogMode.achievement => 'Completed task book',
        QuickLogMode.project => 'Committee work',
        QuickLogMode.education => 'CE / college',
        QuickLogMode.taskBookProgress => 'Choose a Task Book item above',
        QuickLogMode.custom => 'What happened?',
      };

  static String _categoryLabel(QuickLogMode mode) => switch (mode) {
        QuickLogMode.driveTime => 'Apparatus type (optional)',
        QuickLogMode.awardRecognition => 'Organization (optional)',
        QuickLogMode.taskBookProgress => 'Qualification (optional)',
        _ => 'Category (optional)',
      };

  static String _defaultCategory(QuickLogMode mode) => switch (mode) {
        QuickLogMode.callIncident => 'Incident',
        QuickLogMode.skill => 'Skill',
        QuickLogMode.training => 'Training',
        QuickLogMode.driveTime => 'Driver / Operator',
        QuickLogMode.leadership => 'Leadership',
        QuickLogMode.teaching => 'Teaching',
        QuickLogMode.awardRecognition => 'Award / Recognition',
        QuickLogMode.achievement => 'Achievement',
        QuickLogMode.project => 'Project',
        QuickLogMode.education => 'Education',
        QuickLogMode.taskBookProgress => 'Task Book',
        QuickLogMode.custom => 'Custom',
      };

  static String _trackingKey(QuickLogMode mode) => switch (mode) {
        QuickLogMode.driveTime => 'quick.drive_time',
        QuickLogMode.awardRecognition => 'quick.award',
        _ => 'quick.${mode.name}',
      };
}

class _TaskBookLinkCard extends StatelessWidget {
  final LogPrefill? prefill;
  final VoidCallback onChoose;
  final VoidCallback? onClear;

  const _TaskBookLinkCard({
    required this.prefill,
    required this.onChoose,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final linked = prefill?.relatedRequirementId != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: linked ? cs.primaryContainer : cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: linked
              ? cs.primary.withValues(alpha: 0.18)
              : cs.outline.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.fact_check_outlined,
              color: linked ? cs.onPrimaryContainer : cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(linked ? 'TASK BOOK LINKED' : 'TASK BOOK PROGRESS',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  linked
                      ? '${prefill!.category ?? 'Requirement'} → ${prefill!.title}'
                      : 'Choose the requirement or task this work should advance.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChoose,
            child: Text(linked ? 'Change' : 'Choose'),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              tooltip: 'Remove Task Book link',
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

class _TaskChoice {
  final String title;
  final String subtitle;
  final LogPrefill prefill;

  const _TaskChoice({
    required this.title,
    required this.subtitle,
    required this.prefill,
  });
}

class _TaskPickerSheet extends StatefulWidget {
  final String goalTitle;
  final List<_TaskChoice> choices;

  const _TaskPickerSheet({required this.goalTitle, required this.choices});

  @override
  State<_TaskPickerSheet> createState() => _TaskPickerSheetState();
}

class _TaskPickerSheetState extends State<_TaskPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = widget.choices.where((choice) {
      if (query.isEmpty) return true;
      return '${choice.title} ${choice.subtitle}'
          .toLowerCase()
          .contains(query);
    }).toList();

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.goalTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Choose an unfinished Task Book item'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search tasks or qualifications',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No unfinished Task Book items match.'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final choice = visible[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.radio_button_unchecked),
                          title: Text(choice.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(choice.subtitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.pop(choice.prefill),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _trackerIcon(String name) => switch (name) {
      'vaccines' => Icons.vaccines_outlined,
      'medical' => Icons.medical_services_outlined,
      'air' => Icons.air_outlined,
      'heart' => Icons.favorite_border,
      'monitor' => Icons.monitor_heart_outlined,
      'medication' => Icons.medication_outlined,
      'structure' => Icons.apartment_outlined,
      'car' => Icons.directions_car_filled_outlined,
      'fire' => Icons.local_fire_department_outlined,
      'crash' => Icons.car_crash_outlined,
      'water' => Icons.water_drop_outlined,
      'ladder' => Icons.stairs_outlined,
      'tools' => Icons.construction_outlined,
      'search' => Icons.search_outlined,
      'truck' => Icons.local_shipping_outlined,
      'hydrant' => Icons.fire_hydrant_alt_outlined,
      'route' => Icons.alt_route_outlined,
      'checklist' => Icons.checklist_outlined,
      'groups' => Icons.groups_outlined,
      'command' => Icons.radar_outlined,
      'school' => Icons.school_outlined,
      'person' => Icons.person_outline,
      'project' => Icons.assignment_outlined,
      'community' => Icons.diversity_3_outlined,
      _ => Icons.add_task_outlined,
    };

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
