import 'package:flutter/material.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/theme.dart';

enum SimpleQuickLogResult { moreDetails }

enum _SimpleMode { training, call, skill, drive, career, taskBook }

extension _SimpleModeX on _SimpleMode {
  String get label => switch (this) {
        _SimpleMode.training => 'TRAINING',
        _SimpleMode.call => 'CALL',
        _SimpleMode.skill => 'SKILL',
        _SimpleMode.drive => 'DRIVING',
        _SimpleMode.career => 'CAREER',
        _SimpleMode.taskBook => 'TASK BOOK',
      };

  IconData get icon => switch (this) {
        _SimpleMode.training => Icons.school_outlined,
        _SimpleMode.call => Icons.local_fire_department_outlined,
        _SimpleMode.skill => Icons.handyman_outlined,
        _SimpleMode.drive => Icons.local_shipping_outlined,
        _SimpleMode.career => Icons.military_tech_outlined,
        _SimpleMode.taskBook => Icons.fact_check_outlined,
      };
}

class SimpleQuickLogSheet extends StatefulWidget {
  final LogPrefill? prefill;

  const SimpleQuickLogSheet({super.key, this.prefill});

  @override
  State<SimpleQuickLogSheet> createState() => _SimpleQuickLogSheetState();
}

class _SimpleQuickLogSheetState extends State<SimpleQuickLogSheet> {
  final CareerRecordStore _store = CareerRecordStore();
  _SimpleMode? _mode;
  String? _choice;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    if ((prefill?.title ?? '').trim().isNotEmpty) {
      _mode = _SimpleMode.taskBook;
      _choice = prefill!.title.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          child: _choice != null
              ? _ConfirmStep(
                  key: const ValueKey('confirm'),
                  mode: _mode!,
                  choice: _choice!,
                  saving: _saving,
                  onBack: () => setState(() => _choice = null),
                  onSave: _save,
                  onMoreDetails: () => Navigator.of(context)
                      .pop(SimpleQuickLogResult.moreDetails),
                )
              : _mode != null
                  ? _ChoiceStep(
                      key: const ValueKey('choice'),
                      mode: _mode!,
                      onBack: () => setState(() => _mode = null),
                      onPick: (value) => setState(() => _choice = value),
                      onMoreDetails: () => Navigator.of(context)
                          .pop(SimpleQuickLogResult.moreDetails),
                    )
                  : _CategoryStep(
                      key: const ValueKey('category'),
                      onPick: (mode) => setState(() => _mode = mode),
                      onMoreDetails: () => Navigator.of(context)
                          .pop(SimpleQuickLogResult.moreDetails),
                    ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_mode == null || _choice == null || _saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final mode = _mode!;
    final title = _choice!;
    final prefill = widget.prefill;

    final record = CareerRecord(
      id: 'ql-${now.microsecondsSinceEpoch.toRadixString(36)}',
      type: _recordType(mode, title),
      title: title,
      category: (prefill?.category ?? '').trim().isNotEmpty
          ? prefill!.category!.trim()
          : _category(mode),
      date: now,
      roleOrAssignment: null,
      summary: null,
      impact: null,
      evidenceReference: null,
      hours: null,
      repetitions: 1,
      tags: const ['quick-log', 'simple-capture'],
      relatedGoalId: prefill?.relatedGoalId,
      relatedRequirementId: prefill?.relatedRequirementId,
      relatedTaskId: prefill?.relatedTaskId,
      highlight: mode == _SimpleMode.career,
      trackingKey: mode == _SimpleMode.drive ? 'fire.driver' : prefill?.trackerKey,
      outcome: mode == _SimpleMode.taskBook
          ? CareerRecordOutcome.completed
          : null,
      details: mode == _SimpleMode.drive
          ? <String, dynamic>{'apparatusName': title, 'quickCapture': true}
          : const <String, dynamic>{},
      createdAt: now,
      updatedAt: now,
    );

    final ok = await _store.upsert(record);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title logged')),
      );
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the log. Try again.')),
      );
    }
  }

  static CareerRecordType _recordType(_SimpleMode mode, String title) =>
      switch (mode) {
        _SimpleMode.training => CareerRecordType.training,
        _SimpleMode.call => CareerRecordType.operationalExperience,
        _SimpleMode.skill => CareerRecordType.skill,
        _SimpleMode.drive => CareerRecordType.skill,
        _SimpleMode.taskBook => CareerRecordType.taskBookEvidence,
        _SimpleMode.career => _careerType(title),
      };

  static CareerRecordType _careerType(String title) {
    final value = title.toLowerCase();
    if (value.contains('lead')) return CareerRecordType.leadership;
    if (value.contains('teach') || value.contains('instructor')) {
      return CareerRecordType.teaching;
    }
    if (value.contains('project')) return CareerRecordType.project;
    if (value.contains('education')) return CareerRecordType.education;
    return CareerRecordType.achievement;
  }

  static String _category(_SimpleMode mode) => switch (mode) {
        _SimpleMode.training => 'Training',
        _SimpleMode.call => 'Call / Incident',
        _SimpleMode.skill => 'Skill',
        _SimpleMode.drive => 'Driving',
        _SimpleMode.career => 'Career',
        _SimpleMode.taskBook => 'Task Book Progress',
      };
}

class _CategoryStep extends StatelessWidget {
  final ValueChanged<_SimpleMode> onPick;
  final VoidCallback onMoreDetails;

  const _CategoryStep({
    super.key,
    required this.onPick,
    required this.onMoreDetails,
  });

  static const _orderedModes = <_SimpleMode>[
    _SimpleMode.training,
    _SimpleMode.call,
    _SimpleMode.skill,
    _SimpleMode.drive,
    _SimpleMode.career,
    _SimpleMode.taskBook,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Log',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'What are you logging?',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.85,
          ),
          itemCount: _orderedModes.length,
          itemBuilder: (context, index) {
            final mode = _orderedModes[index];
            return FilledButton.tonal(
              onPressed: () => onPick(mode),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(14),
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(mode.icon, size: 27),
                  const SizedBox(height: 7),
                  Text(
                    mode.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onMoreDetails,
          icon: const Icon(Icons.tune_outlined),
          label: const Text('Full log / more details'),
        ),
      ],
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  final _SimpleMode mode;
  final VoidCallback onBack;
  final ValueChanged<String> onPick;
  final VoidCallback onMoreDetails;

  const _ChoiceStep({
    super.key,
    required this.mode,
    required this.onBack,
    required this.onPick,
    required this.onMoreDetails,
  });

  @override
  Widget build(BuildContext context) {
    final choices = _choices(mode);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  mode.label,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _prompt(mode),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.05,
            ),
            itemCount: choices.length,
            itemBuilder: (context, index) => FilledButton.tonal(
              onPressed: () => onPick(choices[index]),
              child: Text(choices[index], textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onMoreDetails,
            icon: const Icon(Icons.add),
            label: const Text('Custom / more details'),
          ),
        ],
      ),
    );
  }

  static String _prompt(_SimpleMode mode) => switch (mode) {
        _SimpleMode.training => 'What kind of training?',
        _SimpleMode.call => 'What kind of call?',
        _SimpleMode.skill => 'What skill did you practice?',
        _SimpleMode.drive => 'Which apparatus?',
        _SimpleMode.career => 'What career activity?',
        _SimpleMode.taskBook => 'What did you do in your Task Book?',
      };
}

class _ConfirmStep extends StatelessWidget {
  final _SimpleMode mode;
  final String choice;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onMoreDetails;

  const _ConfirmStep({
    super.key,
    required this.mode,
    required this.choice,
    required this.saving,
    required this.onBack,
    required this.onSave,
    required this.onMoreDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                'Ready to log',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Icon(mode.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      choice,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(saving ? 'Saving…' : 'Save Log'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onMoreDetails,
          icon: const Icon(Icons.tune_outlined),
          label: const Text('Add details instead'),
        ),
      ],
    );
  }
}

List<String> _choices(_SimpleMode mode) => switch (mode) {
      _SimpleMode.training => const [
          'Crew drill',
          'Department training',
          'Live fire',
          'Outside class',
          'Online CE',
          'Physical training',
        ],
      _SimpleMode.call => const [
          'EMS call',
          'Structure fire',
          'Vehicle accident',
          'Wildland fire',
          'HazMat incident',
          'Public assist',
        ],
      _SimpleMode.skill => const [
          'Pump operations',
          'Ground ladders',
          'Hose advancement',
          'Search and rescue',
          'Patient assessment',
          'Airway management',
        ],
      _SimpleMode.drive => const [
          'Engine',
          'Medic',
          'Brush',
          'Tender',
          'Truck / Ladder',
          'Rescue',
        ],
      _SimpleMode.career => const [
          'Leadership',
          'Teaching / Instructor',
          'Achievement',
          'Award / Recognition',
          'Project',
          'Education',
        ],
      _SimpleMode.taskBook => const [
          'Task practice',
          'Evaluator sign-off',
          'Knowledge review',
          'Scenario evaluation',
        ],
    };
