import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/services/theme.dart';

class DepartmentTaskBookPage extends StatefulWidget {
  final DepartmentTaskBookAssignment assignment;

  const DepartmentTaskBookPage({
    super.key,
    required this.assignment,
  });

  @override
  State<DepartmentTaskBookPage> createState() => _DepartmentTaskBookPageState();
}

class _DepartmentTaskBookPageState extends State<DepartmentTaskBookPage> {
  final ResponderRoadmapApi _api = ResponderRoadmapApi();
  late DepartmentTaskBookAssignment _assignment = widget.assignment;
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final assignment = await _api.getAssignment(_assignment.id);
      if (!mounted) return;
      setState(() => _assignment = assignment);
    } on ResponderRoadmapApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _openRequirement(DepartmentRequirement requirement) async {
    final updated = await showModalBottomSheet<DepartmentTaskBookAssignment>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RequirementSheet(
        assignment: _assignment,
        requirement: requirement,
        api: _api,
      ),
    );
    if (updated != null && mounted) {
      setState(() => _assignment = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_assignment.taskBookTitle),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: cs.primary.withValues(alpha: .14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _assignment.isSingleTask
                              ? 'Single training assignment'
                              : 'Version ${_assignment.version}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      _StatusChip(status: _assignment.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_assignment.progress}%',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${_assignment.complete} of ${_assignment.totalRequired} required items approved',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (_assignment.progress / 100)
                        .clamp(0.0, 1.0)
                        .toDouble(),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  if (_assignment.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      _assignment.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ],
                  if (_assignment.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Text(
                        _assignment.notes,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                  if (_assignment.evaluatorName != null ||
                      _assignment.supervisorName != null ||
                      _assignment.dueDate != null) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        if (_assignment.evaluatorName != null)
                          _Meta(icon: Icons.fact_check_outlined, text: 'Evaluator: ${_assignment.evaluatorName}'),
                        if (_assignment.supervisorName != null)
                          _Meta(icon: Icons.supervisor_account_outlined, text: 'Supervisor: ${_assignment.supervisorName}'),
                        if (_assignment.dueDate != null)
                          _Meta(icon: Icons.event_outlined, text: 'Due ${_shortDate(_assignment.dueDate!)}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_assignment.pendingApproval > 0)
              _Notice(
                icon: Icons.hourglass_top_rounded,
                text: '${_assignment.pendingApproval} item${_assignment.pendingApproval == 1 ? '' : 's'} waiting for department review.',
              ),
            if (_assignment.pendingApproval > 0) const SizedBox(height: 12),
            ..._assignment.sections.map((section) {
              final approved = section.requirements.where((r) => r.isFullyApproved).length;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    section.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('$approved of ${section.requirements.length} complete'),
                  children: [
                    if (section.description.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            section.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ),
                    ...section.requirements.map((requirement) {
                      final status = _requirementStatus(requirement);
                      return ListTile(
                        onTap: () => _openRequirement(requirement),
                        leading: Icon(
                          requirement.isFullyApproved
                              ? Icons.check_circle_rounded
                              : requirement.isAwaitingReview
                                  ? Icons.hourglass_top_rounded
                                  : requirement.blockedByPrerequisites
                                      ? Icons.lock_outline_rounded
                                      : Icons.radio_button_unchecked_rounded,
                          color: requirement.isFullyApproved
                              ? cs.primary
                              : requirement.isAwaitingReview
                                  ? cs.tertiary
                                  : requirement.blockedByPrerequisites
                                      ? cs.onSurfaceVariant
                                      : cs.onSurfaceVariant,
                        ),
                        title: Text(
                          requirement.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(status),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      );
                    }),
                  ],
                ),
              );
            }),
            if (_assignment.sections.isEmpty)
              const _Notice(
                icon: Icons.info_outline_rounded,
                text: 'This assigned Task Book does not contain any requirements yet.',
              ),
          ],
        ),
      ),
    );
  }
}

class _RequirementSheet extends StatefulWidget {
  final DepartmentTaskBookAssignment assignment;
  final DepartmentRequirement requirement;
  final ResponderRoadmapApi api;

  const _RequirementSheet({
    required this.assignment,
    required this.requirement,
    required this.api,
  });

  @override
  State<_RequirementSheet> createState() => _RequirementSheetState();
}

class _RequirementSheetState extends State<_RequirementSheet> {
  late final TextEditingController _notes = TextEditingController(
    text: widget.requirement.memberNotes,
  );
  final TextEditingController _evidence = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notes.dispose();
    _evidence.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !widget.requirement.canSubmit) return;
    setState(() => _submitting = true);
    try {
      final assignment = await widget.api.submitRequirement(
        assignmentId: widget.assignment.id,
        requirementId: widget.requirement.id,
        memberNotes: widget.requirement.memberNotesAllowed ? _notes.text : '',
        evidenceDescription: _evidence.text,
        evidenceType: widget.requirement.evidenceType,
      );
      if (!mounted) return;
      Navigator.of(context).pop(assignment);
    } on ResponderRoadmapApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openReference(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final requirement = widget.requirement;
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final nextRep = (requirement.repetitionCount + 1)
        .clamp(1, requirement.repetitionsRequired)
        .toInt();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 20 + viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requirement.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _StatusChip(status: _requirementStatus(requirement)),
            if (requirement.repetitionsRequired > 1) ...[
              const SizedBox(height: 10),
              Text(
                '${requirement.repetitionCount} of ${requirement.repetitionsRequired} repetitions approved',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
            if (requirement.description.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(requirement.description, style: const TextStyle(height: 1.45)),
            ],
            if (requirement.instructions.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Instructions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(requirement.instructions, style: const TextStyle(height: 1.45)),
            ],
            if ((requirement.referenceDocument ?? '').trim().isNotEmpty ||
                (requirement.referenceUrl ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Reference', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              if ((requirement.referenceDocument ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(requirement.referenceDocument!),
                ),
              if ((requirement.referenceUrl ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TextButton.icon(
                    onPressed: () => _openReference(requirement.referenceUrl!),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open reference'),
                  ),
                ),
            ],
            const SizedBox(height: 18),
            if (requirement.isFullyApproved)
              _Notice(
                icon: Icons.verified_rounded,
                text: requirement.repetitionsRequired > 1
                    ? 'All required repetitions are approved.'
                    : 'This requirement is approved.',
              )
            else if (requirement.isAwaitingReview)
              _Notice(
                icon: requirement.reviewStage == 'SUPERVISOR'
                    ? Icons.supervisor_account_outlined
                    : Icons.hourglass_top_rounded,
                text: '${requirement.reviewLabel}. You can record the next attempt after this review is complete.',
              )
            else if (requirement.blockedByPrerequisites) ...[
              _Notice(
                icon: Icons.lock_outline_rounded,
                text: 'Complete the prerequisite${requirement.prerequisiteTitles.length == 1 ? '' : 's'} first: ${requirement.prerequisiteTitles.join(', ')}.',
              ),
            ] else ...[
              if (requirement.completionStatus == 'RETURNED') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: cs.error.withValues(alpha: .3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Corrections required',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: cs.onErrorContainer,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        requirement.correctionNotes.trim().isEmpty
                            ? 'Contact your evaluator for the required corrections.'
                            : requirement.correctionNotes,
                        style: TextStyle(color: cs.onErrorContainer, height: 1.4),
                      ),
                      if ((requirement.returnedByName ?? '').trim().isNotEmpty || requirement.returnedAt != null) ...[
                        const SizedBox(height: 7),
                        Text(
                          [
                            if ((requirement.returnedByName ?? '').trim().isNotEmpty)
                              'Returned by ${requirement.returnedByName}',
                            if (requirement.returnedAt != null)
                              _shortDate(requirement.returnedAt!),
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (requirement.memberNotesAllowed) ...[
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Member notes',
                    hintText: 'What did you complete or demonstrate?',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _evidence,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Evidence / context',
                  hintText: requirement.evidenceType == 'NONE'
                      ? 'Optional context for the reviewer'
                      : 'Describe the evidence for the department reviewer',
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  requirement.evaluatorSignOffRequired || requirement.supervisorApprovalRequired
                      ? _submissionExplanation(requirement, nextRep)
                      : 'This department configured the item without a separate evaluator or supervisor sign-off. Submitting will record the repetition immediately.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _submitting
                        ? 'Submitting…'
                        : requirement.completionStatus == 'RETURNED'
                            ? 'Resubmit Corrections'
                            : 'Submit for Department Review',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _submissionExplanation(DepartmentRequirement requirement, int nextRep) {
  final repetition = requirement.repetitionsRequired > 1
      ? 'repetition $nextRep of ${requirement.repetitionsRequired}'
      : 'this requirement';
  if (requirement.evaluatorSignOffRequired && requirement.supervisorApprovalRequired) {
    return 'Submitting $repetition sends it to the evaluator first. After evaluator approval, it moves to supervisor approval. It is not counted complete until the required approval path finishes.';
  }
  if (requirement.supervisorApprovalRequired) {
    return 'Submitting $repetition sends it directly to supervisor approval.';
  }
  return 'Submitting $repetition sends it to the evaluator for approval.';
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withValues(alpha: .16)),
      ),
      child: Text(
        _humanize(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Notice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

String _requirementStatus(DepartmentRequirement requirement) {
  if (requirement.isFullyApproved) return 'Approved';
  if (requirement.isAwaitingReview) return requirement.reviewLabel;
  if (requirement.completionStatus == 'RETURNED') {
    return 'Returned — ready to revise and resubmit';
  }
  if (requirement.blockedByPrerequisites) return 'Locked — prerequisite required';
  if (requirement.repetitionCount > 0 && requirement.repetitionsRequired > 1) {
    return '${requirement.repetitionCount} of ${requirement.repetitionsRequired} repetitions approved';
  }
  return 'Ready to work';
}

String _humanize(String value) {
  if (value.isEmpty) return value;
  return value
      .toLowerCase()
      .split('_')
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _shortDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
