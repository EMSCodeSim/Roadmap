import 'package:flutter/material.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/theme.dart';

enum FastQuickLogResult { moreDetails }

enum _FastMode { call, training, skill, drive, taskBook, career }

extension _FastModeX on _FastMode {
  String get label => switch (this) {
        _FastMode.call => 'CALL',
        _FastMode.training => 'TRAINING',
        _FastMode.skill => 'SKILL',
        _FastMode.drive => 'DRIVE',
        _FastMode.taskBook => 'TASK BOOK',
        _FastMode.career => 'CAREER',
      };

  IconData get icon => switch (this) {
        _FastMode.call => Icons.local_fire_department_outlined,
        _FastMode.training => Icons.school_outlined,
        _FastMode.skill => Icons.handyman_outlined,
        _FastMode.drive => Icons.local_shipping_outlined,
        _FastMode.taskBook => Icons.fact_check_outlined,
        _FastMode.career => Icons.military_tech_outlined,
      };
}

class FastQuickLogSheet extends StatefulWidget {
  final LogPrefill? prefill;

  const FastQuickLogSheet({super.key, this.prefill});

  @override
  State<FastQuickLogSheet> createState() => _FastQuickLogSheetState();
}

class _FastQuickLogSheetState extends State<FastQuickLogSheet> {
  final CareerRecordStore _store = CareerRecordStore();
  _FastMode? _mode;
  String? _choice;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    if ((prefill?.title ?? '').trim().isNotEmpty) {
      _mode = _FastMode.taskBook;
      _choice = prefill!.title!.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  onMoreDetails: () => Navigator.of(context).pop(FastQuickLogResult.moreDetails),
                )
              : _mode != null
                  ? _PresetStep(
                      key: const ValueKey('preset'),
                      mode: _mode!,
                      onBack: () => setState(() => _mode = null),
                      onPick: (value) => setState(() => _choice = value),
                      onMoreDetails: () => Navigator.of(context).pop(FastQuickLogResult.moreDetails),
                    )
                  : _CategoryStep(
                      key: const ValueKey('category'),
                      onPick: (mode) => setState(() => _mode = mode),
                      onMoreDetails: () => Navigator.of(context).pop(FastQuickLogResult.moreDetails),
                    ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_choice == null || _mode == null || _saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final prefill = widget.prefill;
    final mode = _mode!;
    final title = _choice!;
    final record = CareerRecord(
      id: 'ql-${now.microsecondsSinceEpoch.toRadixString(36)}',
      type: _typeFor(mode, title),
      title: title,
      category: (prefill?.category ?? '').trim().isNotEmpty
          ? prefill!.category!.trim()
          : _categoryFor(mode, title),
      date: now,
      roleOrAssignment: null,
      summary: null,
      impact: null,
      evidenceReference: null,
      hours: null,
      repetitions: 1,
      tags: const ['quick-log', 'fast-capture'],
      relatedGoalId: prefill?.relatedGoalId,
      relatedRequirementId: prefill?.relatedRequirementId,
      relatedTaskId: prefill?.relatedTaskId,
      highlight: mode == _FastMode.career,
      trackingKey: mode == _FastMode.drive ? 'fire.driver' : prefill?.trackerKey,
      outcome: mode == _FastMode.taskBook ? CareerRecordOutcome.completed : null,
      details: mode == _FastMode.drive
          ? <String, dynamic>{'apparatusName': title, 'quickCapture': true}
          : const <String, dynamic>{},
      createdAt: now,
      updatedAt: now,
    );
    final ok = await _store.upsert(record);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title logged')),
      );
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the log. Try again.')),
      );
    }
  }

  static CareerRecordType _typeFor(_FastMode mode, String title) => switch (mode) {
        _FastMode.call => CareerRecordType.operationalExperience,
        _FastMode.training => CareerRecordType.training,
        _FastMode.skill => CareerRecordType.skill,
        _FastMode.drive => CareerRecordType.skill,
        _FastMode.taskBook => CareerRecordType.taskBookEvidence,
        _FastMode.career => _careerType(title),
      };

  static CareerRecordType _careerType(String title) {
    final t = title.toLowerCase();
    if (t.contains('teach') || t.contains('instructor') || t.contains('mentor')) {
      return CareerRecordType.teaching;
    }
    if (t.contains('project') || t.contains('committee')) return CareerRecordType.project;
    if (t.contains('class') || t.contains('course') || t.contains('education')) {
      return CareerRecordType.education;
    }
    if (t.contains('lead') || t.contains('acting')) return CareerRecordType.leadership;
    return CareerRecordType.achievement;
  }

  static String _categoryFor(_FastMode mode, String title) => switch (mode) {
        _FastMode.call => 'Call / Incident',
        _FastMode.training => 'Training',
        _FastMode.skill => 'Skill',
        _FastMode.drive => title,
        _FastMode.taskBook => 'Task Book Progress',
        _FastMode.career => 'Career',
      };
}

class _CategoryStep extends StatelessWidget {
  final ValueChanged<_FastMode> onPick;
  final VoidCallback onMoreDetails;

  const _CategoryStep({
    super.key,
    required this.onPick,
    required this.onMoreDetails,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Log',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'What are you logging?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.85,
          ),
          itemCount: _FastMode.values.length,
          itemBuilder: (context, index) {
            final mode = _FastMode.values[index];
            return FilledButton.tonal(
              onPressed: () => onPick(mode),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(14),
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(mode.icon, size: 27),
                  const SizedBox(height: 7),
                  Text(mode.label, style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onMoreDetails,
          icon: const Icon(Icons.tune_outlined),
          label: const Text('Full log / more details'),
        ),
      ],
    );
  }
}

class _PresetStep extends StatelessWidget {
  final _FastMode mode;
  final VoidCallback onBack;
  final ValueChanged<String> onPick;
  final VoidCallback onMoreDetails;

  const _PresetStep({
    super.key,
    required this.mode,
    required this.onBack,
    required this.onPick,
    required this.onMoreDetails,
  });

  @override
  Widget build(BuildContext context) {
    final choices = _presets(mode);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Text(
                mode.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          mode == _FastMode.drive ? 'Which apparatus?' : 'Pick the closest match.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
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
          label: const Text('Custom or more details'),
        ),
      ],
    );
  }

  static List<String> _presets(_FastMode mode) => switch (mode) {
        _FastMode.call => const [
            'EMS call',
            'Structure fire',
            'Vehicle accident',
            'Wildland fire',
            'Alarm response',
            'Public assist',
            'HazMat incident',
            'Technical rescue',
          ],
        _FastMode.training => const [
            'Crew drill',
            'Department training',
            'Physical training',
            'Live fire training',
            'Outside class',
            'Online CE',
            'Company training',
            'Conference',
          ],
        _FastMode.skill => const [
            'Patient assessment',
            'Airway management',
            'IV attempt',
            'Medication administration',
            'Pump operations',
            'Ground ladders',
            'Hose advancement',
            'Search and rescue',
          ],
        _FastMode.drive => const [
            'Engine',
            'Medic',
            'Brush',
            'Tender',
            'Truck / Ladder',
            'Rescue',
            'Chief / Command',
            'Utility',
          ],
        _FastMode.taskBook => const [
            'Task practice',
            'Evaluator sign-off',
            'Knowledge review',
            'Scenario evaluation',
          ],
        _FastMode.career => const [
            'Acting officer',
            'Crew mentoring',
            'Taught a class',
            'Project / committee',
            'Award / recognition',
            'Career milestone',
            'Certification course',
            'Leadership course',
          ],
      };
}

class _ConfirmStep extends StatelessWidget {
  final _FastMode mode;
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(onPressed: saving ? null : onBack, icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Text(
                'Ready to save',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Icon(mode.icon, size: 30, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(choice, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Saves one occurrence for today. Add miles, hours, notes, outcomes, task links, or other details only when you need them.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: Text(saving ? 'Saving…' : 'Save Quick Log'),
          ),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: saving ? null : onMoreDetails,
          icon: const Icon(Icons.tune_outlined),
          label: const Text('Add more details instead'),
        ),
      ],
    );
  }
}
