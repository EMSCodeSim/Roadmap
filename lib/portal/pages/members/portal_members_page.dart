import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/status_pill.dart';

class PortalMembersPage extends StatefulWidget {
  const PortalMembersPage({super.key});

  @override
  State<PortalMembersPage> createState() => _PortalMembersPageState();
}

class _PortalMembersPageState extends State<PortalMembersPage> {
  String _search = '';
  String? _rank;
  String? _station;
  String? _shift;
  bool? _active;

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final all = portal.departmentMembers;

    final ranks = all.map((e) => e.rank).whereType<String>().toSet().toList()..sort();
    final stations = all.map((e) => e.station).whereType<String>().toSet().toList()..sort();
    final shifts = all.map((e) => e.shift).whereType<String>().toSet().toList()..sort();

    List<PortalUser> filtered() {
      return all.where((m) {
        if (_active != null && m.isActive != _active) return false;
        if (_rank != null && (m.rank ?? '') != _rank) return false;
        if (_station != null && (m.station ?? '') != _station) return false;
        if (_shift != null && (m.shift ?? '') != _shift) return false;
        if (_search.trim().isNotEmpty) {
          final s = _search.trim().toLowerCase();
          if (!m.name.toLowerCase().contains(s) && !m.email.toLowerCase().contains(s)) return false;
        }
        return true;
      }).toList();
    }

    final members = filtered();

    return PortalPageScaffold(
      title: 'Members',
      subtitle: 'Search and monitor member progress across Task Books and credentials.',
      actions: [
        SizedBox(
          width: 320,
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name or email'),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
      ],
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _FilterDropdown<String>(
                    label: 'Rank',
                    value: _rank,
                    items: ranks,
                    onChanged: (v) => setState(() => _rank = v),
                  ),
                  _FilterDropdown<String>(
                    label: 'Station',
                    value: _station,
                    items: stations,
                    onChanged: (v) => setState(() => _station = v),
                  ),
                  _FilterDropdown<String>(
                    label: 'Shift',
                    value: _shift,
                    items: shifts,
                    onChanged: (v) => setState(() => _shift = v),
                  ),
                  _FilterDropdown<bool>(
                    label: 'Status',
                    value: _active,
                    items: const [true, false],
                    itemLabel: (b) => b ? 'Active' : 'Inactive',
                    onChanged: (v) => setState(() => _active = v),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _rank = null;
                      _station = null;
                      _shift = null;
                      _active = null;
                      _search = '';
                    }),
                    icon: Icon(Icons.refresh, color: cs.onSurface),
                    label: Text('Clear', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 62,
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Rank / Position')),
                    DataColumn(label: Text('Station')),
                    DataColumn(label: Text('Shift')),
                    DataColumn(label: Text('Active Task Books')),
                    DataColumn(label: Text('Overall Progress')),
                    DataColumn(label: Text('Last Activity')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: members.map((m) {
                    final assignments = portal.assignmentsForMember(m.id);
                    final activeCount = assignments.length;
                    final avgProgress = activeCount == 0 ? 0.0 : (assignments.map(portal.progressForAssignment).reduce((a, b) => a + b) / activeCount);
                    final last = portal.db.activity.where((a) => a.userId == m.id).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                    final lastText = last.isEmpty ? '—' : _daysAgo(last.first.timestamp);
                    return DataRow(
                      onSelectChanged: (_) => context.go('${AppRoutes.portal}/members/${m.id}'),
                      cells: [
                        DataCell(Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                        DataCell(Text(m.rank ?? '—')),
                        DataCell(Text(m.station ?? '—')),
                        DataCell(Text(m.shift ?? '—')),
                        DataCell(Text('$activeCount')),
                        DataCell(Text('${(avgProgress * 100).round()}%')),
                        DataCell(Text(lastText)),
                        DataCell(
                          StatusPill(
                            text: m.isActive ? 'Active' : 'Inactive',
                            icon: m.isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                            backgroundColor: m.isActive ? FireOpsSemanticColors.complete.withValues(alpha: 0.10) : cs.surfaceContainerHighest,
                            foregroundColor: m.isActive ? FireOpsSemanticColors.complete : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _daysAgo(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T)? itemLabel;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: () => onChanged(null),
                  icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                ),
        ),
        items: items
            .map(
              (i) => DropdownMenuItem(
                value: i,
                child: Text(itemLabel?.call(i) ?? i.toString()),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
