import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/pages/department/department_task_book_page.dart';
import 'package:firepath/pages/department/department_review_page.dart';
import 'package:firepath/pages/department/department_qualifications_page.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/competency_evidence_bridge.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';

DepartmentReviewItem? resolveDepartmentReviewTarget(
  String targetId,
  Iterable<DepartmentReviewItem> reviews,
) {
  for (final review in reviews) {
    if (review.id == targetId) return review;
  }
  return null;
}

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
    final timer = Stopwatch()..start();
    if (mounted) setState(() {
      _refreshing = true;
      if (!silent && _assignments.isEmpty && _workQueue.isEmpty) _loading = true;
    });
    try {
      // Start both independent calls without waiting for session verification.
      String? backgroundError;
      final assignmentsFuture = _api.listAssignments().then<List<DepartmentTaskBookAssignment>?>((items) => items, onError: (Object error) {
        backgroundError ??= error is ResponderRoadmapApiException
            ? error.message
            : 'Could not load department assignments.';
        return null;
      });
      final queueFuture = _api.getWorkQueue().then<DepartmentWorkQueue?>((queue) => queue, onError: (Object error) {
        backgroundError ??= error is ResponderRoadmapApiException
            ? error.message
            : 'Could not load Needs Attention.';
        return null;
      });
      final sessionFuture = _api.currentSession().then<ResponderRoadmapSession?>((session) => session, onError: (Object error) {
        backgroundError ??= error is ResponderRoadmapApiException
            ? error.message
            : 'Could not verify your department session.';
        return null;
      });
      final items = await assignmentsFuture;
      if (!mounted) return;
      if (items != null) {
        items.sort(_priorityCompare);
        setState(() { _assignments = items; _error = backgroundError; _loading = false; });
        debugPrint('Department: assignments visible after ${timer.elapsedMilliseconds}ms');
      } else {
        setState(() { _error = backgroundError; _loading = false; });
      }
      final workQueue = await queueFuture;
      if (!mounted) return;
      if (workQueue != null) {
        setState(() { _workQueue = workQueue.items; _error = backgroundError; });
        debugPrint('Department: work queue visible after ${timer.elapsedMilliseconds}ms');
      }
      final session = await sessionFuture;
      if (!mounted) return;
      if (backgroundError != null) setState(() => _error = backgroundError);
      if (session == null) return;
      final app = context.read<AppState>();
      final inbox = context.read<DepartmentInboxController>();
      final mode = context.read<AppModeController>();
      _loadSecondaryData(
        role: (session.role ?? '').toUpperCase(),
        departmentName: session.departmentName ?? 'Department',
        items: items ?? _assignments,
        app: app,
        inbox: inbox,
        mode: mode,
        session: session,
      );
    } on ResponderRoadmapApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } finally {
      if (mounted) setState(() => _refreshing = false);
      debugPrint('Department: primary refresh completed after ${timer.elapsedMilliseconds}ms');
    }
  }

  Future<void> _loadSecondaryData({
    required String role,
    required String departmentName,
    required List<DepartmentTaskBookAssignment> items,
    required AppState app,
    required DepartmentInboxController inbox,
    required AppModeController mode,
    required dynamic session,
  }) async {
    // Keep all secondary requests off the first-render path and run independent
    // work concurrently. The inbox-only refresh avoids repeating assignments
    // and queued offline writes that the app-level controller already handles.
    final tasks = <Future<void>>[
      mode.refreshFromSession(session).then<void>((_) {}, onError: (_) {}),
      inbox.refreshInboxOnly(),
      _bridgePersonalEvidence(items: items, departmentName: departmentName, app: app),
    ];
    if (const {'INSTRUCTOR', 'TRAINING_OFFICER', 'DEPARTMENT_ADMINISTRATOR'}.contains(role)) {
      tasks.add(_loadInstructorSecondaryData());
    }
    unawaited(Future.wait<void>(tasks).then<void>((_) {}));
  }

  Future<void> _loadInstructorSecondaryData() async {
    final rmsFuture = _api.listRmsActionTrainingSheets().then<List<DepartmentClassDetail>?>((value) => value, onError: (_) => null);
    final instructorFuture = _api.listInstructorTrainingAttention().then<List<InstructorTrainingAttention>?>((value) => value, onError: (_) => null);
    final results = await Future.wait<Object?>([rmsFuture, instructorFuture]);
    if (!mounted) return;
    setState(() {
      if (results[0] != null) _rmsActions = results[0]! as List<DepartmentClassDetail>;
      if (results[1] != null) _instructorTraining = results[1]! as List<InstructorTrainingAttention>;
    });
  }

  Future<void> _bridgePersonalEvidence({
    required List<DepartmentTaskBookAssignment> items,
    required String departmentName,
    required AppState app,
  }) async {
    final timer = Stopwatch()..start();
    try {
      final existing = await _careerRecordStore.load();
      var importedAny = false;
      for (final assignment in items.where((a) =>
          a.progress >= 100 || a.status == 'COMPLETE' || a.status == 'COMPLETED')) {
        if (CompetencyEvidenceBridge.isImported(existing, assignment)) continue;
        final match = CompetencyEvidenceBridge.matchAssignment(assignment, app.roadmap);
        final record = CompetencyEvidenceBridge.toVerifiedCareerRecord(
          assignment: assignment,
          departmentName: departmentName,
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
          reason: 'Completed department training was added as verified evidence. Your Personal Roadmap was recalculated.',
        );
      }
    } catch (_) {
      // Personal evidence failures must not block department access.
    } finally {
      if (kDebugMode) {
        debugPrint('Department: personal evidence sync completed after ${timer.elapsedMilliseconds}ms');
      }
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
    // NOTE: Department pages still use imperative navigation in places because
    // they embed stateful flows that predate go_router. Keep behavior stable.
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DepartmentTaskBookPage(assignment: item)));
    if (mounted) await _refresh(silent: true);
  }

  Future<void> _openClasses() async {
    await context.push('${AppRoutes.departmentTrainingSheets}?create=1');
    if (mounted) await _refresh(silent: true);
  }

  Future<void> _openClass(String id) async {
    await context.push('${AppRoutes.departmentTrainingSheets}/$id');
    if (mounted) await _refresh(silent: true);
  }

  Future<void> _openWorkItem(DepartmentWorkQueueItem item) async {
    if (item.kind == 'ASSIGNMENT' || item.kind == 'TASK_BOOK') {
      var matches = _assignments.where((row) => row.id == item.targetId);
      if (matches.isEmpty) {
        // The work queue can refresh before the assignment list. Resolve the
        // selected record again instead of navigating to an unrelated queue.
        try {
          final latest = await _api.listAssignments();
          if (!mounted) return;
          setState(() => _assignments = latest);
          matches = latest.where((row) => row.id == item.targetId);
        } catch (_) {
          // Display a specific navigation error below.
        }
      }
      if (matches.isNotEmpty) {
        await _open(matches.first);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This Task Book or Assignment is no longer available. Refresh and try again.'),
        ));
      }
      return;
    }
    if (item.kind == 'EVALUATION') {
      // Work-queue EVALUATION targetId is the review/completion ID (the same
      // identity returned by listReviewQueue), never an assignment ID. Resolve
      // it before navigating so a stale item cannot open an unrelated admin
      // queue or fail on that screen after the user has left the dashboard.
      try {
        final reviews = await _api.listReviewQueue();
        if (!mounted) return;
        if (resolveDepartmentReviewTarget(item.targetId, reviews) == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('This evaluation is no longer assigned to you. Refresh the dashboard and try again.'),
          ));
          await _refresh(silent: true);
          return;
        }
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DepartmentReviewPage(
            initialReviewId: item.targetId,
            initialReviews: reviews,
          ),
        ));
        if (mounted) await _refresh(silent: true);
      } on ResponderRoadmapApiException catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
      return;
    }
    if (item.kind == 'TRAINING_SHEET' || item.kind == 'RMS_ENTRY') {
      await _openClass(item.targetId);
    }
  }

  Widget _dashboardBox({
    required String id, required String title, required IconData icon,
    required int count, required Widget child,
    String? subtitle,
  }) {
    final expanded = _expandedSection == id;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pillBg = count > 0
        ? cs.primaryContainer.withValues(alpha: 0.85)
        : cs.surfaceContainerHighest;
    final pillFg = count > 0 ? cs.primary : cs.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expandedSection = expanded ? null : id),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: cs.primary.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
                  ),
                  child: Icon(icon, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.1)),
                      if ((subtitle ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!.trim(),
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
                      ),
                      child: Text('$count', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: pillFg)),
                    ),
                    const SizedBox(height: 6),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more, color: cs.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: AppMotion.medium,
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: [
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
            Padding(padding: const EdgeInsets.all(12), child: child),
          ]),
        ),
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
    final canManageTrainingSheets = mode.isInstructor || mode.isAdmin;
    return Scaffold(
      appBar: FirefighterRoadmapAppBar(
        subtitle: (mode.departmentLink?.departmentName ?? '').trim().isNotEmpty
            ? mode.departmentLink!.departmentName
            : 'Department',
        actions: [
          IconButton(
            tooltip: 'Department settings',
            onPressed: () => context.push(AppRoutes.departmentSettings),
            icon: const Icon(Icons.settings_outlined),
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
        child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _SyncLine(inbox: inbox),
                  const SizedBox(height: 12),
                  _dashboardBox(
                    id: 'attention', title: 'Needs Attention',
                    icon: Icons.notification_important_outlined,
                    count: _workQueue.length,
                    subtitle: 'Items that need a next step to keep department work moving.',
                    child: _CanonicalWorkQueue(items: _workQueue, onTap: _openWorkItem),
                  ),
                  _dashboardBox(
                    id: 'assignments', title: 'Assignments',
                    icon: Icons.assignment_outlined, count: oneOffAssignments.length,
                    subtitle: 'One-off items assigned to you (not a full Task Book).',
                    child: _Section(title: 'Assigned to you', items: oneOffAssignments,
                      status: _status, onTap: _open),
                  ),
                  _dashboardBox(
                    id: 'taskbooks', title: 'Task Books',
                    icon: Icons.menu_book_outlined, count: assignedTaskBooks.length,
                    subtitle: 'Department Task Books assigned to you for completion and sign-off.',
                    child: _Section(title: 'Your department task books',
                      items: assignedTaskBooks, status: _status, onTap: _open),
                  ),
                  if (canManageTrainingSheets)
                    _dashboardBox(
                      id: 'instructors',
                      title: 'Training Sheets',
                      icon: Icons.school_outlined,
                      count: _instructorTraining.length +
                          _rmsActions.where((item) => !_instructorTraining.any((mine) => mine.id == item.id)).length,
                      subtitle: 'Create classes, finalize training sheets, and handle instructor approvals.',
                      child: Column(children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonalIcon(
                            onPressed: _openClasses,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create Training Sheet'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in _instructorTraining)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(item.nextStep, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _openClass(item.id),
                          ),
                        for (final item in _rmsActions.where((item) => !_instructorTraining.any((mine) => mine.id == item.id)))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: const Text('Not yet entered into RMS'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _openClass(item.id),
                          ),
                        if (_instructorTraining.isEmpty && _rmsActions.isEmpty)
                          const ListTile(contentPadding: EdgeInsets.zero, title: Text('No classes awaiting action')),
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
                    subtitle: 'Finished items (kept for reference).',
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
    if (items.isEmpty)
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .35),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text('Nothing here right now.', style: Theme.of(context).textTheme.bodyMedium),
      )
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
    final hint = () {
      if (lower.contains('return')) {
        return 'Returned means corrections are needed. Open it, fix issues, then resubmit.';
      }
      if (lower.contains('in progress')) {
        return 'In Progress means work has started but isn’t submitted yet. Open it to continue.';
      }
      if (lower.contains('waiting')) {
        return 'Waiting means it’s pending someone else’s action (review or RMS entry).';
      }
      if (lower.contains('complete')) {
        return 'Complete means it’s finished. You can open it to review details.';
      }
      return null;
    }();
    final color = lower.contains('return') || lower.contains('overdue')
        ? FireOpsSemanticColors.red
        : lower.contains('waiting')
            ? FireOpsSemanticColors.blue
            : lower.contains('complete')
                ? FireOpsSemanticColors.green
                : FireOpsSemanticColors.amber;

    final pill = Container(
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

    if ((hint ?? '').trim().isEmpty) return pill;
    return Tooltip(message: hint!, child: Semantics(label: '$label. $hint', child: pill));
  }
}

class _CanonicalWorkQueue extends StatelessWidget {
  final List<DepartmentWorkQueueItem> items;
  final Future<void> Function(DepartmentWorkQueueItem) onTap;
  const _CanonicalWorkQueue({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            leading: Icon(
              switch (item.kind) {
              "EVALUATION" => Icons.fact_check_outlined,
              "TRAINING_SHEET" => Icons.school_outlined,
              "RMS_ENTRY" => Icons.assignment_late_outlined,
              _ => item.priority == "URGENT"
                  ? Icons.notification_important_outlined
                  : Icons.assignment_outlined,
              },
              color: item.priority == 'URGENT' ? FireOpsSemanticColors.red : cs.primary,
            ),
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
