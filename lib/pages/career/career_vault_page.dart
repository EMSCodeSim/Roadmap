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
import 'package:firepath/state/app_state.dart';

class CareerVaultPage extends StatefulWidget {
  final EvidencePrefill? prefill;
  const CareerVaultPage({super.key, this.prefill});

  @override
  State<CareerVaultPage> createState() => _CareerVaultPageState();
}

class _CareerVaultPageState extends State<CareerVaultPage> {
  final CareerRecordStore _store = CareerRecordStore();
  final TextEditingController _searchController = TextEditingController();

  List<CareerRecord> _records = <CareerRecord>[];
  CareerRecordType? _filter;
  bool _loading = true;

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
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });

    final prefill = widget.prefill;
    if (prefill != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openEditor(
          initialType: CareerRecordType.taskBookEvidence,
          initialTitle: prefill.title,
          initialCategory: prefill.category,
          initialRelatedGoalId: prefill.relatedGoalId,
          initialRelatedRequirementId: prefill.relatedRequirementId,
          initialTags: prefill.tags,
        );
      });
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

  Future<void> _deleteRecord(CareerRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete career record?'),
        content: Text(
          '“${record.title}” will be removed from your personal career history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final next = _records.where((e) => e.id != record.id).toList();
    await _store.save(next);
    if (!mounted) return;
    setState(() => _records = next);
  }

  List<CareerRecord> get _filteredRecords {
    final q = _searchController.text.trim().toLowerCase();
    return _records.where((record) {
      if (_filter != null && record.type != _filter) return false;
      if (q.isEmpty) return true;
      final haystack = <String>[
        record.title,
        record.category,
        record.type.label,
        record.roleOrAssignment ?? '',
        record.summary ?? '',
        record.impact ?? '',
        record.evidenceReference ?? '',
        ...record.tags,
        record.date.year.toString(),
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
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
              existing == null ? 'Add career evidence' : 'Edit career evidence',
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
                        'Capture enough context that this still makes sense years from now. Avoid patient names, addresses, DOBs, or other identifying information.',
                        style: Theme.of(dialogContext).textTheme.bodySmall
                            ?.copyWith(
                              color: Theme.of(
                                dialogContext,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<CareerRecordType>(
                        value: type,
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
                        controller: title,
                        autofocus: existing == null,
                        decoration: const InputDecoration(
                          labelText: 'What did you do?',
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
                                labelText: 'Category / skill area',
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
                        ],
                      ),
                      const SizedBox(height: 12),
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
                        controller: summary,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'What happened / what you did',
                          hintText:
                              'Write the context and your actions so you can recall the example later.',
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
                          value:
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

    title.dispose();
    category.dispose();
    role.dispose();
    summary.dispose();
    impact.dispose();
    evidence.dispose();
    hours.dispose();
    repetitions.dispose();
    tags.dispose();

    if (result != null) await _saveRecord(result);
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
    if (roadmap != null)
      buffer.writeln(
        'Task Book progress: ${roadmap.completedCount}/${roadmap.totalCount} requirements complete',
      );
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
    if ((record.roleOrAssignment ?? '').trim().isNotEmpty)
      parts.add(record.roleOrAssignment!.trim());
    if ((record.impact ?? '').trim().isNotEmpty)
      parts.add(record.impact!.trim());
    if ((record.evidenceReference ?? '').trim().isNotEmpty)
      parts.add('Evidence: ${record.evidenceReference!.trim()}');
    return parts.isEmpty ? '' : ' — ${parts.join(' | ')}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final roadmap = app.roadmap;
    final goal = app.selectedGoal;
    final currentCerts = app.certifications
        .where((c) => c.status == CertificationStatus.current)
        .length;
    final dueCerts = app.certifications
        .where((c) => c.status == CertificationStatus.expiringSoon)
        .length;
    final expiredCerts = app.certifications
        .where((c) => c.status == CertificationStatus.expired)
        .length;
    final trainingHours = _records
        .where(
          (e) =>
              e.type == CareerRecordType.training ||
              e.type == CareerRecordType.education ||
              e.type == CareerRecordType.teaching,
        )
        .fold<double>(0, (sum, e) => sum + (e.hours ?? 0));
    final skillReps = _records
        .where((e) => e.type == CareerRecordType.skill)
        .fold<int>(0, (sum, e) => sum + e.repetitions);
    final highlights = _records.where((e) => e.highlight).length;

    final requirementIds = <String>{};
    if (roadmap != null) {
      requirementIds.addAll(roadmap.included.map((e) => e.requirement.id));
    }
    final coveredRequirementIds = _records
        .map((e) => e.relatedRequirementId)
        .whereType<String>()
        .where(requirementIds.contains)
        .toSet();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toAdvance(),

        title: const Text('Career Vault'),
        actions: [
          IconButton(
            tooltip: 'Career advancement brief',
            onPressed: () => _showCareerBrief(app),
            icon: const Icon(Icons.description_outlined),
          ),
          IconButton(
            tooltip: 'Add career evidence',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_circle_outline),
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
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.work_history_outlined,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Build the record your future self will need',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Keep skills, calls, training, leadership work, awards, projects, teaching, and task-book evidence tied to your advancement path.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(
                              alpha: 0.45,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal == null
                                    ? 'No advancement target selected'
                                    : 'Target: ${goal.title}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                roadmap == null
                                    ? 'Choose a roadmap target to connect career evidence to specific requirements.'
                                    : '${roadmap.completedCount}/${roadmap.totalCount} requirements complete • ${coveredRequirementIds.length}/${requirementIds.length} requirements have supporting career evidence',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              if (roadmap != null &&
                                  roadmap.totalCount > 0) ...[
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: roadmap.percentComplete,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _openEditor(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add evidence'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showCareerBrief(app),
                                icon: const Icon(Icons.description_outlined),
                                label: const Text('Career brief'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _SectionTitle(
                  title: 'Career snapshot',
                  subtitle: 'A long-term view across roles and departments.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricCard(
                      label: 'Records',
                      value: '${_records.length}',
                      icon: Icons.history,
                    ),
                    _MetricCard(
                      label: 'Training hours',
                      value: _trimNumber(trainingHours),
                      icon: Icons.school_outlined,
                    ),
                    _MetricCard(
                      label: 'Skill reps',
                      value: '$skillReps',
                      icon: Icons.handyman_outlined,
                    ),
                    _MetricCard(
                      label: 'Career highlights',
                      value: '$highlights',
                      icon: Icons.star_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _SectionTitle(
                  title: 'Quick capture',
                  subtitle: 'Log it while the details are still fresh.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickAdd(
                      label: 'Skill',
                      icon: Icons.handyman_outlined,
                      onTap: () =>
                          _openEditor(initialType: CareerRecordType.skill),
                    ),
                    _QuickAdd(
                      label: 'Training',
                      icon: Icons.school_outlined,
                      onTap: () =>
                          _openEditor(initialType: CareerRecordType.training),
                    ),
                    _QuickAdd(
                      label: 'Leadership',
                      icon: Icons.groups_outlined,
                      onTap: () =>
                          _openEditor(initialType: CareerRecordType.leadership),
                    ),
                    _QuickAdd(
                      label: 'Award / win',
                      icon: Icons.emoji_events_outlined,
                      onTap: () => _openEditor(
                        initialType: CareerRecordType.achievement,
                      ),
                    ),
                    _QuickAdd(
                      label: 'Call / experience',
                      icon: Icons.local_fire_department_outlined,
                      onTap: () => _openEditor(
                        initialType: CareerRecordType.operationalExperience,
                      ),
                    ),
                    _QuickAdd(
                      label: 'Task book',
                      icon: Icons.fact_check_outlined,
                      onTap: () => _openEditor(
                        initialType: CareerRecordType.taskBookEvidence,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Certification radar',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.go(AppRoutes.certifications),
                              child: const Text('Manage'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currentCerts current • $dueCerts expiring within 90 days • $expiredCerts expired',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Credentials stay in the existing certification tracker and are automatically included in your career brief.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionTitle(
                  title: 'Career timeline',
                  subtitle:
                      'Search years of evidence by skill, project, role, tag, or year.',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search career history',
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
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: _filter == null,
                          onSelected: (_) => setState(() => _filter = null),
                        ),
                      ),
                      ...CareerRecordType.values.map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(type.shortLabel),
                            selected: _filter == type,
                            onSelected: (_) => setState(
                              () => _filter = _filter == type ? null : type,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_filteredRecords.isEmpty)
                  _EmptyState(
                    hasRecords: _records.isNotEmpty,
                    onAdd: () => _openEditor(),
                  )
                else
                  ..._filteredRecords.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecordCard(
                        record: record,
                        requirementName: _requirementName(
                          app,
                          record.relatedRequirementId,
                        ),
                        onEdit: () => _openEditor(existing: record),
                        onDelete: () => _deleteRecord(record),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String? _requirementName(AppState app, String? id) {
    if (id == null) return null;
    final roadmap = app.roadmap;
    if (roadmap == null) return null;
    for (final item in roadmap.all) {
      if (item.requirement.id == id) return item.requirement.name;
    }
    return null;
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 156,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAdd({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _RecordCard extends StatelessWidget {
  final CareerRecord record;
  final String? requirementName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.requirementName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconFor(record.type),
                size: 21,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (record.highlight)
                        Icon(Icons.star, size: 18, color: cs.primary),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${record.type.label} • ${_formatDate(record.date)}${record.category.trim().isEmpty ? '' : ' • ${record.category.trim()}'}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if ((record.roleOrAssignment ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      record.roleOrAssignment!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if ((record.summary ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      record.summary!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if ((record.impact ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Impact: ${record.impact!}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (record.hours != null)
                        _MiniTag(text: '${_trimNumber(record.hours!)} hr'),
                      if (record.repetitions > 1)
                        _MiniTag(text: '${record.repetitions} reps'),
                      if (requirementName != null)
                        _MiniTag(
                          text: 'Task Book: $requirementName',
                          icon: Icons.fact_check_outlined,
                        ),
                      if ((record.evidenceReference ?? '').trim().isNotEmpty)
                        const _MiniTag(
                          text: 'Evidence noted',
                          icon: Icons.attach_file,
                        ),
                      ...record.tags.take(4).map((tag) => _MiniTag(text: tag)),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Record actions',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _MiniTag({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasRecords;
  final VoidCallback onAdd;

  const _EmptyState({required this.hasRecords, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              hasRecords ? Icons.search_off : Icons.inventory_2_outlined,
              size: 38,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              hasRecords
                  ? 'No matching career records'
                  : 'Start building your career history',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasRecords
                  ? 'Try a different search or category.'
                  : 'Record important skills, training, leadership examples, awards, projects, teaching, and operational experience as they happen.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (!hasRecords) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add first record'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(CareerRecordType type) => switch (type) {
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
