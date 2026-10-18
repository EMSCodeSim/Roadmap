import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/department/department_task_book_page.dart';
import 'package:firepath/pages/department/department_review_page.dart';
import 'package:firepath/pages/department/department_classes_page.dart';
import 'package:firepath/pages/department/department_qualifications_page.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/services/department_link_store.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/competency_evidence_bridge.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/state/app_state.dart';

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
  final _careerRecordStore = CareerRecordStore();
  List<DepartmentTaskBookAssignment> _assignments = const [];
  List<DepartmentReviewItem> _reviews = const [];
  List<DepartmentClassDetail> _rmsActions = const [];
  List<InstructorTrainingAttention> _instructorTraining = const [];
  List<DepartmentWorkQueueItem> _workQueue = const [];
  String? _expandedSection;
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
      final workQueue = await _api.getWorkQueue();
      List<DepartmentReviewItem> reviews = const [];
      List<DepartmentClassDetail> rmsActions = const [];
      List<InstructorTrainingAttention> instructorTraining = const [];
      final role = (session.role ?? '').toUpperCase();
      if (const {'EVALUATOR', 'TRAINING_OFFICER', 'DEPARTMENT_ADMINISTRATOR'}.contains(role)) {
        try { reviews = await _api.listReviewQueue(); } catch (_) {}
      }
      if (const {'INSTRUCTOR', 'TRAINING_OFFICER', 'DEPARTMENT_ADMINISTRATOR'}.contains(role)) {
        try { rmsActions = await _api.listRmsActionTrainingSheets(); } catch (_) {}
        try { instructorTraining = await _api.listInstructorTrainingAttention(); } catch (_) {}
      }
      await context.read<DepartmentInboxController>().refresh(silent: true);
      if (!mounted) return;
      await context.read<AppModeController>().refreshFromSession(session);

      // Bridge newly completed department training into the responder's
      // personal evidence without changing the official department record.
      // Matching is conservative: the verified record can support roadmap
      // progress, but it never fabricates a certification or authorization.
      try {
        final app = context.read<AppState>();
        final existing = await _careerRecordStore.load();
        var importedAny = false;
        for (final assignment in items.where((a) =>
            a.progress >= 100 ||
            a.status == 'COMPLETE' ||
            a.status == 'COMPLETED')) {
          if (CompetencyEvidenceBridge.isImported(existing, assignment)) {
            continue;
          }
          final match =
              CompetencyEvidenceBridge.matchAssignment(assignment, app.roadmap);
          final record = CompetencyEvidenceBridge.toVerifiedCareerRecord(
            assignment: assignment,
            departmentName: session.departmentName ?? 'Department',
            relatedGoalId: app.roadmap?.goal.id,
            match: match,
          );
          if (await _careerRecordStore.upsert(record)) {
            existing.add(record);
            importedAny = true;
            await app.applyLogToRequirementProgress(record);
          }
        }
        if (importedAny) {
          app.roadmapEvidenceChanged(
            reason:
                'Completed department training was added as verified evidence. Your Personal Roadmap was recalculated.',
          );
        }
      } catch (_) {
        // Department Home must remain available even if personal evidence
        // bridging cannot run on this refresh.
      }

      items.sort(_priorityCompare);
      setState(() { _assignments = items; _workQueue = workQueue.items; _reviews = reviews; _rmsActions = rmsActions; _instructorTraining = instructorTraining; _error = null; _loading = false; });
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

  Future<void> _logOutOfDepartment() async {
    if (_refreshing) return;
    final pending = await _api.pendingSubmissionCount() +
        await _api.pendingClassMutationCount();
    if (!mounted) return;
    if (pending > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sync required before logging out'),
          content: Text(
            '$pending field submission(s) are still stored on this device. '
            'Log out is blocked until they are uploaded so another account '
            'cannot accidentally submit your records. Connect to the internet and retry sync.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out of Department?'),
        content: const Text(
          'This signs out of your department on this device. '
          'Your personal roadmap and official department records will not be deleted. '
          'You can sign back in whenever needed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Clear the stored credential and link before navigating away. Never
    // interpret switching to Personal mode alone as a sign-out.
    await _api.disconnect();
    await DepartmentLinkStore().clear();
    if (!mounted) return;
    await context.read<AppModeController>().setDepartmentLink(null);
    await context.read<DepartmentInboxController>().refresh(silent: true);
    if (!mounted) return;
    setState(() {
      _assignments = const [];
      _reviews = const [];
      _rmsActions = const [];
    });
  }

  Future<void> _open(DepartmentTaskBookAssignment item) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DepartmentTaskBookPage(assignment: item),
    ));
    if (mounted) await _refresh(silent: true);
  }

  Future<void> _openClasses() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const DepartmentClassesPage(openCreateTraining: true),
    ));
    if (mounted) await _refresh(silent: true);
  }

  Future<void> _openClass(String id) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DepartmentClassDetailPage(classId: id),
    ));
    if (mounted) await _refresh(silent: true);
  }

  Future<void> _openWorkItem(DepartmentWorkQueueItem item) async {
    if (item.kind == 'ASSIGNMENT') {
      final matches = _assignments.where((row) => row.id == item.targetId);
      if (matches.isNotEmpty) await _open(matches.first);
      return;
    }
    if (item.kind == 'EVALUATION') {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DepartmentReviewPage(initialReviewId: item.targetId),
      ));
      if (mounted) await _refresh(silent: true);
      return;
    }
    if (item.kind == 'TRAINING_SHEET' || item.kind == 'RMS_ENTRY') {
      await _openClass(item.targetId);
    }
  }

  Widget _dashboardBox({
    required String id, required String title, required IconData icon,
    required int count, required Widget child,
  }) {
    final expanded = _expandedSection == id;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('$count', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 12),
            Icon(expanded ? Icons.expand_less : Icons.expand_more),
          ]),
          onTap: () => setState(() => _expandedSection = expanded ? null : id),
        ),
        if (expanded) ...[
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppModeController>();
    final inbox = context.watch<DepartmentInboxController>();
    final active = _assignments.where((a) => _status(a) != 'Complete').toList();
    final oneOffAssignments = active.where((a) => a.isSingleTask).toList();
    final assignedTaskBooks = active.where((a) => !a.isSingleTask).toList();
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Department'),
          if ((mode.departmentLink?.departmentName ?? '').isNotEmpty)
            Text(mode.departmentLink!.departmentName, style: Theme.of(context).textTheme.bodySmall),
        ]),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Department account',
            onSelected: (value) {
              if (value == 'logout') _logOutOfDepartment();
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout_rounded),
                  SizedBox(width: 10),
                  Text('Log out of Department'),
                ]),
              ),
            ],
          ),
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
                  if (_error != null) Card(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  )),
                  _SyncLine(inbox: inbox),
                  const SizedBox(height: 12),
                  _dashboardBox(
                    id: 'attention', title: 'Needs Attention',
                    icon: Icons.notification_important_outlined,
                    count: _workQueue.length,
                    child: _CanonicalWorkQueue(items: _workQueue, onTap: _openWorkItem),
                  ),
                  _dashboardBox(
                    id: 'assignments', title: 'Assignments',
                    icon: Icons.assignment_outlined, count: oneOffAssignments.length,
                    child: _Section(title: 'Assigned to you', items: oneOffAssignments,
                      status: _status, onTap: _open),
                  ),
                  _dashboardBox(
                    id: 'taskbooks', title: 'Task Books',
                    icon: Icons.menu_book_outlined, count: assignedTaskBooks.length,
                    child: _Section(title: 'Your department task books',
                      items: assignedTaskBooks, status: _status, onTap: _open),
                  ),
                  _dashboardBox(
                    id: 'instructors', title: 'Instructors',
                    icon: Icons.school_outlined,
                    count: _instructorTraining.length +
                        _rmsActions.where((item) => !_instructorTraining.any((mine) => mine.id == item.id)).length,
                    child: Column(children: [
                      Align(alignment: Alignment.centerLeft, child: FilledButton.icon(
                        onPressed: _openClasses,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create Training Sheet'),
                      )),
                      for (final item in _instructorTraining)
                        ListTile(title: Text(item.title), subtitle: Text(item.nextStep),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _openClass(item.id)),
                      for (final item in _rmsActions.where((item) => !_instructorTraining.any((mine) => mine.id == item.id)))
                        ListTile(title: Text(item.title), subtitle: const Text('Not yet entered into RMS'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _openClass(item.id)),
                      if (_instructorTraining.isEmpty && _rmsActions.isEmpty)
                        const ListTile(title: Text('No classes awaiting action')),
                    ]),
                  ),
                  _dashboardBox(
                    id: 'eligibility', title: 'Check Member Eligibility',
                    icon: Icons.verified_user_outlined, count: 0,
                    child: ListTile(
                      title: const Text('Look up member qualifications'),
                      subtitle: const Text('Check who is approved to drive, act as officer, or perform another department role.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DepartmentQualificationsPage(focusLookup: true),
                        ),
                      ),
                    ),
                  ),
                  _dashboardBox(
                    id: 'complete', title: 'Complete',
                    icon: Icons.check_circle_outline_rounded,
                    count: _assignments.where((a) => _status(a) == 'Complete').length,
                    child: _Section(title: 'Completed items',
                      items: _assignments.where((a) => _status(a) == 'Complete').toList(),
                      status: _status, onTap: _open),
                  ),
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
    final cs = Theme.of(context).colorScheme;
    final synced = inbox.syncState == DepartmentSyncState.synced;
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: (synced ? FireOpsSemanticColors.green : FireOpsSemanticColors.amber)
              .withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: (synced ? FireOpsSemanticColors.green : FireOpsSemanticColors.amber)
                .withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              synced ? Icons.cloud_done_outlined : Icons.cloud_sync_outlined,
              size: 16,
              color: synced
                  ? FireOpsSemanticColors.green
                  : FireOpsSemanticColors.amber,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
      if (inbox.unreadCount > 0) ...[
        const Spacer(),
        Text(
          '${inbox.unreadCount} update${inbox.unreadCount == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
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
        Text(
          'DEPARTMENT PRIORITY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 3),
        Text('Do this next', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(item.taskBookTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        _DepartmentStatusPill(label: status),
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              _DepartmentStatusPill(label: status(item), compact: true),
              const SizedBox(width: 8),
              Text(
                '${item.progress}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => onTap(item),
      ),
    )),
  ]);
}


class _DepartmentStatusPill extends StatelessWidget {
  const _DepartmentStatusPill({
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final color = lower.contains('return') || lower.contains('overdue')
        ? FireOpsSemanticColors.red
        : lower.contains('waiting')
            ? FireOpsSemanticColors.blue
            : lower.contains('complete')
                ? FireOpsSemanticColors.green
                : FireOpsSemanticColors.amber;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _CanonicalWorkQueue extends StatelessWidget {
  final List<DepartmentWorkQueueItem> items;
  final Future<void> Function(DepartmentWorkQueueItem) onTap;
  const _CanonicalWorkQueue({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.check_circle_outline_rounded),
        title: Text("You’re caught up"),
        subtitle: Text("No department actions need your attention."),
      );
    }
    return Column(
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(switch (item.kind) {
              "EVALUATION" => Icons.fact_check_outlined,
              "TRAINING_SHEET" => Icons.school_outlined,
              "RMS_ENTRY" => Icons.assignment_late_outlined,
              _ => item.priority == "URGENT"
                  ? Icons.notification_important_outlined
                  : Icons.assignment_outlined,
            }),
            title: Text(item.title),
            subtitle: Text('${item.reason}\nNext: ${item.actionLabel} · Owner: ${item.owner}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onTap(item),
          ),
      ],
    );
  }
}
