import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/department/department_review_page.dart';
import 'package:firepath/pages/department/department_task_book_page.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/department_inbox_controller.dart';

class DepartmentInboxPage extends StatefulWidget {
  const DepartmentInboxPage({super.key});

  @override
  State<DepartmentInboxPage> createState() => _DepartmentInboxPageState();
}

class _DepartmentInboxPageState extends State<DepartmentInboxPage> {
  final _api = ResponderRoadmapApi();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DepartmentInboxController>().refresh());
  }

  Future<void> _openAction(DepartmentActionItem item) async {
    if (item.kind == 'EVALUATOR_REVIEW') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DepartmentReviewPage()));
    } else {
      final assignmentId = item.actionPath?.split('/').last ?? '';
      if (assignmentId.isEmpty) return;
      try {
        final assignment = await _api.getAssignment(assignmentId);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DepartmentTaskBookPage(assignment: assignment)));
      } on ResponderRoadmapApiException catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
    if (mounted) await context.read<DepartmentInboxController>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DepartmentInboxController>();
    final inbox = controller.inbox;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Inbox'),
        actions: [
          if ((inbox?.unreadCount ?? 0) > 0)
            TextButton(onPressed: controller.markAllRead, child: const Text('Read all')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            Text('Needs my action', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (inbox == null && controller.syncState == DepartmentSyncState.syncing)
              const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
            else if (inbox?.needsAction.isEmpty ?? true)
              const _EmptyMessage(icon: Icons.task_alt_rounded, text: 'Nothing is waiting on you right now.')
            else
              ...inbox!.needsAction.map((item) => Card(
                    child: ListTile(
                      onTap: () => _openAction(item),
                      leading: Icon(item.kind == 'MEMBER_CORRECTION' ? Icons.build_circle_outlined : Icons.fact_check_outlined, color: cs.primary),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text(item.subtitle),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  )),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: Text('Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
              if ((inbox?.unreadCount ?? 0) > 0) Badge(label: Text('${inbox!.unreadCount}')),
            ]),
            const SizedBox(height: 8),
            if (inbox?.items.isEmpty ?? true)
              const _EmptyMessage(icon: Icons.notifications_none_rounded, text: 'Assignment updates will remain available here.')
            else
              ...inbox!.items.map((item) => Card(
                    color: item.readAt == null ? cs.primaryContainer.withValues(alpha: .28) : null,
                    child: ListTile(
                      onTap: item.readAt == null ? () => controller.markRead(item.id) : null,
                      leading: Icon(item.type == 'SUBMISSION_RETURNED' ? Icons.warning_amber_rounded : Icons.notifications_outlined),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text('${item.body}\n${_date(item.createdAt)}'),
                      isThreeLine: true,
                      trailing: item.readAt == null ? const Icon(Icons.circle, size: 10) : null,
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyMessage({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .35), borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Row(children: [Icon(icon), const SizedBox(width: 10), Expanded(child: Text(text))]),
      );
}

String _date(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  return '${local.month}/${local.day}/${local.year} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
}
