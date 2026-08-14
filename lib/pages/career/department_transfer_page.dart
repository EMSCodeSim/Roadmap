import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/department_transfer.dart';
import 'package:firepath/services/career_pdf_export.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/department_transfer_service.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class DepartmentTransferPage extends StatefulWidget {
  const DepartmentTransferPage({super.key});

  @override
  State<DepartmentTransferPage> createState() => _DepartmentTransferPageState();
}

class _DepartmentTransferPageState extends State<DepartmentTransferPage> {
  final DepartmentTransferStore _store = DepartmentTransferStore();
  final CareerRecordStore _recordsStore = CareerRecordStore();
  final CareerExportIdentityStore _identityStore = CareerExportIdentityStore();
  final _department = TextEditingController();
  List<CareerRecord> _records = const [];
  DepartmentTransferPlan _plan = DepartmentTransferPlan.empty();
  CareerExportIdentity _identity = CareerExportIdentity.empty();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _store.load(),
      _recordsStore.load(),
      _identityStore.load(),
    ]);
    final plan = results[0] as DepartmentTransferPlan;
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _department.text = plan.departmentName;
      _records = results[1] as List<CareerRecord>;
      _identity = results[2] as CareerExportIdentity;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _department.dispose();
    super.dispose();
  }

  Future<void> _save(DepartmentTransferPlan plan) async {
    final saved = plan.copyWith(
      departmentName: _department.text.trim(),
      updatedAt: DateTime.now(),
    );
    await _store.save(saved);
    if (!mounted) return;
    setState(() => _plan = saved);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final evaluation = DepartmentTransferService.evaluate(
      app: app,
      records: _records,
      plan: _plan.copyWith(departmentName: _department.text.trim()),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Department Transfer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'See what carries with you.',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Compare another department’s requirements against the credentials, Task Book history, and career evidence you already have. Your current Career Road is not changed.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _department,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Target department / agency',
                    hintText: 'Example: North Valley Fire Rescue',
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _save(_plan),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _plan.targetGoalId,
                  decoration: const InputDecoration(labelText: 'Target role / path'),
                  items: app.availableGoals
                      .map((goal) => DropdownMenuItem(
                            value: goal.id,
                            child: Text(goal.title),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    final goal = app.availableGoals.where((g) => g.id == value).firstOrNull;
                    await _save(_plan.copyWith(
                      targetGoalId: value,
                      targetRole: goal?.title,
                    ));
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _plan.targetGoalId == null
                        ? null
                        : () => _importTypical(app),
                    icon: const Icon(Icons.playlist_add_check_outlined),
                    label: const Text('Load typical requirements for this path'),
                  ),
                ),
                const SizedBox(height: 18),
                _ReadinessHero(evaluation: evaluation),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'TARGET REQUIREMENTS',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addRequirement,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (_plan.requirements.isEmpty)
                  _InfoCard(
                    icon: Icons.rule_folder_outlined,
                    title: 'Add the receiving department’s requirements',
                    text: 'Start from a typical FireOps path, then add or edit local certifications, experience, task books, education, practicals, and promotional steps.',
                  )
                else
                  ...evaluation.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RequirementCard(
                        item: item,
                        onToggleManual: () => _toggleManual(item.requirement),
                        onEdit: () => _editRequirement(item.requirement),
                        onDelete: () => _deleteRequirement(item.requirement.id),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                _InfoCard(
                  icon: Icons.verified_user_outlined,
                  title: 'What this comparison means',
                  text: 'A match means Career Road found a current credential, related record, retained progress, or a user-confirmed equivalent. It does not mean the receiving department has accepted it.',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: evaluation.totalCount == 0
                            ? null
                            : () => _previewPdf(app, evaluation),
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Preview PDF'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: evaluation.totalCount == 0
                            ? null
                            : () => _sharePdf(app, evaluation),
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text('Share Report'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _importTypical(AppState app) async {
    final goal = app.availableGoals
        .where((g) => g.id == _plan.targetGoalId)
        .cast<CareerGoal?>()
        .firstOrNull;
    if (goal == null) return;
    final imported = DepartmentTransferService.requirementsFromGoal(goal);
    final existingByTitle = {
      for (final r in _plan.requirements) r.title.trim().toLowerCase(): r,
    };
    final merged = [..._plan.requirements];
    for (final item in imported) {
      if (!existingByTitle.containsKey(item.title.trim().toLowerCase())) {
        merged.add(item);
      }
    }
    await _save(_plan.copyWith(
      targetRole: goal.title,
      requirements: merged,
    ));
  }

  Future<void> _addRequirement() async {
    final created = await _requirementDialog(null);
    if (created == null) return;
    await _save(_plan.copyWith(requirements: [..._plan.requirements, created]));
  }

  Future<void> _editRequirement(DepartmentTransferRequirement requirement) async {
    final edited = await _requirementDialog(requirement);
    if (edited == null) return;
    final next = _plan.requirements
        .map((item) => item.id == edited.id ? edited : item)
        .toList();
    await _save(_plan.copyWith(requirements: next));
  }

  Future<DepartmentTransferRequirement?> _requirementDialog(
    DepartmentTransferRequirement? existing,
  ) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    var kind = existing?.kind ?? TransferRequirementKind.other;
    final result = await showDialog<DepartmentTransferRequirement>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add requirement' : 'Edit requirement'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Requirement',
                    hintText: 'Example: Driver Operator Pumper',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TransferRequirementKind>(
                  value: kind,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: TransferRequirementKind.values
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => kind = value);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Department notes / details',
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
                if (title.text.trim().isEmpty) return;
                final id = existing?.id ??
                    'custom:${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
                Navigator.pop(
                  dialogContext,
                  DepartmentTransferRequirement(
                    id: id,
                    title: title.text.trim(),
                    kind: kind,
                    certificationDefinitionId:
                        existing?.certificationDefinitionId,
                    keywords: existing?.keywords ?? [title.text.trim()],
                    manuallySatisfied: existing?.manuallySatisfied ?? false,
                    notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    notes.dispose();
    return result;
  }

  Future<void> _toggleManual(DepartmentTransferRequirement requirement) async {
    final next = _plan.requirements
        .map((item) => item.id == requirement.id
            ? item.copyWith(manuallySatisfied: !item.manuallySatisfied)
            : item)
        .toList();
    await _save(_plan.copyWith(requirements: next));
  }

  Future<void> _deleteRequirement(String id) async {
    await _save(_plan.copyWith(
      requirements: _plan.requirements.where((e) => e.id != id).toList(),
    ));
  }

  Future<void> _previewPdf(
    AppState app,
    DepartmentTransferEvaluation evaluation,
  ) async {
    await _save(evaluation.plan);
    await Printing.layoutPdf(
      name: 'FireOps_Department_Transfer_Readiness.pdf',
      onLayout: (_) => CareerPdfExport.buildTransferReport(
        app: app,
        evaluation: evaluation,
        identity: _identity,
      ),
    );
  }

  Future<void> _sharePdf(
    AppState app,
    DepartmentTransferEvaluation evaluation,
  ) async {
    await _save(evaluation.plan);
    final bytes = await CareerPdfExport.buildTransferReport(
      app: app,
      evaluation: evaluation,
      identity: _identity,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'FireOps_Department_Transfer_Readiness.pdf',
    );
  }
}

class _ReadinessHero extends StatelessWidget {
  final DepartmentTransferEvaluation evaluation;
  const _ReadinessHero({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final percent = (evaluation.percent * 100).round();
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: evaluation.percent,
                    strokeWidth: 7,
                  ),
                ),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated requirement overlap',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${evaluation.satisfiedCount} of ${evaluation.totalCount} entered requirements have likely supporting evidence.',
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
    );
  }
}

class _RequirementCard extends StatelessWidget {
  final TransferRequirementEvaluation item;
  final VoidCallback onToggleManual;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RequirementCard({
    required this.item,
    required this.onToggleManual,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
                color: item.satisfied ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.requirement.title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.requirement.kind.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            item.reason,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onToggleManual,
            icon: Icon(item.requirement.manuallySatisfied
                ? Icons.undo
                : Icons.verified_outlined),
            label: Text(item.requirement.manuallySatisfied
                ? 'Remove manual match'
                : 'Mark equivalent / accepted'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
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
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
