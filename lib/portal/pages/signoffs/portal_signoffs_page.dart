import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/portal/models/assignment_models.dart';
import 'package:firepath/portal/models/task_book_template.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/status_pill.dart';

class PortalSignoffsPage extends StatefulWidget {
  const PortalSignoffsPage({super.key});

  @override
  State<PortalSignoffsPage> createState() => _PortalSignoffsPageState();
}

class _PortalSignoffsPageState extends State<PortalSignoffsPage> {
  String? _selectedCompletionId;

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final deptId = portal.activeDepartmentId;
    final assignmentIds = deptId == null
        ? const <String>{}
        : portal.db.assignments.where((a) => a.departmentId == deptId).map((a) => a.id).toSet();
    final queue = portal.db.completions
        .where((c) => assignmentIds.contains(c.assignmentId) && c.status == CompletionStatus.submitted)
        .toList();
    queue.sort((a, b) => (b.submittedAt ?? DateTime(0)).compareTo(a.submittedAt ?? DateTime(0)));

    _selectedCompletionId ??= queue.isEmpty ? null : queue.first.id;
    final selected = queue
        .cast<RequirementCompletion?>()
        .firstWhere((c) => c?.id == _selectedCompletionId, orElse: () => queue.isEmpty ? null : queue.first);

    return PortalPageScaffold(
      title: 'Requirement Sign-Offs',
      subtitle: 'Approve or return submitted requirements. All actions are recorded in an audit trail.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final split = constraints.maxWidth >= 1040;
          final list = _QueueList(
            queue: queue,
            selectedId: _selectedCompletionId,
            onSelect: (id) => setState(() => _selectedCompletionId = id),
          );
          final detail = _QueueDetail(completion: selected);
          if (!split) {
            return ListView(
              children: [
                list,
                const SizedBox(height: AppSpacing.md),
                detail,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 420, child: list),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: detail),
            ],
          );
        },
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  final List<RequirementCompletion> queue;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  const _QueueList({required this.queue, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Awaiting My Review', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                StatusPill(text: '${queue.length} pending', icon: Icons.fact_check, backgroundColor: FireOpsSemanticColors.expiring.withValues(alpha: 0.10), foregroundColor: FireOpsSemanticColors.expiring),
              ],
            ),
            const SizedBox(height: 10),
            if (queue.isEmpty)
              Text('No items awaiting sign-off.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: queue.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = queue[i];
                  final member = portal.db.users.cast().firstWhere((u) => u.id == c.memberId, orElse: () => null);
                  final req = portal.db.taskBookRequirements.cast<TaskBookRequirement?>().firstWhere((r) => r?.id == c.requirementId, orElse: () => null);
                  final isSelected = c.id == selectedId;
                  return InkWell(
                    onTap: () => onSelect(c.id),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primaryContainer.withValues(alpha: 0.20) : cs.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: isSelected ? cs.primary.withValues(alpha: 0.35) : cs.outline.withValues(alpha: 0.14)),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member?.name ?? 'Member', style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(req?.title ?? 'Requirement', style: TextStyle(color: cs.onSurfaceVariant, height: 1.35)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              StatusPill(text: _taskBookTitle(portal, c.assignmentId), icon: Icons.menu_book_outlined, maxWidth: 220),
                              StatusPill(text: c.submittedAt == null ? 'Submitted' : _shortDateTime(c.submittedAt!), icon: Icons.event, maxWidth: 170),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _taskBookTitle(PortalController portal, String assignmentId) {
    final a = portal.db.assignments.firstWhere((a) => a.id == assignmentId);
    final v = portal.db.taskBookVersions.firstWhere((v) => v.id == a.taskBookVersionId);
    final t = portal.db.taskBookTemplates.firstWhere((t) => t.id == v.templateId);
    return '${t.title} v${v.version}';
  }

  String _shortDateTime(DateTime dt) => '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _QueueDetail extends StatefulWidget {
  final RequirementCompletion? completion;
  const _QueueDetail({required this.completion});

  @override
  State<_QueueDetail> createState() => _QueueDetailState();
}

class _QueueDetailState extends State<_QueueDetail> {
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final c = widget.completion;
    if (c == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text('Select a submitted requirement to review.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      );
    }

    final member = portal.db.users.cast().firstWhere((u) => u.id == c.memberId, orElse: () => null);
    final req = portal.db.taskBookRequirements.cast<TaskBookRequirement?>().firstWhere((r) => r?.id == c.requirementId, orElse: () => null);
    final evid = portal.db.evidence.where((e) => e.completionId == c.id).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member?.name ?? 'Member', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(req?.title ?? 'Requirement', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                    ],
                  ),
                ),
                StatusPill(text: 'Submitted', icon: Icons.fact_check, backgroundColor: FireOpsSemanticColors.expiring.withValues(alpha: 0.10), foregroundColor: FireOpsSemanticColors.expiring),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailBlock(
              title: 'Member notes',
              child: Text(c.memberNotes.trim().isEmpty ? '—' : c.memberNotes, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45)),
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailBlock(
              title: 'Evidence',
              child: evid.isEmpty
                  ? Text('No evidence attached.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
                  : Column(
                      children: evid
                          .map(
                            (e) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.attachment, color: cs.onSurfaceVariant),
                              title: Text(e.type, style: const TextStyle(fontWeight: FontWeight.w900)),
                              subtitle: Text(e.description.isEmpty ? '—' : e.description),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailBlock(
              title: 'Evaluator note (optional)',
              child: TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Add note that will be stored in the audit trail…'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            try {
                              await portal.returnCompletion(c.id, evaluatorId: portal.sessionUserId!, notes: _notes.text.trim());
                              _notes.clear();
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          },
                    icon: const Icon(Icons.undo),
                    label: const Text('Return'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            try {
                              await portal.approveCompletion(c.id, evaluatorId: portal.sessionUserId!, notes: _notes.text.trim());
                              _notes.clear();
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
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

class _DetailBlock extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
