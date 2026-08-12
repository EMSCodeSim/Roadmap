import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/quick_log_tracker.dart';
import 'package:firepath/models/quick_log_template.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/quick_log_preferences_store.dart';
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
  CareerRecord? _repeatDraft;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final loadedPrefs = await _preferencesStore.load();
      final config = _configFromPreferences(loadedPrefs);
      final loadedRecords = await _recordStore.load();
      loadedRecords.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _config = config;
        _records = loadedRecords;
        _loading = false;
      });

      if (widget.prefill?.relatedRequirementId != null ||
          widget.prefill?.relatedTaskId != null) {
        setState(() => _mode = QuickLogMode.taskBookProgress);
      }
    } catch (e) {
      debugPrint('QuickLog init failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  static QuickLogConfig _configFromPreferences(QuickLogPreferences preferences) {
    final custom = preferences.customTemplates
        .map((template) => QuickLogTracker(
              keyName: template.id,
              title: template.title,
              category: template.category,
              type: template.type,
              iconName: template.iconKey,
              tracksOutcome: template.tracksOutcome,
            ))
        .toList();
    final pinned = preferences.pinnedIds;
    final guessedPreset = _guessRolePreset(pinned);
    return QuickLogConfig(
      rolePreset: guessedPreset,
      pinnedKeys: pinned,
      customTrackers: custom,
    );
  }

  static QuickLogRolePreset? _guessRolePreset(List<String> pinnedIds) {
    for (final preset in QuickLogRolePreset.values) {
      final defaults = QuickLogCatalog.defaultsFor(preset);
      if (defaults.toSet().containsAll(pinnedIds.toSet())) return preset;
    }
    return null;
  }

  List<QuickLogTracker> get _pinnedTrackers => _config.pinnedKeys
      .map((key) => QuickLogCatalog.byKey(key, _config.customTrackers))
      .whereType<QuickLogTracker>()
      .toList();

  List<CareerRecord> get _recentRecords => _records.take(6).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                onPickMode: (m) => setState(() => _mode = m),
                onPickPinned: (t) => _openPinnedTracker(t),
                onPickRecent: (r) => _repeatRecord(r),
              )
            : _QuickLogForm(
                mode: _mode!,
                prefill: widget.prefill,
                repeatDraft: _repeatDraft,
                onBack: () => setState(() {
                  _repeatDraft = null;
                  _mode = null;
                }),
                onSaved: (saved) async {
                  await _recordStore.upsert(saved);
                  if (!mounted) return;
                  await _showSavedToast(context, saved, cs);
                  context.pop();
                },
              ),
      ),
    );
  }

  Future<void> _openPinnedTracker(QuickLogTracker tracker) async {
    final prefill = widget.prefill;
    final mode = switch (tracker.type) {
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
    setState(() => _mode = mode);

    // Preload title/category into the prefill so the form is 1-tap.
    if (prefill == null) {
      setState(() {
        // not stored, form handles tracker hint
      });
    }
  }

  Future<void> _repeatRecord(CareerRecord record) async {
    setState(() {
      _mode = switch (record.type) {
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
      _repeatDraft = record;
    });
  }

  static Future<void> _showSavedToast(
      BuildContext context, CareerRecord record, ColorScheme cs) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved: ${record.title}'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
      ),
    );
  }
}

class _Chooser extends StatelessWidget {
  final bool loading;
  final List<QuickLogTracker> pinned;
  final List<CareerRecord> recent;
  final ValueChanged<QuickLogMode> onPickMode;
  final ValueChanged<QuickLogTracker> onPickPinned;
  final ValueChanged<CareerRecord> onPickRecent;

  const _Chooser(
      {required this.loading,
      required this.pinned,
      required this.recent,
      required this.onPickMode,
      required this.onPickPinned,
      required this.onPickRecent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('chooser'),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: [
        Text('Quick Log',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(
          'What are you logging?',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
        ),
        const SizedBox(height: 14),
        if (pinned.isNotEmpty) ...[
          Text('QUICK ACTIONS',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: pinned
                .map((t) => _ActionChip(
                      label: t.title,
                      icon: _trackerIcon(t.iconName),
                      onTap: () => onPickPinned(t),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
        ],
        if (recent.isNotEmpty) ...[
          Text('RECENT',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...recent.map((r) => _RecentTile(record: r, onTap: () => onPickRecent(r))),
          const SizedBox(height: 18),
        ],
        Text('TYPES',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...QuickLogMode.values.map((m) => _BigPickTile(
              label: m.label,
              icon: m.icon,
              onTap: () => onPickMode(m),
            )),
        const SizedBox(height: 8),
        if (loading)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.primary)),
                const SizedBox(width: 10),
                Text('Loading…',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
      ],
    );
  }

  static IconData _trackerIcon(String name) => switch (name) {
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
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: cs.onSecondaryContainer),
            const SizedBox(width: 8),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: cs.onSecondaryContainer)),
          ],
        ),
      ),
    );
  }
}

class _BigPickTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _BigPickTile(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final CareerRecord record;
  final VoidCallback onTap;
  const _RecentTile({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Icon(Icons.history, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      '${record.type.shortLabel} • ${record.category}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLogForm extends StatefulWidget {
  final QuickLogMode mode;
  final LogPrefill? prefill;
  final CareerRecord? repeatDraft;
  final VoidCallback onBack;
  final ValueChanged<CareerRecord> onSaved;
  const _QuickLogForm(
      {required this.mode,
      required this.prefill,
      required this.repeatDraft,
      required this.onBack,
      required this.onSaved});

  @override
  State<_QuickLogForm> createState() => _QuickLogFormState();
}

class _QuickLogFormState extends State<_QuickLogForm> {
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _note = TextEditingController();
  final _role = TextEditingController();
  final _hours = TextEditingController();
  final _reps = TextEditingController(text: '1');
  CareerRecordOutcome? _outcome;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.repeatDraft;
    if (d != null) {
      _title.text = d.title;
      _category.text = d.category;
      _note.text = d.summary ?? '';
      _role.text = d.roleOrAssignment ?? '';
      if (d.hours != null) _hours.text = d.hours!.toString();
      if (d.repetitions > 0) _reps.text = d.repetitions.toString();
      _outcome = d.outcome;
      _date = DateTime.now();
    } else {
      _title.text = widget.prefill?.title ?? '';
      _category.text = widget.prefill?.category ?? '';
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

  bool get _usesHours => switch (widget.mode) {
        QuickLogMode.training => true,
        QuickLogMode.driveTime => true,
        QuickLogMode.teaching => true,
        QuickLogMode.project => false,
        QuickLogMode.education => true,
        _ => false,
      };

  bool get _usesReps => switch (widget.mode) {
        QuickLogMode.skill => true,
        QuickLogMode.taskBookProgress => true,
        _ => false,
      };

  bool get _tracksOutcome => widget.mode == QuickLogMode.skill;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = context.read<AppState>();

    return ListView(
      key: ValueKey('form_${widget.mode.name}'),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _saving ? null : widget.onBack,
              icon: const Icon(Icons.chevron_left),
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
        const SizedBox(height: 10),
        if (widget.mode == QuickLogMode.taskBookProgress)
          _TaskBookSuggestCard(prefill: widget.prefill),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: _labelForTitle(widget.mode),
            hintText: _hintForTitle(widget.mode),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_categoryEnabled(widget.mode))
          TextField(
            controller: _category,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: _labelForCategory(widget.mode),
              hintText: _hintForCategory(widget.mode),
            ),
          ),
        if (_categoryEnabled(widget.mode)) const SizedBox(height: AppSpacing.md),
        if (_usesReps)
          TextField(
            controller: _reps,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Repetitions', hintText: '1'),
          ),
        if (_usesReps) const SizedBox(height: AppSpacing.md),
        if (_usesHours)
          TextField(
            controller: _hours,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Duration (hours)', hintText: '1.5'),
          ),
        if (_usesHours) const SizedBox(height: AppSpacing.md),
        if (_tracksOutcome)
          DropdownButtonFormField<CareerRecordOutcome?>(
            value: _outcome,
            items: [
              const DropdownMenuItem(value: null, child: Text('No outcome')),
              ...[
                CareerRecordOutcome.successful,
                CareerRecordOutcome.unsuccessful,
                CareerRecordOutcome.attempted
              ].map((o) => DropdownMenuItem(value: o, child: Text(o.label)))
            ],
            onChanged: (v) => setState(() => _outcome = v),
            decoration: const InputDecoration(labelText: 'Outcome'),
          ),
        if (_tracksOutcome) const SizedBox(height: AppSpacing.md),
        if (_roleEnabled(widget.mode))
          TextField(
            controller: _role,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Role / assignment (optional)'),
          ),
        if (_roleEnabled(widget.mode)) const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    final rec = _buildRecord();
                    if (rec == null) return;
                    setState(() => _saving = true);
                    try {
                      widget.onSaved(rec);
                      // Update state-backed progress only when safe and linked.
                      if (rec.relatedGoalId != null && rec.relatedRequirementId != null) {
                        await state.applyLogToRequirementProgress(rec);
                      }
                    } catch (e) {
                      debugPrint('QuickLog save failed: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Could not save log entry.'),
                          backgroundColor: cs.error,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            icon: Icon(Icons.check_circle, color: cs.onPrimary),
            label: Text('Save', style: TextStyle(color: cs.onPrimary)),
            style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg))),
          ),
        ),
      ],
    );
  }

  CareerRecord? _buildRecord() {
    final title = _title.text.trim();
    if (title.isEmpty) return null;
    final category = _category.text.trim();
    final reps = int.tryParse(_reps.text.trim()) ?? 1;
    final hours = double.tryParse(_hours.text.trim());
    final now = DateTime.now();
    return CareerRecord(
      id: now.microsecondsSinceEpoch.toString(),
      type: _recordType,
      title: title,
      category: category,
      date: _date,
      roleOrAssignment: _role.text.trim().isEmpty ? null : _role.text.trim(),
      summary: _note.text.trim().isEmpty ? null : _note.text.trim(),
      impact: null,
      evidenceReference: null,
      hours: _usesHours ? hours : null,
      repetitions: _usesReps ? reps : 1,
      tags: widget.prefill?.tags ?? const [],
      relatedGoalId: widget.prefill?.relatedGoalId,
      relatedRequirementId: widget.prefill?.relatedRequirementId,
      relatedTaskId: widget.prefill?.relatedTaskId,
      highlight: false,
      trackingKey: null,
      outcome: _outcome,
      createdAt: now,
      updatedAt: now,
    );
  }

  static bool _categoryEnabled(QuickLogMode mode) => switch (mode) {
        QuickLogMode.callIncident => true,
        QuickLogMode.skill => false,
        QuickLogMode.training => false,
        QuickLogMode.driveTime => true,
        QuickLogMode.leadership => true,
        QuickLogMode.teaching => true,
        QuickLogMode.awardRecognition => true,
        QuickLogMode.achievement => true,
        QuickLogMode.project => true,
        QuickLogMode.education => true,
        QuickLogMode.taskBookProgress => true,
        QuickLogMode.custom => true,
      };

  static bool _roleEnabled(QuickLogMode mode) => switch (mode) {
        QuickLogMode.callIncident => true,
        QuickLogMode.leadership => true,
        QuickLogMode.teaching => true,
        QuickLogMode.project => true,
        _ => false,
      };

  static String _labelForTitle(QuickLogMode mode) => switch (mode) {
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

  static String _hintForTitle(QuickLogMode mode) => switch (mode) {
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
        QuickLogMode.taskBookProgress => 'Drafting from static water source…',
        QuickLogMode.custom => 'What happened?',
      };

  static String _labelForCategory(QuickLogMode mode) => switch (mode) {
        QuickLogMode.callIncident => 'Category (optional)',
        QuickLogMode.driveTime => 'Apparatus type (optional)',
        QuickLogMode.leadership => 'Role / assignment (optional)',
        QuickLogMode.teaching => 'Role (optional)',
        QuickLogMode.awardRecognition => 'Organization (optional)',
        QuickLogMode.achievement => 'Category (optional)',
        QuickLogMode.project => 'Role (optional)',
        QuickLogMode.education => 'Category (optional)',
        QuickLogMode.taskBookProgress => 'Qualification (optional)',
        QuickLogMode.custom => 'Category (optional)',
        _ => 'Category',
      };

  static String _hintForCategory(QuickLogMode mode) => switch (mode) {
        QuickLogMode.taskBookProgress => 'Driver Operator – Pumper',
        QuickLogMode.driveTime => 'Engine, truck, tender…',
        _ => '',
      };
}

class _TaskBookSuggestCard extends StatelessWidget {
  final LogPrefill? prefill;
  const _TaskBookSuggestCard({required this.prefill});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final roadmap = state.roadmap;
    final goalTitle = roadmap?.goal.title;
    final requirement = prefill?.relatedRequirementId == null
        ? null
        : roadmap?.all
            .where((r) => r.requirement.id == prefill!.relatedRequirementId)
            .firstOrNull;
    final scope = <String>[];
    if (goalTitle != null && goalTitle.trim().isNotEmpty) scope.add(goalTitle);
    if (prefill?.category != null && (prefill!.category ?? '').trim().isNotEmpty) scope.add(prefill!.category!);
    if (requirement != null) scope.add(requirement.requirement.name);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.fact_check, color: cs.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Task Book link',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  scope.isEmpty ? 'Optional — log can stand alone.' : scope.join(' → '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onPrimaryContainer, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
