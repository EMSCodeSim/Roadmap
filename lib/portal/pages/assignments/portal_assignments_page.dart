import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/portal/models/assignment_models.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/status_pill.dart';

class PortalAssignmentsPage extends StatelessWidget {
  const PortalAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final deptId = portal.activeDepartmentId;
    final assignments = deptId == null ? const <TaskBookAssignment>[] : portal.db.assignments.where((a) => a.departmentId == deptId).toList();
    assignments.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));

    return PortalPageScaffold(
      title: 'Assignments',
      subtitle: 'Monitor Task Book assignments, progress, and upcoming due dates.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('${AppRoutes.portal}/signoffs'),
          icon: Icon(Icons.fact_check, color: cs.onSurface),
          label: Text('Pending sign-offs', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800)),
        ),
      ],
      child: Card(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 64,
            columns: const [
              DataColumn(label: Text('Member')),
              DataColumn(label: Text('Task Book')),
              DataColumn(label: Text('Progress')),
              DataColumn(label: Text('Pending')),
              DataColumn(label: Text('Due Date')),
              DataColumn(label: Text('Days Remaining')),
              DataColumn(label: Text('Status')),
            ],
            rows: assignments.map((a) {
              final member = portal.db.users.cast().firstWhere((u) => u.id == a.memberId, orElse: () => null);
              final progress = portal.progressForAssignment(a);
              final pending = portal.db.completions.where((c) => c.assignmentId == a.id && c.status == CompletionStatus.submitted).length;
              final due = a.dueDate;
              final days = due == null ? null : due.difference(DateTime.now()).inDays;
              final status = _statusFor(a, progress, pending);
              final tone = _toneFor(status);
              return DataRow(
                onSelectChanged: (_) => context.go('${AppRoutes.portal}/members/${a.memberId}'),
                cells: [
                  DataCell(Text(member?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w900))),
                  DataCell(Text(_taskBookTitle(portal, a), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  DataCell(Text('${(progress * 100).round()}%')),
                  DataCell(Text('$pending')),
                  DataCell(Text(due == null ? '—' : '${due.month}/${due.day}/${due.year}')),
                  DataCell(Text(days == null ? '—' : (days < 0 ? '${days.abs()} overdue' : '$days'))),
                  DataCell(StatusPill(text: status.label, icon: Icons.circle, backgroundColor: tone.withValues(alpha: 0.10), foregroundColor: tone, maxWidth: 200)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _taskBookTitle(PortalController portal, TaskBookAssignment a) {
    final v = portal.db.taskBookVersions.firstWhere((v) => v.id == a.taskBookVersionId);
    final t = portal.db.taskBookTemplates.firstWhere((t) => t.id == v.templateId);
    return '${t.title} v${v.version}';
  }

  AssignmentStatus _statusFor(TaskBookAssignment a, double progress, int pending) {
    final due = a.dueDate;
    if (progress >= 0.999) return AssignmentStatus.complete;
    if (due != null && due.isBefore(DateTime.now())) return AssignmentStatus.overdue;
    if (pending > 0) return AssignmentStatus.awaitingSignOff;
    if (progress <= 0.01) return AssignmentStatus.notStarted;
    return AssignmentStatus.inProgress;
  }

  Color _toneFor(AssignmentStatus s) {
    return switch (s) {
      AssignmentStatus.complete => FireOpsSemanticColors.complete,
      AssignmentStatus.awaitingSignOff => FireOpsSemanticColors.expiring,
      AssignmentStatus.overdue => FireOpsSemanticColors.expired,
      AssignmentStatus.inProgress => FireOpsSemanticColors.current,
      AssignmentStatus.notStarted => Colors.grey,
    };
  }
}
