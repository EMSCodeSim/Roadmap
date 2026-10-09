import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/needs_attention_engine.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final department = context.watch<DepartmentInboxController>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _Header(onSettings: () => context.push(AppRoutes.settings)),
            const SizedBox(height: 14),
            _MyStatusCard(app: app, department: department),
            const SizedBox(height: 14),
            _HomeOverview(app: app, department: department),
          ],
        ),
      ),
    );
  }
}

class _MyStatusCard extends StatelessWidget {
  final AppState app;
  final DepartmentInboxController department;

  const _MyStatusCard({required this.app, required this.department});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roadmap = app.roadmap;
    final currentRole = app.profile.currentRoles.isEmpty
        ? 'Not set'
        : app.profile.currentRoles.first;
    final nextTarget = roadmap?.goal.title ?? 'Choose a roadmap';
    final progress =
        roadmap == null ? null : (roadmap.percentComplete * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MY GOAL · MY PROGRESS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'My Roadmap',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                if (progress != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$progress%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _StatusLine(label: 'Current level', value: currentRole),
            _StatusLine(label: 'Career goal', value: nextTarget),
            _StatusLine(
              label: 'Requirements completed',
              value: roadmap == null ? 'Not started' : '${roadmap.completedCount}/${roadmap.totalCount}',
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (progress / 100).clamp(0, 1),
                  minHeight: 8,
                  backgroundColor:
                      cs.surfaceContainerHighest.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.go(AppRoutes.myPath),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(roadmap == null ? 'Build My Roadmap' : 'View My Roadmap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String label;
  final String value;
  final bool alert;

  const _StatusLine({
    required this.label,
    required this.value,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: alert ? cs.error : cs.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}


class _HomeOverview extends StatefulWidget {
  final AppState app;
  final DepartmentInboxController department;

  const _HomeOverview({required this.app, required this.department});

  @override
  State<_HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<_HomeOverview>
    with WidgetsBindingObserver {
  final _recordStore = CareerRecordStore();
  final _api = ResponderRoadmapApi();
  List<CareerRecord> _records = const [];
  List<DepartmentTaskBookAssignment>? _assignments;
  bool _loadingPersonal = true;
  bool _loadingDepartment = true;
  bool _connected = false;
  String? _departmentError;

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
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final records = await _recordStore.load();
      if (mounted) setState(() {
        _records = records;
        _loadingPersonal = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPersonal = false);
    }
    try {
      final connected = await _api.hasStoredToken;
      if (!connected) {
        if (mounted) setState(() {
          _connected = false;
          _assignments = null;
          _departmentError = null;
          _loadingDepartment = false;
        });
        return;
      }
      if (mounted) setState(() {
        _connected = true;
        _loadingDepartment = true;
      });
      final assignments = await _api.listAssignments();
      if (mounted) setState(() {
        _assignments = assignments;
        _departmentError = null;
        _loadingDepartment = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _connected = true;
        _departmentError = 'Department progress could not be refreshed.';
        _loadingDepartment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _personalCard(context),
      const SizedBox(height: 14),
      _departmentCard(context),
    ]);
  }

  Widget _personalCard(BuildContext context) {
    final app = widget.app;
    final roadmap = app.roadmap;
    final needs = _loadingPersonal
        ? <NeedsAttentionItem>[]
        : NeedsAttentionEngine.analyze(app: app, records: _records);
    final credentialNeeds = needs.where((item) =>
        item.certificationId != null ||
        item.kind == NeedsAttentionKind.certificationMatch).length;

    return _OverviewCard(
      icon: Icons.person_outline_rounded,
      title: 'Personal overview',
      subtitle: 'Your requirements, credentials and next steps',
      action: 'Open My Roadmap',
      onAction: () => context.go(AppRoutes.myPath),
      children: [
        Row(children: [
          Expanded(child: _OverviewMetric(
            value: roadmap == null ? '—' : '${roadmap.missing.length}',
            label: 'Still needed',
          )),
          Expanded(child: _OverviewMetric(
            value: '$credentialNeeds',
            label: 'Credential needs',
            alert: credentialNeeds > 0,
          )),
          Expanded(child: _OverviewMetric(
            value: _loadingPersonal ? '—' : '${_records.length}',
            label: 'Records logged',
          )),
        ]),
        const SizedBox(height: 12),
        Text('Needs attention',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        if (_loadingPersonal)
          const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator())
        else if (needs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No urgent personal items right now.'),
          )
        else
          ...needs.take(2).map((item) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(item.certificationId != null
                ? Icons.workspace_premium_outlined : Icons.route_outlined),
            title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(item.detail, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go(item.certificationId != null ||
                    item.kind == NeedsAttentionKind.certificationMatch
                ? AppRoutes.certifications : AppRoutes.myPath),
          )),
        if (needs.length > 2)
          TextButton(
            onPressed: () => context.go(AppRoutes.myPath),
            child: Text('${needs.length - 2} more personal items'),
          ),
      ],
    );
  }

  Widget _departmentCard(BuildContext context) {
    final inbox = widget.department;
    final assignments = _assignments;
    final done = assignments?.where((item) => item.progress >= 100).length ?? 0;
    final waiting = assignments?.where((item) => item.pendingApproval > 0).length ?? 0;
    final completedSteps = assignments?.fold<int>(0, (total, item) => total + item.complete) ?? 0;
    final requiredSteps = assignments?.fold<int>(0, (total, item) => total + item.totalRequired) ?? 0;
    final progress = requiredSteps > 0 ? (completedSteps / requiredSteps).clamp(0.0, 1.0).toDouble() : null;
    final urgent = inbox.urgentAssignments;
    final actions = inbox.inbox?.needsAction ?? const <DepartmentActionItem>[];
    final sync = inbox.syncState;

    return _OverviewCard(
      icon: Icons.apartment_outlined,
      title: 'Department overview',
      subtitle: 'Assigned training, evaluations and department needs',
      action: 'Open Department',
      onAction: () => context.go(AppRoutes.department),
      trailing: IconButton(
        tooltip: 'Refresh department progress',
        onPressed: _loadingDepartment ? null : () {
          _refresh();
          inbox.refresh(silent: true);
        },
        icon: const Icon(Icons.refresh_rounded),
      ),
      children: [
        if (!_connected && !_loadingDepartment)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Connect to your department to see assigned training and progress.'),
          )
        else ...[
          if (_departmentError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_departmentError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_loadingDepartment && assignments == null)
            const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator())
          else if (assignments != null) ...[
            Row(children: [
              Expanded(child: _OverviewMetric(
                value: '${assignments.length}', label: 'Assigned')),
              Expanded(child: _OverviewMetric(
                value: '$done', label: '100% progress')),
              Expanded(child: _OverviewMetric(
                value: '$waiting', label: 'Awaiting sign-off', alert: waiting > 0)),
            ]),
            if (progress != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Text('Required steps completed')),
                Text('$completedSteps / $requiredSteps',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progress, minHeight: 7),
            ],
          ],
          if (sync == DepartmentSyncState.waitingToUpload ||
              sync == DepartmentSyncState.failed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(sync == DepartmentSyncState.waitingToUpload
                  ? 'Some entries are waiting to sync.'
                  : 'Department sync needs attention.'),
            ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text('Needs attention',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
            if (inbox.actionCount > 0)
              Text('${inbox.actionCount}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          if (urgent.isEmpty && actions.isEmpty && _departmentError == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No overdue, returned or pending department actions.'),
            )
          else ...[
            ...urgent.take(2).map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.assignment_late_outlined),
              title: Text(item.taskBookTitle, maxLines: 1,
                overflow: TextOverflow.ellipsis),
              subtitle: const Text('Overdue or returned assignment'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go(AppRoutes.department),
            )),
            if (urgent.length < 2)
              ...actions.take(2 - urgent.length).map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(item.title, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                subtitle: Text(item.subtitle, maxLines: 2,
                  overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go(AppRoutes.department),
              )),
          ],
        ],
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onAction;
  final Widget? trailing;
  final List<Widget> children;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onAction,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900)),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
                ],
              )),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 12),
            ...children,
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(action),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String value;
  final String label;
  final bool alert;
  const _OverviewMetric({required this.value, required this.label, this.alert = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(children: [
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: alert ? theme.colorScheme.error : theme.colorScheme.onSurface,
        )),
        Text(label, textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onSettings;

  const _Header({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FirefighterRoadmapWordmark(),
              const SizedBox(height: 4),
              Text(
                'Know where you are. Know what comes next.',
                style: t.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
          ),
          child: IconButton(
            tooltip: 'Settings and profile',
            onPressed: onSettings,
            icon: Icon(Icons.settings_outlined, color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}

