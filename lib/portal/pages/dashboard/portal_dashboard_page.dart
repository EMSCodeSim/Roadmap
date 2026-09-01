import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/portal/models/assignment_models.dart';
import 'package:firepath/portal/models/credential.dart';
import 'package:firepath/portal/models/task_book_template.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/portal/widgets/portal_stat_card.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/status_pill.dart';

class PortalDashboardPage extends StatelessWidget {
  const PortalDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;

    final members = portal.departmentMembers;
    final templates = portal.templatesForDept.where((t) => t.status != TaskBookTemplateStatus.archived).toList();
    final pending = portal.pendingSignOffCount();

    final deptId = portal.activeDepartmentId;
    final assignments = deptId == null
        ? const []
        : portal.db.assignments.where((a) => a.departmentId == deptId).toList();

    int expiringSoon = 0;
    int expired = 0;
    final now = DateTime.now();
    for (final c in portal.db.credentials.where((c) => c.departmentId == deptId)) {
      final exp = c.expirationDate;
      if (exp == null) continue;
      final days = exp.difference(now).inDays;
      if (days < 0) expired++;
      else if (days <= 60) expiringSoon++;
    }

    int overdueReqs = 0;
    for (final a in assignments) {
      if (a.dueDate == null) continue;
      if (a.dueDate!.isBefore(now) && a.status != AssignmentStatus.complete) overdueReqs++;
    }

    final activity = portal.db.activity.where((e) => e.departmentId == deptId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return PortalPageScaffold(
      title: 'Dashboard',
      subtitle: 'What needs your attention today?',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('${AppRoutes.portal}/signoffs'),
          icon: Icon(Icons.fact_check, color: cs.onSurface),
          label: Text('Review sign-offs', style: TextStyle(color: cs.onSurface)),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth >= 1180 ? 5 : (constraints.maxWidth >= 920 ? 3 : 1);
          return SingleChildScrollView(
            child: Column(
              children: [
                GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: cols == 1 ? 3.2 : 2.2,
                  children: [
                    PortalStatCard(
                      icon: Icons.groups,
                      label: 'Active Members',
                      value: '${members.where((m) => m.isActive).length}',
                      tone: cs.secondary,
                      onTap: () => context.go('${AppRoutes.portal}/members'),
                    ),
                    PortalStatCard(
                      icon: Icons.menu_book,
                      label: 'Active Task Books',
                      value: '${templates.where((t) => t.status == TaskBookTemplateStatus.active).length}',
                      tone: cs.primary,
                      onTap: () => context.go('${AppRoutes.portal}/task-books'),
                    ),
                    PortalStatCard(
                      icon: Icons.fact_check,
                      label: 'Awaiting Sign-Off',
                      value: '$pending',
                      tone: FireOpsSemanticColors.expiring,
                      onTap: () => context.go('${AppRoutes.portal}/signoffs'),
                    ),
                    PortalStatCard(
                      icon: Icons.verified,
                      label: 'Certs Expiring Soon',
                      value: '$expiringSoon',
                      tone: FireOpsSemanticColors.warning,
                      onTap: () => context.go('${AppRoutes.portal}/certifications'),
                    ),
                    PortalStatCard(
                      icon: Icons.warning_amber,
                      label: 'Overdue Assignments',
                      value: '$overdueReqs',
                      tone: FireOpsSemanticColors.expired,
                      onTap: () => context.go('${AppRoutes.portal}/assignments'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _TwoPane(
                  left: _NeedsAttentionPanel(expiringSoon: expiringSoon, pending: pending, overdue: overdueReqs, expired: expired),
                  right: _RecentActivityPanel(activity: activity.take(8).toList()),
                ),
                const SizedBox(height: AppSpacing.lg),
                _TaskBookProgressPanel(templates: templates),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TwoPane extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _TwoPane({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final split = constraints.maxWidth >= 1020;
        if (!split) {
          return Column(
            children: [left, const SizedBox(height: AppSpacing.md), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: left), const SizedBox(width: AppSpacing.md), Expanded(child: right)],
        );
      },
    );
  }
}

class _NeedsAttentionPanel extends StatelessWidget {
  final int expiringSoon;
  final int pending;
  final int overdue;
  final int expired;
  const _NeedsAttentionPanel({required this.expiringSoon, required this.pending, required this.overdue, required this.expired});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <_AttentionItem>[
      if (expiringSoon > 0)
        _AttentionItem(
          icon: Icons.verified,
          text: '$expiringSoon certifications expire within 60 days',
          color: FireOpsSemanticColors.expiring,
        ),
      if (pending > 0)
        _AttentionItem(
          icon: Icons.fact_check,
          text: '$pending Task Book requirements awaiting evaluator approval',
          color: FireOpsSemanticColors.expiring,
        ),
      if (overdue > 0)
        _AttentionItem(
          icon: Icons.warning_amber,
          text: '$overdue Task Book assignments are overdue',
          color: FireOpsSemanticColors.expired,
        ),
      if (expired > 0)
        _AttentionItem(
          icon: Icons.error_outline,
          text: '$expired credentials are expired',
          color: FireOpsSemanticColors.expired,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Needs Attention', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text('All clear. No urgent items right now.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
            else
              ...items.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: e.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: e.color.withValues(alpha: 0.22)),
                          ),
                          child: Icon(e.icon, size: 18, color: e.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35))),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _AttentionItem {
  final IconData icon;
  final String text;
  final Color color;
  const _AttentionItem({required this.icon, required this.text, required this.color});
}

class _TaskBookProgressPanel extends StatelessWidget {
  final List<TaskBookTemplate> templates;
  const _TaskBookProgressPanel({required this.templates});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final deptId = portal.activeDepartmentId;
    final assignments = deptId == null
        ? const <TaskBookAssignment>[]
        : portal.db.assignments.where((a) => a.departmentId == deptId).toList();

    List<_TaskBookRow> rows() {
      final out = <_TaskBookRow>[];
      for (final t in templates.take(6)) {
        final version = portal.publishedVersionForTemplate(t.id);
        if (version == null) continue;
        final my = assignments.where((a) => a.taskBookVersionId == version.id).toList();
        final assigned = my.length;
        final avg = assigned == 0 ? 0.0 : (my.map(portal.progressForAssignment).reduce((a, b) => a + b) / assigned);
        final complete = my.where((a) => portal.progressForAssignment(a) >= 0.999).length;
        final pending = my
            .map((a) => portal.db.completions.where((c) => c.assignmentId == a.id && c.status == CompletionStatus.submitted).length)
            .fold<int>(0, (a, b) => a + b);
        out.add(_TaskBookRow(title: t.title, version: version.version, assigned: assigned, avgProgress: avg, complete: complete, pending: pending));
      }
      return out;
    }

    final data = rows();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Task Book Progress', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                TextButton(
                  onPressed: () => context.go('${AppRoutes.portal}/task-books'),
                  child: Text('View library', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (data.isEmpty)
              Text('No active Task Books yet.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  columns: const [
                    DataColumn(label: Text('Task Book')),
                    DataColumn(label: Text('Version')),
                    DataColumn(label: Text('Assigned')),
                    DataColumn(label: Text('Avg progress')),
                    DataColumn(label: Text('Complete')),
                    DataColumn(label: Text('Pending')),
                  ],
                  rows: data
                      .map(
                        (r) => DataRow(cells: [
                          DataCell(Text(r.title)),
                          DataCell(StatusPill(text: 'v${r.version}', icon: Icons.sell_outlined)),
                          DataCell(Text('${r.assigned}')),
                          DataCell(Text('${(r.avgProgress * 100).round()}%')),
                          DataCell(Text('${r.complete}')),
                          DataCell(Text('${r.pending}')),
                        ]),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskBookRow {
  final String title;
  final String version;
  final int assigned;
  final double avgProgress;
  final int complete;
  final int pending;
  const _TaskBookRow({required this.title, required this.version, required this.assigned, required this.avgProgress, required this.complete, required this.pending});
}

class _RecentActivityPanel extends StatelessWidget {
  final List activity;
  const _RecentActivityPanel({required this.activity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (activity.isEmpty)
              Text('No recent activity.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
            else
              ...activity.map((e) {
                final meta = (e.metadata as Map<String, dynamic>);
                final msg = _formatActivity(e.type, meta);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.bolt, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(child: Text(msg, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35))),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatActivity(String type, Map<String, dynamic> meta) {
    return switch (type) {
      'requirement.completed' => '${meta['member'] ?? ''} completed ${meta['requirement'] ?? 'a requirement'}',
      'credential.uploaded' => '${meta['action'] ?? 'Credential updated'} (${meta['credential'] ?? ''})',
      'signoff.approved' => '${meta['member'] ?? ''} sign-off approved: ${meta['requirement'] ?? ''}',
      'assignment.created' => 'Task Book assigned: ${meta['taskBook'] ?? ''} to ${meta['member'] ?? ''}',
      _ => type,
    };
  }
}
