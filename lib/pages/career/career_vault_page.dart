import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/career_stats.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/state/app_state.dart';

enum _FirstRecordChoice { training, certification, experience, accomplishment }

class CareerVaultPage extends StatefulWidget {
  final EvidencePrefill? prefill;
  final bool openEditorOnLoad;
  final bool showFirstRecordPicker;
  final ResponderRoadmapApi? api;
  const CareerVaultPage({
    super.key,
    this.prefill,
    this.openEditorOnLoad = false,
    this.showFirstRecordPicker = false,
    this.api,
  });

  @override
  State<CareerVaultPage> createState() => _CareerVaultPageState();
}

class _CareerVaultPageState extends State<CareerVaultPage> {
  final CareerRecordStore _store = CareerRecordStore();

  List<CareerRecord> _records = <CareerRecord>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _store.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });

    final prefill = widget.prefill;
    if ((prefill != null || widget.openEditorOnLoad) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (prefill != null) {
          _openEditor(
            initialType: CareerRecordType.taskBookEvidence,
            initialTitle: prefill.title,
            initialCategory: prefill.category,
            initialRelatedGoalId: prefill.relatedGoalId,
            initialRelatedRequirementId: prefill.relatedRequirementId,
            initialTags: prefill.tags,
          );
        } else {
          if (widget.showFirstRecordPicker) {
            _showFirstRecordPicker();
          } else {
            _openEditor();
          }
        }
      });
    }
  }

  Future<void> _showFirstRecordPicker() async {
    final choice = await showModalBottomSheet<_FirstRecordChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        final textTheme = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'What would you like to add?',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose one to get a form started. You can add details later.',
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                _FirstRecordOption(
                  icon: Icons.school_outlined,
                  title: 'Training or class',
                  detail: 'Course, drill, CE, or skill practice',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _FirstRecordChoice.training,
                  ),
                ),
                _FirstRecordOption(
                  icon: Icons.verified_outlined,
                  title: 'Certification or qualification',
                  detail: 'EMT, paramedic, fire, or other credential',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _FirstRecordChoice.certification,
                  ),
                ),
                _FirstRecordOption(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Experience or assignment',
                  detail: 'Response experience, ride time, or acting role',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _FirstRecordChoice.experience,
                  ),
                ),
                _FirstRecordOption(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Accomplishment or leadership',
                  detail: 'Award, mentoring, project, or milestone',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _FirstRecordChoice.accomplishment,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;

    switch (choice) {
      case _FirstRecordChoice.training:
        await _openEditor(initialType: CareerRecordType.training);
        return;
      case _FirstRecordChoice.certification:
        await context.push(AppRoutes.certificationAdd);
        return;
      case _FirstRecordChoice.experience:
        await _openEditor(initialType: CareerRecordType.operationalExperience);
        return;
      case _FirstRecordChoice.accomplishment:
        await _openEditor(initialType: CareerRecordType.achievement);
        return;
    }
  }

  Future<void> _saveRecord(CareerRecord record) async {
    final next = [..._records];
    final index = next.indexWhere((e) => e.id == record.id);
    if (index >= 0) {
      next[index] = record;
    } else {
      next.add(record);
    }
    next.sort((a, b) => b.date.compareTo(a.date));
    await _store.save(next);
    if (!mounted) return;
    setState(() => _records = next);
  }

  bool _isAdvancementRecord(CareerRecord record) =>
      record.type == CareerRecordType.achievement ||
      record.type == CareerRecordType.leadership ||
      record.type == CareerRecordType.teaching ||
      record.type == CareerRecordType.project ||
      record.type == CareerRecordType.education ||
      record.type == CareerRecordType.taskBookEvidence;

  List<_GrowthYear> _growthYears(AppState app) {
    final byYear = <int, _GrowthYear>{};
    for (final record in _records.where(_isAdvancementRecord)) {
      (byYear[record.date.year] ??= _GrowthYear(record.date.year))
          .records
          .add(record);
    }
    for (final certification in app.certifications) {
      final date = certification.issueDate ?? certification.createdAt;
      (byYear[date.year] ??= _GrowthYear(date.year))
          .certifications
          .add(certification);
    }
    final years = byYear.values.toList()
      ..sort((a, b) => b.year.compareTo(a.year));
    return years;
  }

  List<_GrowthCategorySummary> _growthCategorySummaries(AppState app) {
    final stats = CareerStats.fromRecords(_records);
    final leadership = _records
        .where((record) => record.type == CareerRecordType.leadership)
        .toList();
    final teaching = _records
        .where((record) => record.type == CareerRecordType.teaching)
        .toList();
    final milestones = _records
        .where((record) =>
            record.type == CareerRecordType.achievement ||
            record.type == CareerRecordType.project)
        .toList();
    final taskBookEvidence = _records
        .where((record) => record.type == CareerRecordType.taskBookEvidence)
        .toList();

    String yearsLabel(Iterable<int> years) {
      final count = years.toSet().length;
      return count == 0
          ? 'No years documented yet'
          : 'Across $count documented year${count == 1 ? '' : 's'}';
    }

    String recordsLabel(List<CareerRecord> records) =>
        '${records.length} record${records.length == 1 ? '' : 's'}';

    return [
      _GrowthCategorySummary(
        title: 'Leadership',
        icon: Icons.groups_outlined,
        value: '${stats.leadershipCount}',
        detail: '${recordsLabel(leadership)} · ${yearsLabel(leadership.map((e) => e.date.year))}',
      ),
      _GrowthCategorySummary(
        title: 'Teaching',
        icon: Icons.record_voice_over_outlined,
        value: stats.teachingHours > 0
            ? stats.teachingLabel
            : '${teaching.length}',
        detail: stats.teachingHours > 0
            ? '${recordsLabel(teaching)} · hours taught'
            : 'Teaching and mentoring records',
      ),
      _GrowthCategorySummary(
        title: 'Credentials',
        icon: Icons.verified_outlined,
        value: '${app.certifications.length}',
        detail: yearsLabel(app.certifications.map(
          (certification) =>
              (certification.issueDate ?? certification.createdAt).year,
        )),
      ),
      _GrowthCategorySummary(
        title: 'Achievements',
        icon: Icons.emoji_events_outlined,
        value: '${stats.achievements + stats.projects}',
        detail: '${recordsLabel(milestones)} · ${yearsLabel(milestones.map((e) => e.date.year))}',
      ),
      _GrowthCategorySummary(
        title: 'Task book evidence',
        icon: Icons.fact_check_outlined,
        value: '${stats.taskBookUpdates}',
        detail: '${recordsLabel(taskBookEvidence)} · ${yearsLabel(taskBookEvidence.map((e) => e.date.year))}',
      ),
    ];
  }

  String _growthFocus(_GrowthYear year) {
    final types = <CareerRecordType, int>{};
    for (final record in year.records) {
      types[record.type] = (types[record.type] ?? 0) + 1;
    }
    if (year.certifications.isNotEmpty) return 'Building qualifications';
    if ((types[CareerRecordType.leadership] ?? 0) > 0 ||
        (types[CareerRecordType.teaching] ?? 0) > 0 ||
        (types[CareerRecordType.project] ?? 0) > 0) {
      return 'Growing leadership and influence';
    }
    if ((types[CareerRecordType.achievement] ?? 0) > 0) {
      return 'Reaching career milestones';
    }
    if ((types[CareerRecordType.education] ?? 0) > 0) {
      return 'Building professional qualifications';
    }
    return 'Advancing your career plan';
  }

  Widget _growthYearCard(AppState app, _GrowthYear year) {
    final stats = CareerStats.fromRecords(year.records);
    final highlights = year.records.where((record) => record.highlight).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final credentials = year.certifications.toList()
      ..sort((a, b) => (b.issueDate ?? b.createdAt)
          .compareTo(a.issueDate ?? a.createdAt));
    final cs = Theme.of(context).colorScheme;
    final hasDetails =
        year.records.isNotEmpty || year.certifications.isNotEmpty;
    final facts = <String>[
      if (year.records.isNotEmpty)
        '${year.records.length} record${year.records.length == 1 ? '' : 's'}',
      if (year.certifications.isNotEmpty)
        '${year.certifications.length} credential${year.certifications.length == 1 ? '' : 's'}',
      if (stats.leadershipCount + stats.projects + stats.teachingHours > 0)
        'Leadership and service documented',
    ];

    final isCurrentYear = year.year == DateTime.now().year;
    return Card(
      color: isCurrentYear
          ? const Color(0xFFEAF2FF)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isCurrentYear
              ? const Color(0xFF2563EB).withValues(alpha: 0.35)
              : cs.outline.withValues(alpha: 0.10),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${year.year}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _growthFocus(year),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        facts.isEmpty
                            ? 'No career entries recorded for this year yet.'
                            : facts.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (highlights.isNotEmpty || credentials.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              ...highlights.take(3).map(
                    (record) => _GrowthMilestone(
                      icon: Icons.star_rounded,
                      title: record.title,
                      detail: record.impact?.trim().isNotEmpty == true
                          ? record.impact!.trim()
                          : record.summary?.trim().isNotEmpty == true
                              ? record.summary!.trim()
                              : record.type.label,
                    ),
                  ),
              ...credentials.take(2).map(
                    (certification) => _GrowthMilestone(
                      icon: Icons.verified_outlined,
                      title: app.certificationDisplayName(certification),
                      detail: 'Credential added',
                    ),
                  ),
            ],
            if (hasDetails) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.go(AppRoutes.training),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('View full records'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor({
    CareerRecord? existing,
    CareerRecordType? initialType,
    String? initialTitle,
    String? initialCategory,
    String? initialRelatedGoalId,
    String? initialRelatedRequirementId,
    List<String>? initialTags,
  }) async {
    final app = context.read<AppState>();
    final roadmap = app.roadmap;
    final requirementNames = <String, String>{};
    if (roadmap != null) {
      for (final item in roadmap.included) {
        requirementNames[item.requirement.id] = item.requirement.name;
      }
    }

    final now = DateTime.now();
    var type = existing?.type ?? initialType ?? CareerRecordType.skill;
    var selectedDate = existing?.date ?? now;
    var selectedRequirementId =
        existing?.relatedRequirementId ?? (initialRelatedRequirementId ?? '');
    var highlight = existing?.highlight ?? false;
    var showAdvanced = existing != null;

    final title = TextEditingController(
      text: existing?.title ?? (initialTitle ?? ''),
    );
    final category = TextEditingController(
      text: existing?.category ?? (initialCategory ?? ''),
    );
    final role = TextEditingController(text: existing?.roleOrAssignment ?? '');
    final summary = TextEditingController(text: existing?.summary ?? '');
    final impact = TextEditingController(text: existing?.impact ?? '');
    final evidence = TextEditingController(
      text: existing?.evidenceReference ?? '',
    );
    final hours = TextEditingController(
      text: existing?.hours == null ? '' : _trimNumber(existing!.hours!),
    );
    final repetitions = TextEditingController(
      text: existing == null ? '1' : existing.repetitions.toString(),
    );
    final tags = TextEditingController(
      text: existing?.tags.join(', ') ?? (initialTags?.join(', ') ?? ''),
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<CareerRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(
              existing == null ? _editorTitleFor(type) : 'Edit career record',
            ),
            content: SizedBox(
              width: 620,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _editorGuidanceFor(type),
                        style: Theme.of(dialogContext).textTheme.bodySmall
                            ?.copyWith(
                              color: Theme.of(
                                dialogContext,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<CareerRecordType>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Record type',
                        ),
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
                        key: const ValueKey('career_record_title'),
                        controller: title,
                        autofocus: existing == null,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText:
                              'Led first-due company drill, completed FO1 module, received award…',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Add a short title.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: category,
                              decoration: const InputDecoration(
                                labelText: 'Category (optional)',
                                hintText: 'Leadership, pumps, EMS, hazmat…',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(1970),
                                  lastDate: DateTime(now.year + 10),
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedDate = picked);
                                }
                              },
                              icon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                              label: Text(_formatDate(selectedDate)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: summary,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          hintText:
                              'Write the context and your actions so you can recall the example later.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => setDialogState(
                          () => showAdvanced = !showAdvanced,
                        ),
                        icon: Icon(showAdvanced
                            ? Icons.expand_less : Icons.expand_more),
                        label: Text(showAdvanced
                            ? 'Hide additional details'
                            : 'Add hours, evidence, and more details'),
                      ),
                      if (showAdvanced) ...[
                      TextFormField(
                        controller: role,
                        decoration: const InputDecoration(
                          labelText: 'Your role / assignment',
                          hintText:
                              'Acting officer, nozzle firefighter, instructor, project lead…',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: impact,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Result / impact',
                          hintText:
                              'What improved, what you learned, who benefited, or what changed?',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: hours,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Hours (optional)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: repetitions,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Repetitions / count',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (requirementNames.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue:
                              requirementNames.containsKey(
                                selectedRequirementId,
                              )
                              ? selectedRequirementId
                              : '',
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText:
                                'Supports roadmap requirement (optional)',
                            helperText: app.selectedGoal == null
                                ? null
                                : 'Current target: ${app.selectedGoal!.title}',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Not linked to a requirement'),
                            ),
                            ...requirementNames.entries.map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) => setDialogState(
                            () => selectedRequirementId = value ?? '',
                          ),
                        ),
                      if (requirementNames.isNotEmpty)
                        const SizedBox(height: 12),
                      TextFormField(
                        controller: evidence,
                        decoration: const InputDecoration(
                          labelText: 'Evidence reference (optional)',
                          hintText:
                              'Training record, evaluation, award letter, task-book page, email…',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tags,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          hintText: 'FO1, interview, leadership, engineer',
                          helperText: 'Separate tags with commas.',
                        ),
                      ),
                      const SizedBox(height: 6),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: highlight,
                        onChanged: (value) =>
                            setDialogState(() => highlight = value ?? false),
                        title: const Text('Use as a career highlight'),
                        subtitle: const Text(
                          'Prioritize this record in promotion, resume, and interview summaries.',
                        ),
                      ),

                      ],
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
                  final parsedHours = double.tryParse(hours.text.trim());
                  final parsedReps = int.tryParse(repetitions.text.trim());
                  final cleanTags = tags.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toSet()
                      .toList();
                  final savedAt = DateTime.now();
                  Navigator.pop(
                    dialogContext,
                    CareerRecord(
                      id:
                          existing?.id ??
                          savedAt.microsecondsSinceEpoch.toRadixString(36),
                      type: type,
                      title: title.text.trim(),
                      category: category.text.trim(),
                      date: selectedDate,
                      roleOrAssignment: _nullable(role.text),
                      summary: _nullable(summary.text),
                      impact: _nullable(impact.text),
                      evidenceReference: _nullable(evidence.text),
                      hours: parsedHours != null && parsedHours >= 0
                          ? parsedHours
                          : null,
                      repetitions: parsedReps != null && parsedReps > 0
                          ? parsedReps
                          : 1,
                      tags: cleanTags,
                      relatedGoalId: selectedRequirementId.isEmpty
                          ? (existing?.relatedGoalId ??
                                initialRelatedGoalId ??
                                app.selectedGoal?.id)
                          : (existing?.relatedGoalId ??
                                initialRelatedGoalId ??
                                app.selectedGoal?.id),
                      relatedRequirementId: selectedRequirementId.isEmpty
                          ? (existing?.relatedRequirementId ??
                                initialRelatedRequirementId)
                          : selectedRequirementId,
                      highlight: highlight,
                      createdAt: existing?.createdAt ?? savedAt,
                      updatedAt: savedAt,
                    ),
                  );
                },
                child: Text(existing == null ? 'Save record' : 'Save changes'),
              ),
            ],
          );
        },
      ),
    );

    // Persist before cleanup, then leave the controllers alive through the
    // dialog's reverse transition so its form fields are not listening to
    // disposed controllers while the route animates out.
    if (result != null) await _saveRecord(result);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    title.dispose();
    category.dispose();
    role.dispose();
    summary.dispose();
    impact.dispose();
    evidence.dispose();
    hours.dispose();
    repetitions.dispose();
    tags.dispose();

  }

  Future<void> _showCareerBrief(AppState app) async {
    final brief = _buildCareerBrief(app);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Career advancement brief'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: SelectableText(
              brief,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: brief));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Career brief copied.')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy brief'),
          ),
        ],
      ),
    );
  }

  String _buildCareerBrief(AppState app) {
    final roadmap = app.roadmap;
    final goal = app.selectedGoal;
    final requirementNames = <String, String>{};
    if (roadmap != null) {
      for (final item in roadmap.included) {
        requirementNames[item.requirement.id] = item.requirement.name;
      }
    }

    final currentCerts = app.certifications
        .where((c) => c.status != CertificationStatus.expired)
        .toList();
    final highlights = _records.where((e) => e.highlight).take(12).toList();
    final leadership = _records
        .where(
          (e) =>
              e.type == CareerRecordType.leadership ||
              e.type == CareerRecordType.project ||
              e.type == CareerRecordType.teaching,
        )
        .take(10)
        .toList();
    final linked = goal == null
        ? <CareerRecord>[]
        : _records
              .where(
                (e) =>
                    e.relatedGoalId == goal.id ||
                    requirementNames.containsKey(e.relatedRequirementId),
              )
              .toList();
    final trainingHours = _records
        .where(
          (e) =>
              e.type == CareerRecordType.training ||
              e.type == CareerRecordType.education ||
              e.type == CareerRecordType.teaching,
        )
        .fold<double>(0, (sum, e) => sum + (e.hours ?? 0));

    final skillCounts = <String, int>{};
    for (final record in _records.where(
      (e) => e.type == CareerRecordType.skill,
    )) {
      final key = record.category.trim().isEmpty
          ? record.title
          : record.category.trim();
      skillCounts[key] = (skillCounts[key] ?? 0) + record.repetitions;
    }
    final topSkills = skillCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    buffer.writeln('PROFESSIONAL GROWTH & ADVANCEMENT BRIEF');
    buffer.writeln('Generated ${_formatDate(DateTime.now())}');
    if (goal != null) buffer.writeln('Target role: ${goal.title}');
    if (roadmap != null) {
      buffer.writeln(
        'Task Book progress: ${roadmap.completedCount}/${roadmap.totalCount} requirements complete',
      );
    }
    buffer.writeln('Career evidence records: ${_records.length}');
    buffer.writeln(
      'Documented training/education hours: ${_trimNumber(trainingHours)}',
    );
    buffer.writeln();

    buffer.writeln('CURRENT CREDENTIALS');
    if (currentCerts.isEmpty) {
      buffer.writeln('- No current credentials recorded.');
    } else {
      for (final cert in currentCerts.take(20)) {
        final expires = cert.doesNotExpire || cert.expirationDate == null
            ? 'no expiration recorded'
            : 'expires ${_formatDate(cert.expirationDate!)}';
        buffer.writeln('- ${app.certificationDisplayName(cert)} — $expires');
      }
    }
    buffer.writeln();

    buffer.writeln('CAREER HIGHLIGHTS');
    if (highlights.isEmpty) {
      buffer.writeln(
        '- Mark strong records as Career Highlights to build this section.',
      );
    } else {
      for (final record in highlights) {
        buffer.writeln(
          '- ${_formatDate(record.date)} | ${record.title}${_briefDetail(record)}',
        );
      }
    }
    buffer.writeln();

    buffer.writeln('LEADERSHIP / TEACHING / PROJECT EVIDENCE');
    if (leadership.isEmpty) {
      buffer.writeln(
        '- No leadership, teaching, mentoring, or project records yet.',
      );
    } else {
      for (final record in leadership) {
        buffer.writeln(
          '- ${_formatDate(record.date)} | ${record.title}${_briefDetail(record)}',
        );
      }
    }
    buffer.writeln();

    buffer.writeln('MOST PRACTICED SKILLS');
    if (topSkills.isEmpty) {
      buffer.writeln('- No skill repetitions recorded yet.');
    } else {
      for (final entry in topSkills.take(10)) {
        buffer.writeln(
          '- ${entry.key}: ${entry.value} documented repetition${entry.value == 1 ? '' : 's'}',
        );
      }
    }

    if (goal != null) {
      buffer.writeln();
      buffer.writeln('EVIDENCE SUPPORTING ${goal.title.toUpperCase()}');
      if (linked.isEmpty) {
        buffer.writeln('- No career records linked to this roadmap yet.');
      } else {
        for (final record in linked.take(20)) {
          final req = record.relatedRequirementId == null
              ? null
              : requirementNames[record.relatedRequirementId!];
          buffer.writeln(
            '- ${req == null ? record.title : '$req — ${record.title}'}${_briefDetail(record)}',
          );
        }
      }
    }

    buffer.writeln();
    buffer.writeln(
      'Use this as a memory aid for promotion preparation, resumes, performance reviews, and interviews. Verify dates and details against official records when required.',
    );
    return buffer.toString().trim();
  }

  String _briefDetail(CareerRecord record) {
    final parts = <String>[];
    if ((record.roleOrAssignment ?? '').trim().isNotEmpty) {
      parts.add(record.roleOrAssignment!.trim());
    }
    if ((record.impact ?? '').trim().isNotEmpty) {
      parts.add(record.impact!.trim());
    }
    if ((record.evidenceReference ?? '').trim().isNotEmpty) {
      parts.add('Evidence: ${record.evidenceReference!.trim()}');
    }
    return parts.isEmpty ? '' : ' — ${parts.join(' | ')}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final roadmap = app.roadmap;
    final goal = app.selectedGoal;
    final growthYears = _growthYears(app);
    final growthCategories = _growthCategorySummaries(app);
    final activeYears = growthYears.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        surfaceTintColor: Colors.transparent,
        leading: const AppBackButton.toAdvance(),
        title: const Text(
          'Roadmap',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Career Goals',
            onPressed: () => context.go(AppRoutes.careerGoals),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF071A33), Color(0xFF164E7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.trending_up_rounded, size: 28, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          'Advance your career',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Build your qualifications, prepare stronger applications, and turn years of experience into your next opportunity.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _GrowthMetric(
                              value: '$activeYears',
                              label: activeYears == 1 ? 'year documented' : 'years documented',
                            ),
                            _GrowthMetric(
                              value: roadmap == null
                                  ? '—'
                                  : '${roadmap.completedCount}/${roadmap.totalCount}',
                              label: 'roadmap steps',
                            ),
                            _GrowthMetric(
                              value: '${app.certifications.length}',
                              label: 'credentials',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionTitle(
                  title: 'Career advancement',
                  subtitle:
                      'Choose the next move, prepare for it, and keep every application organized.',
                ),
                const SizedBox(height: 10),
                Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.applicationCenter),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF312E81), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.rocket_launch_outlined, color: Colors.white),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Application Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                                SizedBox(height: 4),
                                Text('Reusable profile, document readiness, references, and hiring progress', style: TextStyle(color: Colors.white70, height: 1.35)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push(AppRoutes.jobHistory),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(0xFFE0E7FF),
                                  child: Icon(
                                    Icons.work_history_outlined,
                                    color: Color(0xFF3730A3),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Job history',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Roles and service dates',
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push(AppRoutes.jobSearch),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(0xFFDCFCE7),
                                  child: Icon(
                                    Icons.travel_explore_rounded,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Job search',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Find fire and EMS openings',
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  color: const Color(0xFFEAF1FC),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag_rounded, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                goal == null
                                    ? 'Choose a career goal'
                                    : goal.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          roadmap == null
                              ? 'Set a destination for your professional growth. Your timeline will show the experience and milestones you build along the way.'
                              : '${roadmap.completedCount} of ${roadmap.totalCount} roadmap steps complete. Your career records capture the experience and milestones behind your progress.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                        if (roadmap != null && roadmap.totalCount > 0) ...[
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            minHeight: 8,
                            value: roadmap.percentComplete,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${roadmap.completedCount} of ${roadmap.totalCount} steps complete',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => context.go(AppRoutes.careerGoals),
                            icon: Icon(goal == null ? Icons.flag_outlined : Icons.edit_outlined),
                            label: Text(goal == null ? 'Set my goal' : 'Update my goal'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionTitle(
                  title: 'Career-building areas',
                  subtitle:
                      'Focus on leadership, credentials, achievements, teaching, and evidence that support advancement.',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 156,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: growthCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => SizedBox(
                      width: 184,
                      child: _GrowthCategoryCard(
                        category: growthCategories[index],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionTitle(
                  title: 'Advancement milestones',
                  subtitle:
                      'A high-level view of qualifications and career-building milestones. Skills, calls, and individual training entries stay in Records.',
                ),
                const SizedBox(height: 10),
                if (growthYears.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          const Icon(Icons.timeline_rounded, size: 36),
                          const SizedBox(height: 10),
                          Text(
                            'Your advancement story starts with a milestone',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose a career goal, add qualifications, and mark important leadership, education, project, or achievement milestones.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...growthYears.map((year) => _growthYearCard(app, year)),
                const SizedBox(height: 4),
                Card(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('Need a specific detail?'),
                    subtitle: const Text(
                      'Records contains the complete searchable timeline for everything entered through Quick Add, including skills and training.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(AppRoutes.training),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showCareerBrief(app),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Create career brief'),
                ),
              ],
            ),
    );
  }

}

class _GrowthYear {
  final int year;
  final List<CareerRecord> records = [];
  final List<Certification> certifications = [];

  _GrowthYear(this.year);
}

class _GrowthCategorySummary {
  final String title;
  final IconData icon;
  final String value;
  final String detail;

  const _GrowthCategorySummary({
    required this.title,
    required this.icon,
    required this.value,
    required this.detail,
  });
}

class _GrowthCategoryCard extends StatelessWidget {
  final _GrowthCategorySummary category;

  const _GrowthCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(category.icon, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              category.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              category.detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.25,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthMetric extends StatelessWidget {
  final String value;
  final String label;

  const _GrowthMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _GrowthMilestone extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _GrowthMilestone({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FirstRecordOption extends StatelessWidget {
  const _FirstRecordOption({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

String _editorTitleFor(CareerRecordType type) => switch (type) {
  CareerRecordType.operationalExperience => 'Add experience record',
  CareerRecordType.skill => 'Add skill or competency',
  CareerRecordType.training => 'Add training or class',
  CareerRecordType.achievement => 'Add accomplishment',
  CareerRecordType.leadership => 'Add leadership record',
  CareerRecordType.teaching => 'Add teaching or mentoring record',
  CareerRecordType.project => 'Add project record',
  CareerRecordType.education => 'Add education record',
  CareerRecordType.taskBookEvidence => 'Add task book evidence',
};

String _editorGuidanceFor(CareerRecordType type) => switch (type) {
  CareerRecordType.operationalExperience =>
    'Describe the call, ride time, or assignment. Do not include patient names, addresses, dates of birth, or other identifying information.',
  CareerRecordType.skill =>
    'Capture a skill or competency you practiced or demonstrated. Add the date and useful context.',
  CareerRecordType.training =>
    'Record a class, drill, course, or continuing education. Add hours and a document reference when you have them.',
  CareerRecordType.achievement =>
    'Describe the accomplishment, award, or milestone and why it mattered.',
  CareerRecordType.leadership =>
    'Capture a leadership role, acting assignment, or responsibility and what you accomplished.',
  CareerRecordType.teaching =>
    'Record instruction, mentoring, or evaluation work and who it supported without adding private details.',
  CareerRecordType.project =>
    'Describe the project or committee work, your role, and the result.',
  CareerRecordType.education =>
    'Record a degree, course of study, or other formal education.',
  CareerRecordType.taskBookEvidence =>
    'Add the performance evidence for this task book item. Avoid patient identifying information.',
};

String _formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _trimNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
