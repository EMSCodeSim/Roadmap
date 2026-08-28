import 'package:firepath/portal/models/portal_user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/models/task_book_template.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/status_pill.dart';

class PortalTaskBookBuilderPage extends StatefulWidget {
  final String templateId;
  const PortalTaskBookBuilderPage({super.key, required this.templateId});

  @override
  State<PortalTaskBookBuilderPage> createState() => _PortalTaskBookBuilderPageState();
}

class _PortalTaskBookBuilderPageState extends State<PortalTaskBookBuilderPage> {
  String? _selectedVersionId;

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final template = portal.db.taskBookTemplates.cast<TaskBookTemplate?>().firstWhere((t) => t?.id == widget.templateId, orElse: () => null);
    if (template == null) {
      return const Scaffold(body: Center(child: Text('Task Book not found')));
    }

    final versions = portal.db.taskBookVersions.where((v) => v.templateId == template.id).toList()
      ..sort((a, b) => b.version.compareTo(a.version));
    final draft = versions.where((v) => !v.isPublished).cast<TaskBookVersion?>().firstWhere((e) => true, orElse: () => null);
    final published = portal.publishedVersionForTemplate(template.id);
    _selectedVersionId ??= (draft ?? published ?? (versions.isEmpty ? null : versions.first))?.id;
    final selectedVersion = versions.cast<TaskBookVersion?>().firstWhere((v) => v?.id == _selectedVersionId, orElse: () => versions.first);
    final isDraft = selectedVersion != null && !selectedVersion.isPublished;

    return PortalPageScaffold(
      title: template.title,
      subtitle: template.description,
      actions: [
        _VersionPicker(
          versions: versions,
          value: _selectedVersionId,
          onChanged: (v) => setState(() => _selectedVersionId = v),
        ),
        if (!isDraft)
          FilledButton.icon(
            onPressed: portal.hasRole(PortalRole.trainingOfficer)
                ? () async {
                    try {
                      final newId = await portal.createDraftFromPublished(template.id);
                      setState(() => _selectedVersionId = newId);
                    } catch (_) {}
                  }
                : null,
            icon: const Icon(Icons.fork_right),
            label: const Text('New draft'),
          ),
        FilledButton.icon(
          onPressed: (isDraft && portal.hasRole(PortalRole.trainingOfficer))
              ? () async {
                  await portal.publishTemplate(template.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Published. Existing assignments remain tied to their version.')));
                }
              : null,
          icon: const Icon(Icons.publish),
          label: const Text('Publish'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final split = constraints.maxWidth >= 1100;
          final editor = _BuilderEditor(version: selectedVersion!, readOnly: !isDraft);
          final meta = _BuilderMeta(template: template, version: selectedVersion, readOnly: !isDraft);
          if (!split) {
            return ListView(
              children: [
                meta,
                const SizedBox(height: AppSpacing.md),
                editor,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 360, child: meta),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: editor),
            ],
          );
        },
      ),
    );
  }
}

class _VersionPicker extends StatelessWidget {
  final List<TaskBookVersion> versions;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _VersionPicker({required this.versions, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(labelText: 'Version'),
        items: versions
            .map(
              (v) => DropdownMenuItem(
                value: v.id,
                child: Text(v.isPublished ? 'v${v.version} (published)' : 'v${v.version} (draft)'),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _BuilderMeta extends StatelessWidget {
  final TaskBookTemplate template;
  final TaskBookVersion version;
  final bool readOnly;
  const _BuilderMeta({required this.template, required this.version, required this.readOnly});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final owner = portal.db.users.cast().firstWhere((u) => u.id == template.ownerUserId, orElse: () => null);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Book', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(template.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                StatusPill(
                  text: version.isPublished ? 'Published' : 'Draft',
                  icon: version.isPublished ? Icons.verified : Icons.edit,
                  backgroundColor: (version.isPublished ? FireOpsSemanticColors.complete : FireOpsSemanticColors.expiring).withValues(alpha: 0.10),
                  foregroundColor: version.isPublished ? FireOpsSemanticColors.complete : FireOpsSemanticColors.expiring,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(template.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StatusPill(text: template.category, icon: Icons.category_outlined),
                StatusPill(text: 'v${version.version}', icon: Icons.sell_outlined),
                StatusPill(text: owner?.name ?? '—', icon: Icons.person_outline, maxWidth: 220),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  version.isPublished
                      ? 'Published versions are read-only. Create a new draft to make changes. Assignments stay tied to the version they were assigned.'
                      : 'Draft mode. Add sections and requirements, reorder them, then publish when ready.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuilderEditor extends StatelessWidget {
  final TaskBookVersion version;
  final bool readOnly;
  const _BuilderEditor({required this.version, required this.readOnly});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final sections = portal.sectionsForVersion(version.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Sections', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                FilledButton.icon(
                  onPressed: readOnly
                      ? null
                      : () async {
                          final title = await _prompt(context, title: 'Add section', label: 'Section title');
                          if (title == null) return;
                          await portal.addSection(versionId: version.id, title: title);
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Add section'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (sections.isEmpty)
              Text('No sections yet. Add your first section to start building.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
            else
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: sections.length,
                  onReorder: readOnly
                      ? (_, __) {}
                      : (oldIndex, newIndex) => portal.reorderSections(versionId: version.id, oldIndex: oldIndex, newIndex: newIndex),
                  itemBuilder: (context, index) {
                    final s = sections[index];
                    return _SectionEditor(key: ValueKey(s.id), section: s, index: index, readOnly: readOnly);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _prompt(BuildContext context, {required String title, required String label}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: label), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim().isEmpty ? null : controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
  }
}

class _SectionEditor extends StatelessWidget {
  final TaskBookSection section;
  final int index;
  final bool readOnly;
  const _SectionEditor({super.key, required this.section, required this.index, required this.readOnly});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final reqs = portal.requirementsForSection(section.id);

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ReorderableDragStartListener(
                    enabled: !readOnly,
                    index: index,
                    child: Icon(Icons.drag_indicator, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(section.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  ),
                  StatusPill(text: '${reqs.length} reqs', icon: Icons.list_alt, maxWidth: 140),
                ],
              ),
              if (section.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(section.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text('Requirements', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
                  TextButton.icon(
                    onPressed: readOnly
                        ? null
                        : () async {
                            final title = await _prompt(context, title: 'Add requirement', label: 'Requirement title');
                            if (title == null) return;
                            await portal.addRequirement(sectionId: section.id, title: title);
                          },
                    icon: Icon(Icons.add, color: readOnly ? cs.onSurfaceVariant : cs.primary),
                    label: Text('Add', style: TextStyle(color: readOnly ? cs.onSurfaceVariant : cs.primary, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (reqs.isEmpty)
                Text('No requirements in this section yet.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant))
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: reqs.length,
                  onReorder: readOnly
                      ? (_, __) {}
                      : (oldIndex, newIndex) => portal.reorderRequirements(sectionId: section.id, oldIndex: oldIndex, newIndex: newIndex),
                  itemBuilder: (context, index) {
                    final r = reqs[index];
                    return Padding(
                      key: ValueKey(r.id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                          leading: ReorderableDragStartListener(
                            enabled: !readOnly,
                            index: index,
                            child: Icon(Icons.drag_indicator, color: cs.onSurfaceVariant),
                          ),
                          title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text(
                            r.instructions.isEmpty ? '—' : r.instructions,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
                          ),
                          trailing: StatusPill(text: r.evidenceType.label, icon: Icons.attachment, maxWidth: 190),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _prompt(BuildContext context, {required String title, required String label}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: label), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim().isEmpty ? null : controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
  }
}
