import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/department/department_task_book_page.dart';
import 'package:firepath/pages/department/department_classes_page.dart';
import 'package:firepath/pages/department/department_review_page.dart';
import 'package:firepath/pages/department/department_qr_scanner_page.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/widgets/app_mode_switcher.dart';

/// Canonical department home for members. Official department records are read
/// from responderroadmap.com; no local department database is used here.
class DepartmentTrainingHomePage extends StatefulWidget {
  const DepartmentTrainingHomePage({super.key});

  @override
  State<DepartmentTrainingHomePage> createState() => _DepartmentTrainingHomePageState();
}

class _DepartmentTrainingHomePageState extends State<DepartmentTrainingHomePage>
    with WidgetsBindingObserver {
  final _api = ResponderRoadmapApi();
  List<DepartmentTaskBookAssignment> _assignments = const [];
  List<DepartmentReviewItem> _reviews = const [];
  List<DepartmentClassSummary> _classes = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(silent: true);
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    if (mounted) setState(() { _refreshing = true; if (!silent) _loading = true; });
    try {
      final session = await _api.currentSession();
      final items = await _api.listAssignments();
      List<DepartmentReviewItem> reviews = const [];
      List<DepartmentClassSummary> classes = const [];
      final role = (session.role ?? '').toUpperCase();
      if (const {'EVALUATOR', 'TRAINING_OFFICER', 'DEPARTMENT_ADMINISTRATOR'}.contains(role)) {
        try { reviews = await _api.listReviewQueue(); } catch (_) {}
      }
      if (const {'INSTRUCTOR', 'TRAINING_OFFICER', 'DEPARTMENT_ADMINISTRATOR'}.contains(role)) {
        try { classes = await _api.listClasses(); } catch (_) {}
      }
      await context.read<DepartmentInboxController>().refresh(silent: true);
      if (!mounted) return;
      await context.read<AppModeController>().refreshFromSession(session);
      items.sort(_priorityCompare);
      setState(() { _assignments = items; _reviews = reviews; _classes = classes; _error = null; _loading = false; });
    } on ResponderRoadmapApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  static int _priorityCompare(DepartmentTaskBookAssignment a, DepartmentTaskBookAssignment b) {
    int score(DepartmentTaskBookAssignment x) {
      final returned = x.sections.expand((s) => s.requirements)
          .any((r) => r.correctionNotes.trim().isNotEmpty && !r.isFullyApproved);
      if (returned) return 0;
      if (x.overdue > 0 || (x.dueDate != null && x.dueDate!.isBefore(DateTime.now()) && x.progress < 100)) return 1;
      if (x.pendingApproval > 0) return 3;
      if (x.progress >= 100 || x.status == 'COMPLETE' || x.status == 'COMPLETED') return 4;
      return 2;
    }
    final byPriority = score(a).compareTo(score(b));
    if (byPriority != 0) return byPriority;
    return (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999));
  }

  String _status(DepartmentTaskBookAssignment a) {
    final returned = a.sections.expand((s) => s.requirements)
        .any((r) => r.correctionNotes.trim().isNotEmpty && !r.isFullyApproved);
    if (returned) return 'Returned — correction needed';
    if (a.overdue > 0 || (a.dueDate != null && a.dueDate!.isBefore(DateTime.now()) && a.progress < 100)) return 'Overdue';
    if (a.pendingApproval > 0) return 'Waiting for evaluator';
    if (a.progress >= 100 || a.status == 'COMPLETE' || a.status == 'COMPLETED') return 'Complete';
    return 'Ready to do';
  }

  Future<void> _open(DepartmentTaskBookAssignment item) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DepartmentTaskBookPage(assignment: item),
    ));
    if (mounted) await _refresh(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppModeController>();
    final inbox = context.watch<DepartmentInboxController>();
    final active = _assignments.where((a) => _status(a) != 'Complete').toList();
    final waiting = _assignments.where((a) => _status(a) == 'Waiting for evaluator').toList();
    final completed = _assignments.where((a) => _status(a) == 'Complete').take(5).toList();
    final next = active.where((a) => _status(a) != 'Waiting for evaluator').firstOrNull;
    final returned = active.where((a) => _status(a).startsWith('Returned')).toList();
    final overdue = active.where((a) => _status(a) == 'Overdue').toList();
    final openClasses = _classes.where((c) => c.status != 'COMPLETE').toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Training'),
          if ((mode.departmentLink?.departmentName ?? '').isNotEmpty)
            Text(mode.departmentLink!.departmentName, style: Theme.of(context).textTheme.bodySmall),
        ]),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshing ? null : () => _refresh(),
            icon: _refreshing
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? ListView(children: [SizedBox(height: 220), Center(child: CircularProgressIndicator())])
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  const AppModeSwitcher(),
                  const SizedBox(height: 12),
                  if (_error != null) Card(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  )),
                  _SyncLine(inbox: inbox),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final checkedIn = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => const DepartmentQrScannerPage()),
                        );
                        if (checkedIn == true && mounted) await _refresh(silent: true);
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan Training QR'),
                    ),
                  ),
                  if (mode.isAdmin) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DepartmentClassesPage(openCreateTraining: true)),
                        ),
                        icon: const Icon(Icons.note_add_outlined),
                        label: const Text('Create Training Sheet'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _NeedsAttention(
                    returned: returned,
                    overdue: overdue,
                    reviews: _reviews,
                    classes: openClasses,
                    onAssignment: _open,
                    onReview: (item) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DepartmentReviewPage(initialReviewId: item.id))),
                    onClass: (item) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DepartmentClassDetailPage(classId: item.id))),
                  ),
                  const SizedBox(height: 12),
                  if (next != null) _NextCard(item: next, status: _status(next), onTap: () => _open(next))
                  else if (waiting.isNotEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Your submitted training is waiting for department review.')))
                  else
                    const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('You are caught up. New department training will appear here automatically.'))),
                  const SizedBox(height: 18),
                  _Section(title: 'My Training', items: active, status: _status, onTap: _open),
                  if (waiting.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _Section(title: 'Waiting for Evaluator', items: waiting, status: _status, onTap: _open),
                  ],
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _Section(title: 'Recently Completed', items: completed, status: _status, onTap: _open),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SyncLine extends StatelessWidget {
  final DepartmentInboxController inbox;
  const _SyncLine({required this.inbox});
  @override
  Widget build(BuildContext context) {
    final label = switch (inbox.syncState) {
      DepartmentSyncState.synced => 'Synced',
      DepartmentSyncState.waitingToUpload => 'Waiting to upload',
      DepartmentSyncState.failed => 'Sync failed',
      DepartmentSyncState.syncing => 'Syncing…',
      DepartmentSyncState.disconnected => 'Disconnected',
    };
    return Row(children: [
      Icon(inbox.syncState == DepartmentSyncState.synced ? Icons.cloud_done_outlined : Icons.cloud_sync_outlined, size: 18),
      const SizedBox(width: 7),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      if (inbox.unreadCount > 0) ...[const Spacer(), Text('${inbox.unreadCount} update${inbox.unreadCount == 1 ? '' : 's'}')],
    ]);
  }
}

class _NextCard extends StatelessWidget {
  final DepartmentTaskBookAssignment item;
  final String status;
  final VoidCallback onTap;
  const _NextCard({required this.item, required this.status, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('DO THIS NEXT', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(item.taskBookTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(status),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: (item.progress.clamp(0, 100)) / 100),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Continue Training')),
      ]),
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<DepartmentTaskBookAssignment> items;
  final String Function(DepartmentTaskBookAssignment) status;
  final Future<void> Function(DepartmentTaskBookAssignment) onTap;
  const _Section({required this.title, required this.items, required this.status, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    if (items.isEmpty) Text('Nothing here right now.', style: Theme.of(context).textTheme.bodyMedium)
    else ...items.map((item) => Card(
      child: ListTile(
        title: Text(item.taskBookTitle),
        subtitle: Text('${status(item)} · ${item.progress}%'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => onTap(item),
      ),
    )),
  ]);
}


class _NeedsAttention extends StatelessWidget {
  final List<DepartmentTaskBookAssignment> returned;
  final List<DepartmentTaskBookAssignment> overdue;
  final List<DepartmentReviewItem> reviews;
  final List<DepartmentClassSummary> classes;
  final Future<void> Function(DepartmentTaskBookAssignment) onAssignment;
  final void Function(DepartmentReviewItem) onReview;
  final void Function(DepartmentClassSummary) onClass;

  const _NeedsAttention({
    required this.returned,
    required this.overdue,
    required this.reviews,
    required this.classes,
    required this.onAssignment,
    required this.onReview,
    required this.onClass,
  });

  @override
  Widget build(BuildContext context) {
    final count = returned.length + overdue.length + reviews.length + classes.length;
    if (count == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.check_circle_outline_rounded),
            const SizedBox(width: 10),
            Expanded(child: Text('Needs Attention', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            const Text('Nothing urgent'),
          ]),
        ),
      );
    }

    final tiles = <Widget>[];
    for (final item in returned.take(2)) {
      tiles.add(ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.assignment_return_outlined),
        title: Text(item.taskBookTitle),
        subtitle: const Text('Returned — correction needed'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => onAssignment(item),
      ));
    }
    for (final item in overdue.take(2)) {
      tiles.add(ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.schedule_rounded),
        title: Text(item.taskBookTitle),
        subtitle: const Text('Overdue training'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => onAssignment(item),
      ));
    }
    for (final item in reviews.take(2)) {
      tiles.add(ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.fact_check_outlined),
        title: Text(item.requirementTitle),
        subtitle: Text('${item.memberName} · evaluation waiting'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => onReview(item),
      ));
    }
    for (final item in classes.take(2)) {
      tiles.add(ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.groups_2_outlined),
        title: Text(item.title),
        subtitle: Text('${item.completeCount} of ${item.rosterCount} complete · ${item.status}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => onClass(item),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Needs Attention', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
            Text('$count', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 4),
          Text('Open the item that needs action now.', style: Theme.of(context).textTheme.bodySmall),
          ...tiles,
        ]),
      ),
    );
  }
}
