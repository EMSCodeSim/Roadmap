import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/models/task_book_template.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/status_pill.dart';

class PortalTaskBooksPage extends StatelessWidget {
  const PortalTaskBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final templates = portal.templatesForDept;

    return PortalPageScaffold(
      title: 'Task Books',
      subtitle: 'Create reusable department templates, publish versions, and assign to members.',
      actions: [
        FilledButton.icon(
          onPressed: portal.hasRole(PortalRole.trainingOfficer)
              ? () async {
                  await _showCreate(context);
                }
              : null,
          icon: const Icon(Icons.add),
          label: const Text('New Task Book'),
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
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Version')),
              DataColumn(label: Text('Assigned')),
              DataColumn(label: Text('Last updated')),
              DataColumn(label: Text('Owner')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('')),
            ],
            rows: templates.map((t) {
              final version = portal.publishedVersionForTemplate(t.id);
              final assigned = version == null
                  ? 0
                  : portal.db.assignments.where((a) => a.taskBookVersionId == version.id).length;
              final owner = portal.db.users.cast().firstWhere((u) => u.id == t.ownerUserId, orElse: () => null);
              final statusTone = switch (t.status) {
                TaskBookTemplateStatus.draft => FireOpsSemanticColors.expiring,
                TaskBookTemplateStatus.active => FireOpsSemanticColors.complete,
                TaskBookTemplateStatus.archived => cs.onSurfaceVariant,
              };
              return DataRow(
                onSelectChanged: (_) => context.go('${AppRoutes.portal}/task-books/${t.id}'),
                cells: [
                  DataCell(Text(t.title, style: const TextStyle(fontWeight: FontWeight.w900))),
                  DataCell(Text(t.category)),
                  DataCell(Text(version == null ? '—' : 'v${version.version}')),
                  DataCell(Text('$assigned')),
                  DataCell(Text('${t.updatedAt.month}/${t.updatedAt.day}/${t.updatedAt.year}')),
                  DataCell(Text(owner?.name ?? '—')),
                  DataCell(
                    StatusPill(
                      text: t.status.label,
                      icon: Icons.circle,
                      backgroundColor: statusTone.withValues(alpha: 0.10),
                      foregroundColor: statusTone,
                    ),
                  ),
                  DataCell(
                    TextButton(
                      onPressed: () => context.go('${AppRoutes.portal}/task-books/${t.id}'),
                      child: Text('Open', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreate(BuildContext context) async {
    final portal = context.read<PortalController>();
    final title = TextEditingController(text: 'Probationary Firefighter');
    final category = TextEditingController(text: 'Fire');
    final description = TextEditingController(text: 'Department probationary requirements and core skills sign-off.');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Task Book'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  final id = await portal.createBlankTaskBook(
                    title: title.text.trim().isEmpty ? 'Untitled Task Book' : title.text.trim(),
                    category: category.text.trim().isEmpty ? 'General' : category.text.trim(),
                    description: description.text.trim(),
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  context.go('${AppRoutes.portal}/task-books/$id');
                } catch (e) {
                  debugPrint('Create task book failed: $e');
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
