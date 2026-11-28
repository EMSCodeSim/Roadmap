import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    final milestones = _records
        .where((record) =>
            record.type == CareerRecordType.achievement ||
            record.type == CareerRecordType.project)
        .toList();
    final experience = _records
        .where((record) =>
            record.type == CareerRecordType.operationalExperience)
        .toList();
    final education = _records
        .where((record) =>
            record.type == CareerRecordType.training ||
            record.type == CareerRecordType.education ||
            record.type == CareerRecordType.teaching)
        .toList();

    return [
      _GrowthCategorySummary(
        title: 'Qualifications',
        icon: Icons.workspace_premium_outlined,
        value: '${app.certifications.length}',
        detail: 'Credentials and roadmap requirements',
      ),
      _GrowthCategorySummary(
        title: 'Leadership',
        icon: Icons.groups_outlined,
        value: '${stats.leadershipCount}',
        detail: '${leadership.length} leadership records',
      ),
      _GrowthCategorySummary(
        title: 'Training & Education',
        icon: Icons.school_outlined,
        value: '${education.length}',
        detail: 'Courses, teaching, and education',
      ),
      _GrowthCategorySummary(
        title: 'Experience',
        icon: Icons.local_fire_department_outlined,
        value: '${experience.length}',
        detail: 'Calls, assignments, and service',
      ),
      _GrowthCategorySummary(
        title: 'Promotion Prep',
        icon: Icons.trending_up_rounded,
        value: '${stats.achievements + stats.projects}',
        detail: '${milestones.length} stories and milestones',
      ),
      _GrowthCategorySummary(
        title: 'Specialty Paths',
        icon: Icons.route_outlined,
        value: app.selectedGoal == null ? 'Explore' : 'View',
        detail: 'Career goals and specialty options',
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

  Widget _careerOpportunityTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          title: 'Career opportunities',
          subtitle: 'Find opportunities and keep application materials organized.',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.jobSearch),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Job Search'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.applicationCenter),
                icon: const Icon(Icons.description_outlined),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Application Center'),
                ),
              ),
            ),
          ],
        ),
      ],
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
                                  maxLines: 3,
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
    final nextStep = roadmap?.nextStep;

    void openDevelopment(int index) {
      switch (index) {
        case 0:
          context.push(AppRoutes.certifications);
        case 1:
          context.push(AppRoutes.growthDetails);
        case 2:
        case 3:
          context.go(AppRoutes.training);
        case 4:
          context.push(AppRoutes.promotionPortfolioReview);
        case 5:
          context.push(AppRoutes.goalSetup);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roadmap', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            Text('Career Development', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export career record',
            onPressed: () => context.push(AppRoutes.careerExport),
            icon: const Icon(Icons.ios_share_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'More roadmap tools',
            onSelected: (value) {
              switch (value) {
                case 'completed':
                  context.go(AppRoutes.careerGoals);
                case 'customize':
                  context.push(AppRoutes.taskBookRequirementsSetup);
                case 'review':
                  context.push(AppRoutes.promotionPortfolioReview);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'completed', child: Text('Completed milestones')),
              PopupMenuItem(value: 'customize', child: Text('Customize my roadmap')),
              PopupMenuItem(value: 'review', child: Text('Promotion review')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  color: const Color(0xFFF5F1FF),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current career goal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 27,
                              backgroundColor: Color(0xFFE9DFFF),
                              child: Icon(Icons.flag_rounded, color: Color(0xFF7138F4), size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(goal?.title ?? 'Choose a career goal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 3),
                                  Text(
                                    roadmap == null ? 'No roadmap created yet' : '${roadmap.completedCount} of ${roadmap.totalCount} milestones complete',
                                    style: TextStyle(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (roadmap != null && roadmap.totalCount > 0) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            minHeight: 7,
                            value: roadmap.percentComplete,
                            color: const Color(0xFF7138F4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton(onPressed: () => context.push(AppRoutes.goalSetup), child: Text(goal == null ? 'Set goal' : 'Change goal'))),
                            const SizedBox(width: 8),
                            Expanded(child: FilledButton(onPressed: () => context.go(AppRoutes.careerGoals), child: const Text('View plan'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionTitle(
                  title: 'Next best step',
                  subtitle: 'One recommendation based on your selected career goal.',
                ),
                const SizedBox(height: 10),
                Card(
                  margin: EdgeInsets.zero,
                  color: const Color(0xFFF5F1FF),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE7EAFE),
                          child: Icon(Icons.auto_awesome_rounded, color: Color(0xFF2454DF)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nextStep?.requirement.name ?? 'Your roadmap is caught up', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(nextStep == null ? 'Review your plan or document new career evidence.' : 'Open the remaining requirement and skills checklist.', style: TextStyle(color: cs.onSurfaceVariant)),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    if (nextStep == null || roadmap == null) {
                                      context.go(AppRoutes.careerGoals);
                                    } else {
                                      AppRouter.openRequirement(context, nextStep.requirement, goalId: roadmap.goal.id);
                                    }
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(nextStep == null ? 'View plan' : 'Open checklist'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionTitle(
                  title: 'My development',
                  subtitle: 'Open a focused view of the part of your career you want to develop.',
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final scaledBody = MediaQuery.textScalerOf(context).scale(16);
                    final useSingleColumn = constraints.maxWidth < 340 || scaledBody > 20;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: growthCategories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: useSingleColumn ? 1 : 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: useSingleColumn ? 3.15 : 1.75,
                      ),
                      itemBuilder: (context, index) => _GrowthCategoryCard(
                        category: growthCategories[index],
                        onTap: () => openDevelopment(index),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _careerOpportunityTools(),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: const Text('More roadmap tools', style: TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: const Text('Completed milestones • Customize • Promotion review'),
                  children: [
                    ListTile(leading: const Icon(Icons.check_circle_outline_rounded), title: const Text('Completed milestones'), onTap: () => context.go(AppRoutes.careerGoals)),
                    ListTile(leading: const Icon(Icons.tune_rounded), title: const Text('Customize my roadmap'), onTap: () => context.push(AppRoutes.taskBookRequirementsSetup)),
                    ListTile(leading: const Icon(Icons.fact_check_outlined), title: const Text('Promotion review'), onTap: () => context.push(AppRoutes.promotionPortfolioReview)),
                    ListTile(leading: const Icon(Icons.description_outlined), title: const Text('Create career brief'), onTap: () => _showCareerBrief(app)),
                    if (growthYears.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Completed milestones', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      ...growthYears.map((year) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _growthYearCard(app, year),
                          )),
                    ],
                  ],
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
  final VoidCallback onTap;

  const _GrowthCategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: category.detail,
      child: Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(category.icon, size: 20, color: cs.primary),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  category.title,
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                category.value,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
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
