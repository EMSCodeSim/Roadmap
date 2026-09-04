import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/widgets/app_mode_switcher.dart';

class DepartmentReviewPage extends StatefulWidget {
  const DepartmentReviewPage({super.key});

  @override
  State<DepartmentReviewPage> createState() => _DepartmentReviewPageState();
}

class _DepartmentReviewPageState extends State<DepartmentReviewPage> {
  final ResponderRoadmapApi _api = ResponderRoadmapApi();
  List<DepartmentReviewItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final mode = context.read<AppModeController>();
    if (!mode.canReview) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.listReviewQueue();
      if (!mounted) return;
      setState(() => _items = items);
    } on ResponderRoadmapApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(DepartmentReviewItem item) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReviewSheet(item: item, api: _api),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppModeController>();
    final cs = Theme.of(context).colorScheme;
    final elevatedRole = mode.role == 'TRAINING_OFFICER' ||
        mode.role == 'DEPARTMENT_ADMINISTRATOR';

    return Scaffold(
      appBar: AppBar(
        title: Text(elevatedRole ? 'Department Admin' : 'Evaluator Review'),
        actions: [
          if (mode.canReview)
            IconButton(
              tooltip: 'Refresh review queue',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            const AppModeSwitcher(),
            const SizedBox(height: 18),
            if (!mode.canReview)
              _MessageCard(
                icon: Icons.shield_outlined,
                title: 'Member access',
                message:
                    'Your department role does not include evaluator or administrator approval access.',
              )
            else if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 72),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _MessageCard(
                icon: Icons.sync_problem_rounded,
                title: 'Could not load reviews',
                message: _error!,
              )
            else if (_items.isEmpty)
              const _MessageCard(
                icon: Icons.task_alt_rounded,
                title: 'Review queue is clear',
                message: 'There are no department Task Book submissions waiting for you.',
              )
            else ...[
              Text(
                '${_items.length} waiting for review',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Open a submission to document the observed steps and record your decision.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 12),
              ..._items.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    onTap: () => _open(item),
                    leading: CircleAvatar(
                      child: Text(
                        item.memberName.trim().isEmpty
                            ? '?'
                            : item.memberName.trim()[0].toUpperCase(),
                      ),
                    ),
                    title: Text(
                      item.requirementTitle,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${item.memberName} · ${item.taskBookTitle}\n${_stageLabel(item.reviewStage)}',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
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

class _ReviewSheet extends StatefulWidget {
  final DepartmentReviewItem item;
  final ResponderRoadmapApi api;

  const _ReviewSheet({required this.item, required this.api});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final TextEditingController _notes = TextEditingController();
  final Set<String> _completedSteps = <String>{};
  final Set<String> _criticalFailures = <String>{};
  bool _attested = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit(String result) async {
    if (_saving) return;
    if (result == 'APPROVED' &&
        _completedSteps.length != widget.item.evaluationSteps.length) {
      setState(() => _error = 'Confirm every required evaluation step before approving.');
      return;
    }
    if (result == 'APPROVED' && _criticalFailures.isNotEmpty) {
      setState(() => _error = 'An item with a critical failure cannot be approved.');
      return;
    }
    if (result == 'APPROVED' && !_attested) {
      setState(() => _error = 'Confirm the evaluator attestation before approving.');
      return;
    }
    if (result == 'RETURNED' && _notes.text.trim().isEmpty) {
      setState(() => _error = 'Add a note explaining what the member must correct.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.reviewSignOff(
        completionId: widget.item.id,
        result: result,
        notes: _notes.text,
        attested: result == 'APPROVED' && _attested,
        stepResults: widget.item.evaluationSteps
            .map(
              (step) => <String, String>{
                'id': step.id,
                'rating': _completedSteps.contains(step.id) ? 'PASS' : 'NOT_OBSERVED',
              },
            )
            .toList(growable: false),
        criticalFailuresTriggered: _criticalFailures.toList(growable: false),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ResponderRoadmapApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cs = Theme.of(context).colorScheme;
    final insets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 20 + insets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.requirementTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text('${item.memberName} · ${item.taskBookTitle}',
                style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            if (item.requirementDescription.trim().isNotEmpty)
              Text(item.requirementDescription, style: const TextStyle(height: 1.4)),
            if (item.instructions.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Instructions', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(item.instructions, style: const TextStyle(height: 1.4)),
            ],
            if (item.memberNotes.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Member notes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(item.memberNotes),
            ],
            if (item.evaluationSteps.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Observed steps', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              ...item.evaluationSteps.map(
                (step) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _completedSteps.contains(step.id),
                  title: Text(step.text),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                            value == true
                                ? _completedSteps.add(step.id)
                                : _completedSteps.remove(step.id);
                          }),
                ),
              ),
            ],
            if (item.criticalFailures.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Critical failures', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.error, fontWeight: FontWeight.w900)),
              ...item.criticalFailures.map(
                (failure) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _criticalFailures.contains(failure.id),
                  title: Text(failure.text),
                  activeColor: cs.error,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                            value == true
                                ? _criticalFailures.add(failure.id)
                                : _criticalFailures.remove(failure.id);
                          }),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Evaluator notes'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _attested,
              title: const Text('I verify this completion and electronic sign-off.'),
              onChanged: _saving ? null : (value) => setState(() => _attested = value == true),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _submit('RETURNED'),
                    child: const Text('Return'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _submit('APPROVED'),
                    child: Text(_saving ? 'Saving…' : 'Approve'),
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

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageCard({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: cs.primary),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String _stageLabel(String stage) {
  if (stage == 'SUPERVISOR') return 'Supervisor approval';
  if (stage == 'EVALUATOR') return 'Evaluator review';
  return 'Department approval';
}
