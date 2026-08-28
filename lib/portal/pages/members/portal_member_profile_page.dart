import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/portal/models/assignment_models.dart';
import 'package:firepath/portal/models/credential.dart';
import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/models/task_book_template.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/status_pill.dart';

class PortalMemberProfilePage extends StatelessWidget {
  final String memberId;
  const PortalMemberProfilePage({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final member = portal.db.users.cast<PortalUser?>().firstWhere((u) => u?.id == memberId, orElse: () => null);
    if (member == null) {
      return const Scaffold(body: Center(child: Text('Member not found')));
    }

    return DefaultTabController(
      length: 6,
      child: PortalPageScaffold(
        title: member.name,
        subtitle: '${member.rank ?? 'Member'} • ${member.station ?? '—'} • Shift ${member.shift ?? '—'}',
        actions: [
          FilledButton.icon(
            onPressed: portal.hasRole(PortalRole.trainingOfficer) ? () => _showAssignDialog(context, member) : null,
            icon: const Icon(Icons.add),
            label: const Text('Assign Task Book'),
          ),
        ],
        child: Column(
          children: [
            const _MemberTabs(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: TabBarView(
                children: [
                  _MemberOverview(memberId: memberId),
                  _MemberTaskBooks(memberId: memberId),
                  _MemberCertifications(memberId: memberId),
                  _MemberActivity(memberId: memberId),
                  _MemberEvidence(memberId: memberId),
                  _MemberNotes(memberId: memberId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignDialog(BuildContext context, PortalUser member) async {
    final portal = context.read<PortalController>();
    final cs = Theme.of(context).colorScheme;

    final templates = portal.templatesForDept.where((t) => t.status != TaskBookTemplateStatus.archived).toList();
    String? selectedTemplateId = templates.isEmpty ? null : templates.first.id;
    DateTime? dueDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Task Book'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedTemplateId,
                  items: templates
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.title)))
                      .toList(),
                  onChanged: (v) => selectedTemplateId = v,
                  decoration: const InputDecoration(labelText: 'Task Book'),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) {
                            dueDate = DateTime(picked.year, picked.month, picked.day);
                            (context as Element).markNeedsBuild();
                          }
                        },
                        icon: Icon(Icons.event, color: cs.onSurface),
                        label: Text(dueDate == null ? 'Set due date (optional)' : 'Due: ${_shortDate(dueDate!)}', style: TextStyle(color: cs.onSurface)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: selectedTemplateId == null
                  ? null
                  : () async {
                      try {
                        await portal.assignTaskBook(
                          templateId: selectedTemplateId!,
                          memberId: member.id,
                          dueDate: dueDate,
                        );
                        Navigator.of(context).pop();
                        if (context.mounted) context.go('${AppRoutes.portal}/members/${member.id}');
                      } catch (_) {
                        Navigator.of(context).pop();
                      }
                    },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  static String _shortDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';
}

class _MemberTabs extends StatelessWidget {
  const _MemberTabs();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: TabBar(
        dividerColor: cs.outline.withValues(alpha: 0.14),
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Task Books'),
          Tab(text: 'Certifications'),
          Tab(text: 'Activity'),
          Tab(text: 'Evidence'),
          Tab(text: 'Notes'),
        ],
      ),
    );
  }
}

class _MemberOverview extends StatelessWidget {
  final String memberId;
  const _MemberOverview({required this.memberId});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final assignments = portal.assignmentsForMember(memberId);
    final creds = portal.db.credentials.where((c) => c.memberId == memberId).toList()
      ..sort((a, b) => (a.expirationDate ?? DateTime(3000)).compareTo(b.expirationDate ?? DateTime(3000)));
    final activity = portal.db.activity.where((a) => a.userId == memberId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return SingleChildScrollView(
      child: Column(
        children: [
          _SectionCard(
            title: 'Current Task Books',
            child: Column(
              children: [
                if (assignments.isEmpty)
                  Text('No active assignments.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
                else
                  ...assignments.map((a) {
                    final progress = portal.progressForAssignment(a);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_assignmentTitle(portal, a), style: const TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: cs.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation(cs.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          StatusPill(
                            text: '${(progress * 100).round()}%',
                            icon: Icons.percent,
                            backgroundColor: cs.surfaceContainerHighest,
                            foregroundColor: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Certification Snapshot',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: creds.map((c) {
                final tone = _credTone(c);
                return StatusPill(
                  text: _credLabel(c),
                  icon: Icons.verified,
                  backgroundColor: tone.withValues(alpha: 0.10),
                  foregroundColor: tone,
                  maxWidth: 260,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Recent Activity',
            child: Column(
              children: [
                if (activity.isEmpty)
                  Text('No recent activity.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
                else
                  ...activity.take(10).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.bolt, size: 18, color: cs.onSurfaceVariant),
                            const SizedBox(width: 10),
                            Expanded(child: Text('${e.type} • ${_shortDateTime(e.timestamp)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35))),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _credTone(Credential c) {
    final exp = c.expirationDate;
    if (exp == null) return Colors.grey;
    final days = exp.difference(DateTime.now()).inDays;
    if (days < 0) return FireOpsSemanticColors.expired;
    if (days <= 60) return FireOpsSemanticColors.expiring;
    return FireOpsSemanticColors.current;
  }

  String _credLabel(Credential c) {
    final exp = c.expirationDate;
    if (exp == null) return '${c.credentialName} — Current';
    final days = exp.difference(DateTime.now()).inDays;
    if (days < 0) return '${c.credentialName} — Expired';
    if (days <= 60) return '${c.credentialName} — Expires in $days days';
    return '${c.credentialName} — Current';
  }

  String _assignmentTitle(PortalController portal, TaskBookAssignment a) {
    final version = portal.db.taskBookVersions.firstWhere((v) => v.id == a.taskBookVersionId);
    final template = portal.db.taskBookTemplates.firstWhere((t) => t.id == version.templateId);
    return '${template.title} — ${_progressLabel(portal, a)}';
  }

  String _progressLabel(PortalController portal, TaskBookAssignment a) => '${(portal.progressForAssignment(a) * 100).round()}%';

  String _shortDateTime(DateTime dt) => '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _MemberTaskBooks extends StatelessWidget {
  final String memberId;
  const _MemberTaskBooks({required this.memberId});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final assignments = portal.assignmentsForMember(memberId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assignments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (assignments.isEmpty)
              Text('No Task Books assigned.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: assignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final a = assignments[index];
                    final progress = portal.progressForAssignment(a);
                    final pending = portal.db.completions.where((c) => c.assignmentId == a.id && c.status == CompletionStatus.submitted).length;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_titleFor(portal, a), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: cs.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation(cs.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      StatusPill(text: '${(progress * 100).round()}% complete', icon: Icons.percent),
                                      StatusPill(text: '$pending pending approval', icon: Icons.fact_check_outlined),
                                      if (a.dueDate != null) StatusPill(text: 'Due ${a.dueDate!.month}/${a.dueDate!.day}', icon: Icons.event),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () => context.go('${AppRoutes.portal}/signoffs'),
                              icon: Icon(Icons.fact_check, color: cs.onSurface),
                              label: Text('View sign-offs', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _titleFor(PortalController portal, TaskBookAssignment a) {
    final version = portal.db.taskBookVersions.firstWhere((v) => v.id == a.taskBookVersionId);
    final template = portal.db.taskBookTemplates.firstWhere((t) => t.id == version.templateId);
    return '${template.title} v${version.version}';
  }
}

class _MemberCertifications extends StatelessWidget {
  final String memberId;
  const _MemberCertifications({required this.memberId});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final creds = portal.db.credentials.where((c) => c.memberId == memberId).toList();
    creds.sort((a, b) => (a.expirationDate ?? DateTime(3000)).compareTo(b.expirationDate ?? DateTime(3000)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Credentials', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (creds.isEmpty)
              Text('No credentials on file.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: creds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final c = creds[i];
                    final tone = _toneFor(c);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: tone.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: tone.withValues(alpha: 0.22)),
                              ),
                              child: Icon(Icons.verified, color: tone),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.credentialName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text('${c.issuer} • ${c.verificationStatus.label}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            StatusPill(
                              text: _expiryLabel(c),
                              backgroundColor: tone.withValues(alpha: 0.10),
                              foregroundColor: tone,
                              icon: Icons.event,
                              maxWidth: 220,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _toneFor(Credential c) {
    final exp = c.expirationDate;
    if (exp == null) return Colors.grey;
    final days = exp.difference(DateTime.now()).inDays;
    if (days < 0) return FireOpsSemanticColors.expired;
    if (days <= 60) return FireOpsSemanticColors.expiring;
    return FireOpsSemanticColors.current;
  }

  String _expiryLabel(Credential c) {
    final exp = c.expirationDate;
    if (exp == null) return 'Current';
    final days = exp.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days <= 60) return 'Expires in $days days';
    return 'Current';
  }
}

class _MemberActivity extends StatelessWidget {
  final String memberId;
  const _MemberActivity({required this.memberId});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final activity = portal.db.activity.where((a) => a.userId == memberId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (activity.isEmpty)
              Text('No activity recorded yet.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: activity.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: cs.outline.withValues(alpha: 0.10)),
                  itemBuilder: (context, i) {
                    final e = activity[i];
                    return ListTile(
                      leading: Icon(Icons.bolt, color: cs.onSurfaceVariant),
                      title: Text(e.type, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${e.timestamp.month}/${e.timestamp.day}/${e.timestamp.year}'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberEvidence extends StatelessWidget {
  final String memberId;
  const _MemberEvidence({required this.memberId});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final assignmentIds = portal.assignmentsForMember(memberId).map((e) => e.id).toSet();
    final completionIds = portal.db.completions.where((c) => assignmentIds.contains(c.assignmentId)).map((c) => c.id).toSet();
    final items = portal.db.evidence.where((e) => completionIds.contains(e.completionId)).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evidence', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text('No evidence uploaded yet.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.attachment, color: cs.onSurfaceVariant),
                        title: Text(e.type, style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text(e.description.isEmpty ? '—' : e.description),
                        trailing: Text('${e.uploadedAt.month}/${e.uploadedAt.day}', style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberNotes extends StatelessWidget {
  final String memberId;
  const _MemberNotes({required this.memberId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text('Notes are stored per-department and do not modify the member\'s personal career record.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              maxLines: 8,
              decoration: const InputDecoration(hintText: 'Add training officer notes…'),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.save),
                label: const Text('Save (coming soon)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
