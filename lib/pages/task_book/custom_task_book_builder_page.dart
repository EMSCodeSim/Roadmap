import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/custom_task_book.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/widgets/status_pill.dart';

class CustomTaskBookBuilderPage extends StatelessWidget {
  final Object? extra;
  const CustomTaskBookBuilderPage({super.key, required this.extra});

  @override
  Widget build(BuildContext context) {
    final map = extra is Map ? extra as Map : null;
    final id = map?['taskBookId'] as String?;
    if (id == null || id.trim().isEmpty) {
      return const Scaffold(body: Center(child: Text('Task Book not found.')));
    }

    final state = context.watch<AppState>();
    final book = state.customTaskBooks.where((b) => b.id == id).firstOrNull;
    if (book == null) {
      return const Scaffold(body: Center(child: Text('Task Book not found.')));
    }

    return _CustomTaskBookBuilderScaffold(book: book);
  }
}

class _CustomTaskBookBuilderScaffold extends StatefulWidget {
  final CustomTaskBook book;
  const _CustomTaskBookBuilderScaffold({required this.book});

  @override
  State<_CustomTaskBookBuilderScaffold> createState() => _CustomTaskBookBuilderScaffoldState();
}

class _CustomTaskBookBuilderScaffoldState extends State<_CustomTaskBookBuilderScaffold> {
  _BuilderView _view = _BuilderView.sections;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final book = state.customTaskBooks.where((b) => b.id == widget.book.id).firstOrNull ?? widget.book;
    final goalId = book.pseudoGoalId;

    final activeCount = book.requirements.length;
    final completedCount = book.requirements.where((r) {
      final o = state.taskBookController.getOverride(goalId, r.id);
      return (o?.completed ?? r.completed) == true;
    }).length;
    final pct = activeCount == 0 ? 0.0 : (completedCount / activeCount).clamp(0, 1).toDouble();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toTaskBook(),
        title: Text(book.name),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Task Book settings',
            onPressed: () => _showManageSheet(context, book),
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditRequirement(context, book, null, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Requirement'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Department Task Book',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (book.departmentSpecific)
                        StatusPill(text: 'DEPARTMENT', backgroundColor: cs.primaryContainer, foregroundColor: cs.onPrimaryContainer)
                      else
                        StatusPill(text: 'CUSTOM', backgroundColor: cs.surfaceContainerHighest, foregroundColor: cs.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$completedCount / $activeCount complete',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text('${(pct * 100).round()}%', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 10,
                      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap an item to open the actionable plan. Long-press the handle to reorder.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _QuickAddPanel(
              onAdd: (draft) => _showAddOrEditRequirement(context, book, null, draft),
            ),
            const SizedBox(height: AppSpacing.md),
            _ViewToggle(
              value: _view,
              onChanged: (v) => setState(() => _view = v),
            ),
            const SizedBox(height: AppSpacing.md),
            if (book.requirements.isEmpty)
              _EmptyBuilderState(
                onAdd: () => _showAddOrEditRequirement(context, book, null, null),
              )
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _view == _BuilderView.reorder
                    ? _RequirementReorderList(
                        key: const ValueKey('reorder'),
                        requirements: book.requirements,
                        goalId: goalId,
                        onReorder: (oldIndex, newIndex) => _reorder(context, book, oldIndex, newIndex),
                        onTapRequirement: (r) => AppRouter.openRequirement(
                          context,
                          r,
                          goalId: goalId,
                        ),
                        onEditRequirement: (r) => _showAddOrEditRequirement(context, book, r, null),
                        onToggleRequired: (r, requiredFlag) => _toggleRequired(context, book, r, requiredFlag),
                        onDeleteRequirement: (r) => _deleteRequirement(context, book, r),
                      )
                    : _SectionedRequirementList(
                        key: const ValueKey('sections'),
                        requirements: book.requirements,
                        goalId: goalId,
                        onTap: (r) => AppRouter.openRequirement(
                          context,
                          r,
                          goalId: goalId,
                        ),
                        onEdit: (r) => _showAddOrEditRequirement(context, book, r, null),
                        onAddToSection: (section) => _showAddOrEditRequirement(context, book, null, _RequirementDraft(category: section)),
                      ),
              ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Future<void> _reorder(BuildContext context, CustomTaskBook book, int oldIndex, int newIndex) async {
    final list = [...book.requirements];
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex > list.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await context.read<AppState>().taskBookController.updateCustomTaskBook(book.copyWith(requirements: list));
  }

  Future<void> _toggleRequired(BuildContext context, CustomTaskBook book, Requirement r, bool requiredFlag) async {
    final idx = book.requirements.indexWhere((e) => e.id == r.id);
    if (idx < 0) return;
    final next = [...book.requirements];
    next[idx] = r.copyWith(
      requirementSource: requiredFlag ? RequirementSource.departmentRequirement : RequirementSource.recommended,
      priority: requiredFlag ? RequirementPriority.department : RequirementPriority.recommended,
      defaultRequired: requiredFlag,
      updatedAt: DateTime.now(),
    );
    await context.read<AppState>().taskBookController.updateCustomTaskBook(book.copyWith(requirements: next));
  }

  Future<void> _deleteRequirement(BuildContext context, CustomTaskBook book, Requirement r) async {
    final next = book.requirements.where((e) => e.id != r.id).toList();
    await context.read<AppState>().taskBookController.updateCustomTaskBook(book.copyWith(requirements: next));
  }

  Future<void> _showManageSheet(BuildContext context, CustomTaskBook book) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Manage Task Book', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: const Text('Rename'),
                  onTap: () async {
                    context.pop();
                    final next = await _promptRename(context, book.name);
                    if (next == null) return;
                    await context.read<AppState>().taskBookController.renameCustomTaskBook(taskBookId: book.id, name: next);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_all_outlined),
                  title: const Text('Duplicate'),
                  onTap: () async {
                    context.pop();
                    await context.read<AppState>().taskBookController.duplicateCustomTaskBook(book.id);
                  },
                ),
                ListTile(
                  leading: Icon(book.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
                  title: Text(book.archived ? 'Unarchive' : 'Archive'),
                  subtitle: const Text('Archived Task Books stay saved but won’t show by default.'),
                  onTap: () async {
                    context.pop();
                    await context.read<AppState>().taskBookController.archiveCustomTaskBook(taskBookId: book.id, archived: !book.archived);
                    if (mounted) context.go(AppRoutes.myPath);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _promptRename(BuildContext context, String current) async {
    final ctrl = TextEditingController(text: current);
    final next = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Task Book'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => context.pop(ctrl.text.trim()), child: const Text('Save')),
          ],
        );
      },
    );
    ctrl.dispose();
    return next?.trim().isEmpty == true ? null : next;
  }

  Future<void> _showAddOrEditRequirement(BuildContext context, CustomTaskBook book, Requirement? existing, _RequirementDraft? prefill) async {
    final result = await showModalBottomSheet<Requirement>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RequirementEditorSheet(book: book, existing: existing, prefill: prefill),
    );
    if (result == null) return;
    final next = [...book.requirements];
    final idx = next.indexWhere((e) => e.id == result.id);
    if (idx >= 0) {
      next[idx] = result;
    } else {
      next.add(result);
    }
    await context.read<AppState>().taskBookController.updateCustomTaskBook(book.copyWith(requirements: next));
  }
}

enum _BuilderView { sections, reorder }

class _ViewToggle extends StatelessWidget {
  final _BuilderView value;
  final ValueChanged<_BuilderView> onChanged;
  const _ViewToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_BuilderView>(
      segments: const [
        ButtonSegment(value: _BuilderView.sections, label: Text('Sections'), icon: Icon(Icons.view_agenda_outlined)),
        ButtonSegment(value: _BuilderView.reorder, label: Text('Reorder'), icon: Icon(Icons.drag_handle)),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class _QuickAddPanel extends StatelessWidget {
  final ValueChanged<_RequirementDraft> onAdd;
  const _QuickAddPanel({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick add', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Drop in common department items, then edit details.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickAddChip(
                label: 'Driver Training Hours',
                icon: Icons.local_shipping_outlined,
                onTap: () => onAdd(const _RequirementDraft(name: 'Driver / Operator Training Hours', type: RequirementType.numericProgress, category: 'Driver / Operator', requiredFlag: true, unit: 'hours')),
              ),
              _QuickAddChip(
                label: 'Live Fire Evolutions',
                icon: Icons.local_fire_department_outlined,
                onTap: () => onAdd(const _RequirementDraft(name: 'Live Fire Evolutions', type: RequirementType.numericProgress, category: 'Live Fire', requiredFlag: true, unit: 'evolutions')),
              ),
              _QuickAddChip(
                label: 'Quarterly Skills',
                icon: Icons.checklist_outlined,
                onTap: () => onAdd(const _RequirementDraft(name: 'Quarterly Skills / Competencies', type: RequirementType.taskBook, category: 'Skills', requiredFlag: true)),
              ),
              _QuickAddChip(
                label: 'CE / Renewal Hours',
                icon: Icons.school_outlined,
                onTap: () => onAdd(const _RequirementDraft(name: 'Continuing Education (CE) Hours', type: RequirementType.numericProgress, category: 'Continuing Education', requiredFlag: true, unit: 'hours')),
              ),
              _QuickAddChip(
                label: 'Promotional Prep Study',
                icon: Icons.menu_book_outlined,
                onTap: () => onAdd(const _RequirementDraft(name: 'Promotional Prep — Study Time', type: RequirementType.numericProgress, category: 'Promotion', requiredFlag: false, unit: 'hours')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAddChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _SectionedRequirementList extends StatelessWidget {
  final List<Requirement> requirements;
  final String goalId;
  final ValueChanged<Requirement> onTap;
  final ValueChanged<Requirement> onEdit;
  final ValueChanged<String> onAddToSection;
  const _SectionedRequirementList({super.key, required this.requirements, required this.goalId, required this.onTap, required this.onEdit, required this.onAddToSection});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();
    final by = <String, List<Requirement>>{};
    for (final r in requirements) {
      final key = r.category.trim().isEmpty ? 'General' : r.category.trim();
      by.putIfAbsent(key, () => <Requirement>[]).add(r);
    }
    final sections = by.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: sections.map((e) {
        final title = e.key;
        final items = e.value;
        final done = items.where((r) {
          final o = state.taskBookController.getOverride(goalId, r.id);
          return (o?.completed ?? r.completed) == true;
        }).length;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                title: Row(
                  children: [
                    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
                    Text('$done/${items.length}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
                  ],
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => onAddToSection(title),
                      icon: const Icon(Icons.add),
                      label: const Text('Add to this section'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...items.map((r) {
                    final o = state.taskBookController.getOverride(goalId, r.id);
                    final complete = (o?.completed ?? r.completed) == true;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: InkWell(
                        onTap: () => onTap(r),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.10))),
                          child: Row(
                            children: [
                              Icon(complete ? Icons.check_circle : Icons.circle_outlined, color: complete ? FireOpsSemanticColors.completed : cs.onSurfaceVariant),
                              const SizedBox(width: 10),
                              Expanded(child: Text(r.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => onEdit(r),
                                icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
                              ),
                              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyBuilderState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBuilderState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Start with 5–10 real department requirements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Add the items your officers and training division actually expect: driver training hours, quarterly skills, promotional steps, local SOP sign-offs, and mandatory courses.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Requirement'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementReorderList extends StatelessWidget {
  final List<Requirement> requirements;
  final String goalId;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<Requirement> onTapRequirement;
  final ValueChanged<Requirement> onEditRequirement;
  final void Function(Requirement r, bool requiredFlag) onToggleRequired;
  final ValueChanged<Requirement> onDeleteRequirement;

  const _RequirementReorderList({
    super.key,
    required this.requirements,
    required this.goalId,
    required this.onReorder,
    required this.onTapRequirement,
    required this.onEditRequirement,
    required this.onToggleRequired,
    required this.onDeleteRequirement,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: onReorder,
      itemCount: requirements.length,
      itemBuilder: (context, index) {
        final r = requirements[index];
        final o = state.taskBookController.getOverride(goalId, r.id);
        final complete = (o?.completed ?? r.completed) == true;

        final requiredFlag = r.defaultRequired || r.priority == RequirementPriority.department || r.requirementSource == RequirementSource.departmentRequirement;

        return Container(
          key: ValueKey(r.id),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: InkWell(
            onTap: () => onTapRequirement(r),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  Icon(complete ? Icons.check_circle : Icons.circle_outlined, color: complete ? FireOpsSemanticColors.completed : cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MiniChip(text: r.category.isEmpty ? 'General' : r.category, tone: _ChipTone.neutral),
                            _MiniChip(text: describeEnum(r.type).toUpperCase(), tone: _ChipTone.neutral),
                            _MiniChip(text: requiredFlag ? 'REQUIRED' : 'RECOMMENDED', tone: requiredFlag ? _ChipTone.strong : _ChipTone.neutral),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Actions',
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEditRequirement(r);
                          break;
                        case 'toggle_required':
                          onToggleRequired(r, !requiredFlag);
                          break;
                        case 'delete':
                          onDeleteRequirement(r);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'toggle_required', child: Text(requiredFlag ? 'Mark Recommended' : 'Mark Required')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.drag_handle, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _ChipTone { neutral, strong }

class _MiniChip extends StatelessWidget {
  final String text;
  final _ChipTone tone;
  const _MiniChip({required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = tone == _ChipTone.strong ? cs.primaryContainer : cs.surfaceContainerHighest.withValues(alpha: 0.6);
    final fg = tone == _ChipTone.strong ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99), border: Border.all(color: cs.outline.withValues(alpha: 0.10))),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w900)),
    );
  }
}

class _RequirementEditorSheet extends StatefulWidget {
  final CustomTaskBook book;
  final Requirement? existing;
  final _RequirementDraft? prefill;
  const _RequirementEditorSheet({required this.book, required this.existing, required this.prefill});

  @override
  State<_RequirementEditorSheet> createState() => _RequirementEditorSheetState();
}

class _RequirementEditorSheetState extends State<_RequirementEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _progressRequiredCtrl;
  late final TextEditingController _progressUnitCtrl;
  late RequirementType _type;
  bool _requiredFlag = true;
  final List<String> _prereq = <String>[];

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    final p = widget.prefill;
    _nameCtrl = TextEditingController(text: r?.name ?? p?.name ?? '');
    _categoryCtrl = TextEditingController(text: r?.category ?? p?.category ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? p?.description ?? '');
    _type = r?.type ?? p?.type ?? RequirementType.custom;
    _requiredFlag = r == null
        ? true
        : (r.defaultRequired || r.priority == RequirementPriority.department || r.requirementSource == RequirementSource.departmentRequirement);

    if (r == null && p?.requiredFlag != null) {
      _requiredFlag = p!.requiredFlag!;
    }

    _progressRequiredCtrl = TextEditingController(
      text: (r?.progressRequired ?? p?.progressRequired)?.toStringAsFixed(0) ?? '',
    );
    _progressUnitCtrl = TextEditingController(text: r?.progressUnit ?? p?.unit ?? '');
    _prereq
      ..clear()
      ..addAll(r?.prerequisiteRequirementIds ?? const []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    _progressRequiredCtrl.dispose();
    _progressUnitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inset = MediaQuery.viewInsetsOf(context);
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: inset.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEditing ? 'Edit Requirement' : 'Add Requirement', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Requirement name')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RequirementType>(
                      value: _type,
                      items: RequirementType.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(describeEnum(t).toUpperCase())))
                          .toList(),
                      onChanged: (v) => setState(() => _type = v ?? _type),
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(controller: _categoryCtrl, decoration: const InputDecoration(labelText: 'Stage / section')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _requiredFlag,
                onChanged: (v) => setState(() => _requiredFlag = v),
                title: const Text('Required'),
                subtitle: const Text('Turn off to mark this as recommended.'),
                contentPadding: EdgeInsets.zero,
              ),
              if (_type == RequirementType.numericProgress) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _progressRequiredCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Required total'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _progressUnitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit (optional)', hintText: 'hours'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Tip: log progress from Quick Log or the requirement plan.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Notes / description (optional)'),
              ),
              const SizedBox(height: 12),
              _PrereqPicker(
                all: widget.book.requirements,
                selected: _prereq,
                onChanged: (next) => setState(() {
                  _prereq
                    ..clear()
                    ..addAll(next);
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => _save(context),
                  icon: Icon(isEditing ? Icons.save : Icons.add, color: cs.onPrimary),
                  label: Text(isEditing ? 'Save' : 'Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a name for this requirement.')));
      return;
    }

    double? progressRequired;
    String? progressUnit;
    double? progressCurrent;
    if (_type == RequirementType.numericProgress) {
      progressRequired = double.tryParse(_progressRequiredCtrl.text.trim());
      progressUnit = _progressUnitCtrl.text.trim().isEmpty ? null : _progressUnitCtrl.text.trim();
      progressCurrent = widget.existing?.progressCurrent ?? 0;
    }

    final now = DateTime.now();
    final existing = widget.existing;
    final id = existing?.id ?? '${widget.book.pseudoGoalId}::${now.microsecondsSinceEpoch}';
    final sortOrder = existing?.sortOrder ?? widget.book.requirements.length + 1;

    final requirementSource = _requiredFlag ? RequirementSource.departmentRequirement : RequirementSource.recommended;
    final priority = _requiredFlag ? RequirementPriority.department : RequirementPriority.recommended;

    final r = existing?.copyWith(
          name: name,
          category: _categoryCtrl.text.trim().isEmpty ? 'General' : _categoryCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          type: _type,
          requirementSource: requirementSource,
          priority: priority,
          defaultRequired: _requiredFlag,
          prerequisiteRequirementIds: [..._prereq],
          progressCurrent: progressCurrent,
          progressRequired: progressRequired,
          progressUnit: progressUnit,
          updatedAt: now,
        ) ??
        Requirement(
          id: id,
          name: name,
          category: _categoryCtrl.text.trim().isEmpty ? 'General' : _categoryCtrl.text.trim(),
          priority: priority,
          description: _descCtrl.text.trim(),
          type: _type,
          requirementSource: requirementSource,
          defaultRequired: _requiredFlag,
          stateDependent: false,
          departmentDependent: true,
          completed: false,
          progressCurrent: progressCurrent,
          progressRequired: progressRequired,
          progressUnit: progressUnit,
          experienceValue: null,
          experienceUnit: null,
          certificationReference: null,
          certificationDefinitionId: null,
          allowExpiredCertification: false,
          prerequisiteRequirementIds: [..._prereq],
          resourceIds: const [],
          resourceLinks: const [],
          sortOrder: sortOrder,
          estimatedDurationDays: null,
          recommendedLeadTimeDays: null,
          canRunConcurrent: true,
          timelineCategory: TimelineCategory.departmentRequirement,
          suggestedStartDate: null,
          suggestedCompletionDate: null,
          createdAt: now,
          updatedAt: now,
        );

    context.pop(r);
  }
}

@immutable
class _RequirementDraft {
  final String? name;
  final RequirementType? type;
  final String? category;
  final bool? requiredFlag;
  final String? description;
  final double? progressRequired;
  final String? unit;
  const _RequirementDraft({
    this.name,
    this.type,
    this.category,
    this.requiredFlag,
    this.description,
    this.progressRequired,
    this.unit,
  });
}

class _PrereqPicker extends StatelessWidget {
  final List<Requirement> all;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _PrereqPicker({required this.all, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggested order (optional)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Pick prerequisites to help you and your crew follow a smart sequence.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: all.map((r) {
              final active = selected.contains(r.id);
              return FilterChip(
                label: Text(r.name, overflow: TextOverflow.ellipsis),
                selected: active,
                onSelected: (v) {
                  final next = [...selected];
                  if (v) {
                    if (!next.contains(r.id)) next.add(r.id);
                  } else {
                    next.removeWhere((e) => e == r.id);
                  }
                  onChanged(next);
                },
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
