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
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/section_header.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final department = context.watch<DepartmentInboxController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Profiles in this app are intentionally minimal; we greet generically unless
    // a name field is added in the future.
    const firstName = 'Responder';
    final role = app.profile.currentRoles.isEmpty ? null : app.profile.currentRoles.first;

    return Scaffold(
      appBar: AppBar(
        title: FirefighterRoadmapWordmark(
          iconSize: 24,
          textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go(AppRoutes.profile),
            icon: const Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _HomeHeader(
              firstName: firstName,
              role: role,
              departmentBadgeCount: department.actionCount,
              onNotificationsTap: () => context.go(AppRoutes.department),
            ),
            const SizedBox(height: 14),
            _PersonalProgressCard(app: app),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Quick actions'),
            const SizedBox(height: 10),
            const _HomeQuickActionGrid(),
            const SizedBox(height: 18),
            _HomeOverview(app: app, department: department),
            if (department.actionCount > 0) ...[
              const SizedBox(height: 16),
              _DepartmentUpdatesCompactCard(controller: department),
            ],
            const SizedBox(height: 12),
            Text(
              'Tip: Use Quick Add (+) any time to capture training fast.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String firstName;
  final String? role;
  final int departmentBadgeCount;
  final VoidCallback onNotificationsTap;

  const _HomeHeader({
    required this.firstName,
    required this.role,
    required this.departmentBadgeCount,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $firstName',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                role ?? 'Your personal dashboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Updates',
          onPressed: onNotificationsTap,
          icon: Badge(
            isLabelVisible: departmentBadgeCount > 0,
            label: Text(departmentBadgeCount > 99 ? '99+' : '$departmentBadgeCount'),
            child: Icon(Icons.notifications_none_rounded, color: cs.primary),
          ),
        ),
      ],
    );
  }
}

class _PersonalProgressCard extends StatelessWidget {
  final AppState app;
  const _PersonalProgressCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final roadmap = app.roadmap;
    final goal = roadmap?.goal.title ?? 'Choose your career goal';
    final progress = roadmap == null ? null : (roadmap.percentComplete * 100).round().clamp(0, 100);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FireOpsFeatureColors.roadmap.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.route_rounded, color: FireOpsFeatureColors.roadmap),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personal Progress',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(goal,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (progress != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$progress%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            if (roadmap != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${roadmap.completedCount} of ${roadmap.totalCount} complete',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  if (roadmap.nextStep?.requirement.name != null)
                    Text('Next: ${roadmap.nextStep!.requirement.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (progress! / 100).clamp(0.0, 1.0),
                minHeight: 7,
                borderRadius: BorderRadius.circular(999),
                color: FireOpsSemanticColors.green,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.myPath),
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: Text(
                roadmap == null ? 'Start My Roadmap' : 'Continue',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeQuickActionGrid extends StatelessWidget {
  const _HomeQuickActionGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 520 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.10,
          children: const [
            _HomeQuickActionTile(
              color: FireOpsFeatureColors.roadmap,
              icon: Icons.route_rounded,
              label: 'My Roadmap',
              destination: AppRoutes.myPath,
              useGo: true,
            ),
            _HomeQuickActionTile(
              color: FireOpsFeatureColors.training,
              icon: Icons.school_rounded,
              label: 'My Training',
              destination: AppRoutes.training,
              useGo: true,
            ),
            _HomeQuickActionTile(
              color: FireOpsFeatureColors.qualifications,
              icon: Icons.verified_rounded,
              label: 'My Qualifications',
              destination: AppRoutes.certifications,
              useGo: false,
            ),
            _HomeQuickActionTile(
              color: FireOpsFeatureColors.certificates,
              icon: Icons.workspace_premium_rounded,
              label: 'My Certificates',
              destination: AppRoutes.certifications,
              useGo: false,
            ),
          ],
        );
      },
    );
  }
}

class _HomeQuickActionTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String destination;
  final bool useGo;

  const _HomeQuickActionTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.destination,
    required this.useGo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.10)),
      ),
      child: InkWell(
        onTap: () => useGo ? context.go(destination) : context.push(destination),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentUpdatesCompactCard extends StatelessWidget {
  final DepartmentInboxController controller;
  const _DepartmentUpdatesCompactCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.apartment_rounded, color: cs.onPrimaryContainer),
        ),
        title: Text('Department Updates', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
        subtitle: Text(
          controller.actionCount == 1 ? '1 item needs attention' : '${controller.actionCount} items need attention',
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.go(AppRoutes.department),
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
  bool _personalRecordsAvailable = false;
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
        _personalRecordsAvailable = true;
        _loadingPersonal = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _personalRecordsAvailable = false;
        _loadingPersonal = false;
      });
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

    return _ExpandableSummaryCard(
      color: FireOpsFeatureColors.training,
      icon: Icons.person_rounded,
      title: 'My activity',
      summary: '${roadmap?.missing.length ?? 0} roadmap items remaining • $credentialNeeds credential needs',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              value: _loadingPersonal || !_personalRecordsAvailable ? '—' : '${_records.length}',
              label: 'Records logged',
            )),
          ]),
          const SizedBox(height: 12),
          Text('Needs attention',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          if (_loadingPersonal)
            const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator())
          else if (!_personalRecordsAvailable)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Personal records could not be loaded.'))
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
              onTap: () => context.push(item.certificationId != null ||
                      item.kind == NeedsAttentionKind.certificationMatch
                  ? AppRoutes.certifications : AppRoutes.myPathLegacy),
            )),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go(AppRoutes.training),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Review training'),
            ),
          ),
        ],
      ),
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

    if (!_connected && !_loadingDepartment) {
      return _ExpandableSummaryCard(
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.apartment_rounded,
        title: 'Department updates',
        summary: 'Not connected',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Connect to your department to see assignments and approvals.'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.go(AppRoutes.department),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Open Department'),
              ),
            ),
          ],
        ),
      );
    }

    return _ExpandableSummaryCard(
      color: Theme.of(context).colorScheme.primary,
      icon: Icons.apartment_rounded,
      title: 'Department updates',
      summary: assignments == null
          ? (_loadingDepartment ? 'Refreshing…' : 'No assignment data')
          : '${assignments.length} assigned • $waiting awaiting sign-off',
      trailing: IconButton(
        tooltip: 'Refresh',
        onPressed: _loadingDepartment
            ? null
            : () {
                _refresh();
                inbox.refresh(silent: true);
              },
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_departmentError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _departmentError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_loadingDepartment && assignments == null)
            const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator())
          else if (assignments != null) ...[
            Row(children: [
              Expanded(child: _OverviewMetric(value: '${assignments.length}', label: 'Assigned')),
              Expanded(child: _OverviewMetric(value: '$done', label: '100% progress')),
              Expanded(child: _OverviewMetric(value: '$waiting', label: 'Awaiting sign-off', alert: waiting > 0)),
            ]),
            if (progress != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Text('Required steps completed')),
                Text('$completedSteps / $requiredSteps', style: const TextStyle(fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progress, minHeight: 7, borderRadius: BorderRadius.circular(999)),
            ],
          ],
          if (sync == DepartmentSyncState.waitingToUpload || sync == DepartmentSyncState.failed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                sync == DepartmentSyncState.waitingToUpload
                    ? 'Some entries are waiting to sync.'
                    : 'Department sync needs attention.',
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go(AppRoutes.department),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Open Department'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSummaryCard extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String summary;
  final Widget child;
  final Widget? trailing;

  const _ExpandableSummaryCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.summary,
    required this.child,
    this.trailing,
  });

  @override
  State<_ExpandableSummaryCard> createState() => _ExpandableSummaryCardState();
}

class _ExpandableSummaryCardState extends State<_ExpandableSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: AnimatedSize(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(widget.icon, color: widget.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.summary,
                              maxLines: _expanded ? 3 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (widget.trailing != null) widget.trailing!,
                      const SizedBox(width: 6),
                      Icon(
                        _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                widget.child,
              ],
            ],
          ),
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

