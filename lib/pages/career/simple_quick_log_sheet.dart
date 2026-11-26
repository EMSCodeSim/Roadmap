import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/quick_log_template.dart';
import 'package:firepath/models/quick_log_tracker.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_stats.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/quick_log_preferences_store.dart';
import 'package:firepath/services/scored_skill_store.dart';
import 'package:firepath/services/department_activity_sharing.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/keyboard_aware_form.dart';

enum SimpleQuickLogResult { moreDetails, scanDepartmentQr }

enum _SimpleMode { training, call, skill, exposure, drive, career, taskBook }

enum _DriveActivity { response, training, other }

extension _SimpleModeX on _SimpleMode {
  String get label => switch (this) {
        _SimpleMode.training => 'TRAINING',
        _SimpleMode.call => 'CALL',
        _SimpleMode.skill => 'SKILL',
        _SimpleMode.exposure => 'EXPOSURE',
        _SimpleMode.drive => 'DRIVING',
        _SimpleMode.career => 'CAREER',
        _SimpleMode.taskBook => 'TASK BOOK',
      };

  IconData get icon => switch (this) {
        _SimpleMode.training => Icons.school_outlined,
        _SimpleMode.call => Icons.local_fire_department_outlined,
        _SimpleMode.skill => Icons.handyman_outlined,
        _SimpleMode.exposure => Icons.health_and_safety_outlined,
        _SimpleMode.drive => Icons.local_shipping_outlined,
        _SimpleMode.career => Icons.military_tech_outlined,
        _SimpleMode.taskBook => Icons.fact_check_outlined,
      };

  Color get color => switch (this) {
        _SimpleMode.training => LightModeColors.trainingBlue,
        _SimpleMode.call => LightModeColors.opsRed,
        _SimpleMode.skill => LightModeColors.skillsTeal,
        _SimpleMode.exposure => LightModeColors.exposureOrange,
        _SimpleMode.drive => LightModeColors.drivingAmber,
        _SimpleMode.career => LightModeColors.growthPurple,
        _SimpleMode.taskBook => const Color(0xFF475569),
      };
}

class SimpleQuickLogSheet extends StatefulWidget {
  final LogPrefill? prefill;
  final bool showDepartmentQrAction;

  const SimpleQuickLogSheet({
    super.key,
    this.prefill,
    this.showDepartmentQrAction = true,
  });

  @override
  State<SimpleQuickLogSheet> createState() => _SimpleQuickLogSheetState();
}

class _SimpleQuickLogSheetState extends State<SimpleQuickLogSheet> {
  final CareerRecordStore _store = CareerRecordStore();
  final QuickLogPreferencesStore _preferencesStore = QuickLogPreferencesStore();
  final ScoredSkillStore _scoredSkillStore = ScoredSkillStore();
  final DepartmentActivitySharingService _sharing = DepartmentActivitySharingService();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _miles = TextEditingController();
  final TextEditingController _durationMinutes = TextEditingController();
  final TextEditingController _repetitions = TextEditingController(text: '1');
  final TextEditingController _role = TextEditingController();

  _SimpleMode? _mode;
  String? _choice;
  bool _saving = false;
  bool _saved = false;
  bool _emergent = false;
  bool _transport = false;
  _DriveActivity _driveActivity = _DriveActivity.response;
  CareerRecordOutcome? _skillOutcome;
  bool _shareWithDepartment = false;
  int _priorityRank = 0;
  List<String> _quickActionKeys =
      List<String>.from(QuickLogPreferencesStore.defaultQuickActionKeys);
  List<QuickLogTracker> _pinnedTrackers = const [];
  QuickLogTracker? _selectedTracker;
  CareerSuccessStats? _skillStats;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    if ((prefill?.title ?? '').trim().isNotEmpty) {
      _mode = _SimpleMode.taskBook;
      _choice = prefill!.title.trim();
    }
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await _preferencesStore.load();
    final custom = preferences.customTemplates
        .map(_trackerFromTemplate)
        .toList(growable: false);
    final pinned = preferences.pinnedIds
        .map((key) => QuickLogCatalog.byKey(key, custom))
        .whereType<QuickLogTracker>()
        .toList(growable: false);
    if (!mounted) return;
    setState(() {
      _quickActionKeys = List<String>.from(preferences.quickActionKeys);
      _pinnedTrackers = pinned;
    });
  }

  static QuickLogTracker _trackerFromTemplate(QuickLogTemplate template) =>
      QuickLogTracker(
        keyName: template.id,
        title: template.title,
        category: template.category,
        type: template.type,
        iconName: template.iconKey,
        tracksOutcome:
            template.type == CareerRecordType.skill || template.tracksOutcome,
        custom: template.isCustom,
      );

  @override
  void dispose() {
    _notes.dispose();
    _miles.dispose();
    _durationMinutes.dispose();
    _repetitions.dispose();
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 140),
          child: _saved
              ? const _SavedConfirmation(key: ValueKey('saved'))
              : _choice != null
              ? _ConfirmStep(
                  key: ValueKey('confirm-${_mode!.name}'),
                  mode: _mode!,
                  choice: _choice!,
                  saving: _saving,
                  notes: _notes,
                  miles: _miles,
                  durationMinutes: _durationMinutes,
                  repetitions: _repetitions,
                  role: _role,
                  emergent: _emergent,
                  transport: _transport,
                  driveActivity: _driveActivity,
                  skillOutcome: _skillOutcome,
                  skillStats: _skillStats,
                  shareWithDepartment: _shareWithDepartment,
                  priorityRank: _priorityRank,
                  departmentConnected: context.watch<AppModeController>().departmentLink != null,
                  onEmergentChanged: (value) =>
                      setState(() => _emergent = value),
                  onTransportChanged: (value) =>
                      setState(() => _transport = value),
                  onDriveActivityChanged: (value) =>
                      setState(() => _driveActivity = value),
                  onSkillOutcomeChanged: (value) =>
                      setState(() => _skillOutcome = value),
                  onShareChanged: (value) =>
                      setState(() => _shareWithDepartment = value),
                  onPriorityRankChanged: (value) =>
                      setState(() => _priorityRank = value),
                  onBack: () => setState(() => _choice = null),
                  onSave: _save,
                  onMoreDetails: () => Navigator.of(context)
                      .pop(SimpleQuickLogResult.moreDetails),
                )
              : _mode != null
                  ? _ChoiceStep(
                      key: const ValueKey('choice'),
                      mode: _mode!,
                      customChoices: _trackersForMode(_mode!),
                      onBack: () => setState(() => _mode = null),
                      onPick: _pickChoice,
                      onCustomize: _openCustomization,
                      onMoreDetails: () => Navigator.of(context)
                          .pop(SimpleQuickLogResult.moreDetails),
                    )
                  : _CategoryStep(
                      key: const ValueKey('category'),
                      onPick: (mode) => setState(() => _mode = mode),
                      visibleModes: _visibleModes,
                      onCustomize: _openCustomization,
                      onTrainingResources: _openTrainingResources,
                      showScanQr: widget.showDepartmentQrAction,
                      onScanQr: () => Navigator.of(context)
                          .pop(SimpleQuickLogResult.scanDepartmentQr),
                    ),
        ),
      ),
    );
  }

  List<_SimpleMode> get _visibleModes {
    final modes = _quickActionKeys
        .map(_modeForActionKey)
        .whereType<_SimpleMode>()
        .where((mode) => mode != _SimpleMode.taskBook)
        .toSet()
        .toList();
    return modes.isEmpty ? _CategoryStep.defaultModes : modes;
  }

  static _SimpleMode? _modeForActionKey(String key) => switch (key) {
        'training' => _SimpleMode.training,
        'call' => _SimpleMode.call,
        'skill' => _SimpleMode.skill,
        'exposure' => _SimpleMode.exposure,
        'drive' => _SimpleMode.drive,
        'career' => _SimpleMode.career,
        'task_book' => _SimpleMode.taskBook,
        _ => null,
      };

  List<QuickLogTracker> _trackersForMode(_SimpleMode mode) => _pinnedTrackers
      .where((tracker) => _modeForTracker(tracker) == mode)
      .toList(growable: false);

  static _SimpleMode _modeForTracker(QuickLogTracker tracker) {
    final haystack = '${tracker.title} ${tracker.category}'.toLowerCase();
    if (tracker.keyName == 'fire.driver') return _SimpleMode.drive;
    return switch (tracker.type) {
      CareerRecordType.skill => _SimpleMode.skill,
      CareerRecordType.training => _SimpleMode.training,
      CareerRecordType.operationalExperience =>
        haystack.contains('exposure') ? _SimpleMode.exposure : _SimpleMode.call,
      CareerRecordType.taskBookEvidence => _SimpleMode.taskBook,
      _ => _SimpleMode.career,
    };
  }

  Future<void> _openCustomization() async {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    await Future<void>.delayed(Duration.zero);
    await router.push(AppRoutes.quickLogSetup);
  }

  Future<void> _openTrainingResources() async {
    final destination = await showModalBottomSheet<Uri>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose training library',
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Find drills, scenarios, skills, and learning resources.',
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            _TrainingLibraryChoice(
              key: const Key('training_library_ems'),
              icon: Icons.medical_services_outlined,
              title: 'EMS Training',
              subtitle: 'Open EMSCodeSim',
              onTap: () => Navigator.of(sheetContext).pop(
                Uri.parse('https://emscodesim.com/ems-training-library.html'),
              ),
            ),
            const SizedBox(height: 10),
            _TrainingLibraryChoice(
              key: const Key('training_library_fire'),
              icon: Icons.local_fire_department_outlined,
              title: 'Fire Training',
              subtitle: 'Open FireOpsSim',
              onTap: () => Navigator.of(sheetContext).pop(
                Uri.parse(
                  'https://fireopssim.com/fire-service-training-library.html',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (destination == null || !mounted) return;
    final opened = await launchUrl(
      destination,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the training library.')),
      );
    }
  }

  Future<void> _pickChoice(String value) async {
    QuickLogTracker? tracker;
    for (final item in _trackersForMode(_mode!)) {
      if (item.title == value) {
        tracker = item;
        break;
      }
    }
    setState(() {
      _choice = value;
      _selectedTracker = tracker;
      _skillStats = null;
      _skillOutcome = null;
    });
    if (_mode != _SimpleMode.skill) return;
    final records = await _store.load();
    final key = tracker?.keyName ?? ScoredSkillStore.keyForTitle(value);
    if (!mounted || _choice != value) return;
    setState(() {
      _skillStats = CareerStats.successFor(records, trackingKey: key);
    });
  }

  Future<void> _save() async {
    if (_mode == null || _choice == null || _saving) return;
    if (_mode == _SimpleMode.skill && _skillOutcome == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose Successful, Attempted, or Unsuccessful.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);

    final now = DateTime.now();
    final mode = _mode!;
    final title = _choice!;
    final prefill = widget.prefill;
    final notes = _notes.text.trim();
    final duration = double.tryParse(_durationMinutes.text.trim());
    final repetitions = int.tryParse(_repetitions.text.trim()) ?? 1;

    final record = CareerRecord(
      id: 'ql-${now.microsecondsSinceEpoch.toRadixString(36)}',
      type: _recordType(mode, title),
      title: title,
      category: (prefill?.category ?? '').trim().isNotEmpty
          ? prefill!.category!.trim()
          : (_selectedTracker?.category ?? _category(mode)),
      date: now,
      roleOrAssignment: _role.text.trim().isEmpty ? null : _role.text.trim(),
      summary: notes.isEmpty ? null : notes,
      impact: null,
      evidenceReference: null,
      hours: duration == null || duration <= 0 ? null : duration / 60,
      repetitions: repetitions < 1 ? 1 : repetitions,
      tags: _tagsFor(mode),
      relatedGoalId: prefill?.relatedGoalId,
      relatedRequirementId: prefill?.relatedRequirementId,
      relatedTaskId: prefill?.relatedTaskId,
      highlight: mode == _SimpleMode.career,
      trackingKey: _trackingKey(
        mode,
        title,
        prefill?.trackerKey ?? _selectedTracker?.keyName,
      ),
      outcome: mode == _SimpleMode.skill
          ? _skillOutcome
          : mode == _SimpleMode.taskBook
              ? CareerRecordOutcome.completed
              : null,
      details: {
        ..._detailsFor(mode, title),
        'visibility': _shareWithDepartment ? 'department_shared' : 'personal',
        'shareWithDepartment': _shareWithDepartment,
        'priorityRank': _priorityRank,
      },
      createdAt: now,
      updatedAt: now,
    );

    final ok = await _store.upsert(record);
    if (!mounted) return;
    if (ok) {
      if (mode == _SimpleMode.skill) {
        await _ensureSkillMetric(record);
      }
      try {
        await context.read<AppState>().applyLogToRequirementProgress(record);
      } catch (_) {
        // Personal history is already durable. Adaptive roadmap updates are
        // best-effort and must never block the field log from saving.
      }
      if (!mounted) return;
      var shared = false;
      if (_shareWithDepartment) {
        try {
          await _sharing.sync();
          shared = true;
        } catch (_) {
          // Keep the local record and sharing intent. A later shared save can
          // retry the full set without losing the responder's entry.
        }
      }
      if (!mounted) return;
      // Small confirmation animation inside the sheet (more personal than a
      // snackbar, and avoids competing with navigation).
      setState(() {
        _saved = true;
        _saving = false;
      });
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (!reduceMotion) {
        await Future<void>.delayed(const Duration(milliseconds: 520));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the log. Try again.')),
      );
    }
  }

  Future<void> _ensureSkillMetric(CareerRecord record) async {
    final key = CareerStats.skillTrackingKey(record);
    if (key == null) return;
    final current = await _scoredSkillStore.load();
    if (current.any((item) => item.keyName == key)) return;
    await _scoredSkillStore.save([
      ...current,
      ScoredSkillPreference(keyName: key, title: record.title),
    ]);
  }

  Map<String, dynamic> _detailsFor(_SimpleMode mode, String title) {
    switch (mode) {
      case _SimpleMode.drive:
        final miles = double.tryParse(_miles.text.trim());
        return <String, dynamic>{
          'apparatusName': title,
          if (miles != null && miles >= 0) 'miles': miles,
          'emergent': _emergent,
          'patientTransport': _transport,
          'activityType': _driveActivity.name,
          'quickCapture': true,
        };
      case _SimpleMode.call:
        return <String, dynamic>{
          'emergent': _emergent,
          'patientTransport': _transport,
          'quickCapture': true,
        };
      case _SimpleMode.skill:
        return <String, dynamic>{
          if (_skillOutcome != null) 'outcome': _skillOutcome!.name,
          'quickCapture': true,
        };
      case _SimpleMode.exposure:
        return <String, dynamic>{
          'possibleHealthExposure': true,
          'officialExposureReport': false,
          'officerFollowUpRequired': true,
          'quickCapture': true,
        };
      case _SimpleMode.training:
        return const <String, dynamic>{'quickCapture': true};
      case _SimpleMode.career:
        return const <String, dynamic>{'quickCapture': true};
      case _SimpleMode.taskBook:
        return const <String, dynamic>{'quickCapture': true};
    }
  }

  static List<String> _tagsFor(_SimpleMode mode) => <String>[
        'quick-log',
        'simple-capture',
        mode.name,
      ];

  static String? _trackingKey(
    _SimpleMode mode,
    String title,
    String? prefillKey,
  ) {
    if (mode == _SimpleMode.drive) return 'fire.driver';
    if (mode == _SimpleMode.skill) {
      return prefillKey ?? ScoredSkillStore.keyForTitle(title);
    }
    return prefillKey;
  }

  static CareerRecordType _recordType(_SimpleMode mode, String title) =>
      switch (mode) {
        _SimpleMode.training => CareerRecordType.training,
        _SimpleMode.call => CareerRecordType.operationalExperience,
        _SimpleMode.skill => CareerRecordType.skill,
        _SimpleMode.exposure => CareerRecordType.operationalExperience,
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
        _SimpleMode.exposure => 'Exposure',
        _SimpleMode.drive => 'Driving',
        _SimpleMode.career => 'Career',
        _SimpleMode.taskBook => 'Task Book Progress',
      };
}

class _CategoryStep extends StatelessWidget {
  final ValueChanged<_SimpleMode> onPick;
  final bool showScanQr;
  final VoidCallback onScanQr;
  final VoidCallback onCustomize;
  final VoidCallback onTrainingResources;
  final List<_SimpleMode> visibleModes;

  const _CategoryStep({
    super.key,
    required this.onPick,
    required this.showScanQr,
    required this.onScanQr,
    required this.onCustomize,
    required this.onTrainingResources,
    required this.visibleModes,
  });

  static const defaultModes = <_SimpleMode>[
    _SimpleMode.training,
    _SimpleMode.call,
    _SimpleMode.skill,
    _SimpleMode.exposure,
    _SimpleMode.drive,
    _SimpleMode.career,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Log something now',
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
          itemCount: visibleModes.length,
          itemBuilder: (context, index) {
            final mode = visibleModes[index];
            return Material(
              color: mode.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(
                onTap: () => onPick(mode),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: mode.color.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: mode.color,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(mode.icon, size: 22, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mode.label,
                        style: TextStyle(
                          color: mode.color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _QuickPickCustomizeButton(onTap: onCustomize),
        const SizedBox(height: 4),
        SizedBox(
          height: 72,
          child: FilledButton.icon(
            key: const Key('quick_add_training_resources'),
            onPressed: onTrainingResources,
            icon: const Icon(Icons.school_rounded, size: 28),
            label: const Text(
              'Training Resources',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (showScanQr) ...[
          OutlinedButton.icon(
            onPressed: onScanQr,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan department class QR'),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _QuickPickCustomizeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickPickCustomizeButton({required this.onTap});

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
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.dashboard_customize_outlined,
                  color: cs.onPrimaryContainer,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Customize Quick Pick Buttons',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose and arrange your colored Quick Add tiles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingLibraryChoice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TrainingLibraryChoice({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 30, color: cs.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  final _SimpleMode mode;
  final VoidCallback onBack;
  final ValueChanged<String> onPick;
  final VoidCallback onMoreDetails;
  final VoidCallback onCustomize;
  final List<QuickLogTracker> customChoices;

  const _ChoiceStep({
    super.key,
    required this.mode,
    required this.onBack,
    required this.onPick,
    required this.onMoreDetails,
    required this.onCustomize,
    required this.customChoices,
  });

  @override
  Widget build(BuildContext context) {
    final choices = <String>[
      ...customChoices.map((item) => item.title),
      ..._choices(mode).where(
        (title) => !customChoices.any(
          (item) => item.title.toLowerCase() == title.toLowerCase(),
        ),
      ),
    ];
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
            onPressed: onCustomize,
            icon: const Icon(Icons.tune),
            label: const Text('Customize these choices'),
          ),
          const SizedBox(height: 4),
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
        _SimpleMode.skill => 'What skill did you perform or practice?',
        _SimpleMode.exposure => 'What possible health or hazard exposure occurred?',
        _SimpleMode.drive => 'Which apparatus?',
        _SimpleMode.career => 'What career activity?',
        _SimpleMode.taskBook => 'What did you do in your Task Book?',
      };
}

class _ConfirmStep extends StatelessWidget {
  final _SimpleMode mode;
  final String choice;
  final bool saving;
  final TextEditingController notes;
  final TextEditingController miles;
  final TextEditingController durationMinutes;
  final TextEditingController repetitions;
  final TextEditingController role;
  final bool emergent;
  final bool transport;
  final _DriveActivity driveActivity;
  final CareerRecordOutcome? skillOutcome;
  final CareerSuccessStats? skillStats;
  final bool shareWithDepartment;
  final int priorityRank;
  final bool departmentConnected;
  final ValueChanged<bool> onEmergentChanged;
  final ValueChanged<bool> onTransportChanged;
  final ValueChanged<_DriveActivity> onDriveActivityChanged;
  final ValueChanged<CareerRecordOutcome?> onSkillOutcomeChanged;
  final ValueChanged<bool> onShareChanged;
  final ValueChanged<int> onPriorityRankChanged;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onMoreDetails;

  const _ConfirmStep({
    super.key,
    required this.mode,
    required this.choice,
    required this.saving,
    required this.notes,
    required this.miles,
    required this.durationMinutes,
    required this.repetitions,
    required this.role,
    required this.emergent,
    required this.transport,
    required this.driveActivity,
    required this.skillOutcome,
    required this.skillStats,
    required this.shareWithDepartment,
    required this.priorityRank,
    required this.departmentConnected,
    required this.onEmergentChanged,
    required this.onTransportChanged,
    required this.onDriveActivityChanged,
    required this.onSkillOutcomeChanged,
    required this.onShareChanged,
    required this.onPriorityRankChanged,
    required this.onBack,
    required this.onSave,
    required this.onMoreDetails,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareFormBody(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                'Quick details',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SummaryCard(mode: mode, choice: choice),
        if (mode == _SimpleMode.skill) ...[
          const SizedBox(height: 10),
          _SkillStatisticCard(choice: choice, stats: skillStats),
        ],
        const SizedBox(height: 14),
        ..._fieldsForMode(context),
        const SizedBox(height: 12),
        TextField(
          controller: notes,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            labelText: 'Notes',
            hintText: mode == _SimpleMode.exposure
                ? 'What happened, PPE used, route of exposure, symptoms, decon, officer notified…'
                : 'Anything worth remembering later…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'How important is this entry?',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Rank it now so you can find your strongest or most important records later.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Not ranked'),
              selected: priorityRank == 0,
              onSelected: (_) => onPriorityRankChanged(0),
            ),
            ...List.generate(5, (index) {
              final rank = index + 1;
              return ChoiceChip(
                avatar: Icon(
                  rank <= priorityRank
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 18,
                ),
                label: Text(rank == 1 ? '1 Low' : rank == 5 ? '5 High' : '$rank'),
                selected: rank == priorityRank,
                onSelected: (_) => onPriorityRankChanged(rank),
              );
            }),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Who can see this?',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Personal only'),
              selected: !shareWithDepartment,
              onSelected: (_) => onShareChanged(false),
            ),
            ChoiceChip(
              label: const Text('Share with department'),
              selected: shareWithDepartment,
              onSelected: departmentConnected ? (_) => onShareChanged(true) : null,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          mode == _SimpleMode.exposure
              ? (shareWithDepartment
                  ? 'Your department can see this personal exposure log as context. It is still not an official exposure report; complete the department’s official documentation with an officer.'
                  : 'This stays in your personal Career Road. It does not replace reporting the exposure to an officer or completing your department’s official exposure documentation.')
              : shareWithDepartment
                  ? 'Your department can see this as member-shared development context. It does not become official training credit or a department evaluation.'
                  : departmentConnected
                      ? 'This stays in your personal Career Road unless you choose to share it.'
                      : 'Personal only. Connect a department from the Department tab to enable sharing.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
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
          label: const Text('Open full log instead'),
        ),
      ],
    );
  }

  List<Widget> _fieldsForMode(BuildContext context) {
    switch (mode) {
      case _SimpleMode.drive:
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: miles,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: const InputDecoration(
                    labelText: 'Miles driven',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: durationMinutes,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: const InputDecoration(
                    labelText: 'Drive time (minutes)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Type', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Response'),
                selected: driveActivity == _DriveActivity.response,
                onSelected: (_) =>
                    onDriveActivityChanged(_DriveActivity.response),
              ),
              ChoiceChip(
                label: const Text('Training'),
                selected: driveActivity == _DriveActivity.training,
                onSelected: (_) =>
                    onDriveActivityChanged(_DriveActivity.training),
              ),
              ChoiceChip(
                label: const Text('Other'),
                selected: driveActivity == _DriveActivity.other,
                onSelected: (_) => onDriveActivityChanged(_DriveActivity.other),
              ),
            ],
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Emergent / lights & siren'),
            value: emergent,
            onChanged: onEmergentChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Patient transport'),
            value: transport,
            onChanged: onTransportChanged,
          ),
        ];
      case _SimpleMode.call:
        return [
          TextField(
            controller: role,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: 'Role / assignment',
              hintText: 'Medic, driver, nozzle, command…',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Emergent response'),
            value: emergent,
            onChanged: onEmergentChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Patient transport'),
            value: transport,
            onChanged: onTransportChanged,
          ),
        ];
      case _SimpleMode.skill:
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: repetitions,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: const InputDecoration(
                    labelText: 'Attempts / reps',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Outcome', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('Successful'),
                selected: skillOutcome == CareerRecordOutcome.successful,
                onSelected: (_) =>
                    onSkillOutcomeChanged(CareerRecordOutcome.successful),
              ),
              ChoiceChip(
                label: const Text('Attempted'),
                selected: skillOutcome == CareerRecordOutcome.attempted,
                onSelected: (_) =>
                    onSkillOutcomeChanged(CareerRecordOutcome.attempted),
              ),
              ChoiceChip(
                label: const Text('Unsuccessful'),
                selected: skillOutcome == CareerRecordOutcome.unsuccessful,
                onSelected: (_) =>
                    onSkillOutcomeChanged(CareerRecordOutcome.unsuccessful),
              ),
            ],
          ),
        ];
      case _SimpleMode.exposure:
        return [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Personal tracking only — this is not an official exposure report. Report and document the incident with an officer using your department’s official exposure/incident process.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: role,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: 'Incident / assignment',
              hintText: 'Structure fire, overhaul, EMS call, HazMat scene…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: durationMinutes,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: 'Approx. exposure time (minutes)',
              border: OutlineInputBorder(),
            ),
          ),
        ];
      case _SimpleMode.training:
        return [
          TextField(
            controller: durationMinutes,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              border: OutlineInputBorder(),
            ),
          ),
        ];
      case _SimpleMode.career:
        return [
          TextField(
            controller: durationMinutes,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: 'Time spent (minutes, optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ];
      case _SimpleMode.taskBook:
        return [
          TextField(
            controller: durationMinutes,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: 'Time spent (minutes, optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ];
    }
  }
}

class _SavedConfirmation extends StatelessWidget {
  const _SavedConfirmation({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final okGreen = Theme.of(context).brightness == Brightness.dark
        ? DarkModeColors.credentialGreen
        : LightModeColors.credentialGreen;

    return Center(
      child: AnimatedScale(
        scale: 1,
        duration: reduceMotion ? Duration.zero : AppMotion.medium,
        curve: AppMotion.standard,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: okGreen.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: okGreen.withValues(alpha: 0.35)),
                ),
                child: Icon(Icons.check_rounded, color: okGreen),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Added to your career record.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillStatisticCard extends StatelessWidget {
  final String choice;
  final CareerSuccessStats? stats;

  const _SkillStatisticCard({required this.choice, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final attempts = stats?.attempts ?? 0;
    final text = attempts == 0
        ? 'Your first result will start a success-rate statistic for $choice.'
        : '$choice success: ${stats!.percent}% • '
            '${stats!.successful} of $attempts attempts';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.query_stats, color: cs.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _SimpleMode mode;
  final String choice;

  const _SummaryCard({required this.mode, required this.choice});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

List<String> _choices(_SimpleMode mode) => switch (mode) {
      _SimpleMode.training => const [
          'Crew drill',
          'Department training',
          'Live fire',
          'Outside class',
          'College / Fire Science class',
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
          'IV / vascular access',
          'Airway management',
          'Patient assessment',
          'Pump operations',
          'Ground ladders',
          'Hose advancement',
          'Search and rescue',
          'Other skill',
        ],
      _SimpleMode.exposure => const [
          'Smoke / combustion products',
          'HazMat / chemical',
          'Blood / body fluids',
          'Infectious disease',
          'Diesel exhaust',
          'Carcinogen / soot',
          'Needlestick / sharps',
          'Unknown substance',
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
