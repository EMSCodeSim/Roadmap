import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/portal/models/credential.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/portal/widgets/portal_page_scaffold.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/status_pill.dart';

class PortalCertificationsPage extends StatelessWidget {
  const PortalCertificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    final deptId = portal.activeDepartmentId;
    final all = deptId == null ? const <Credential>[] : portal.db.credentials.where((c) => c.departmentId == deptId).toList();

    return DefaultTabController(
      length: 6,
      child: PortalPageScaffold(
        title: 'Certifications',
        subtitle: 'Department credential readiness — expired, expiring windows, and current.',
        child: Column(
          children: [
            Card(
              child: TabBar(
                isScrollable: true,
                labelColor: cs.onSurface,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorColor: cs.primary,
                dividerColor: cs.outline.withValues(alpha: 0.14),
                tabs: const [
                  Tab(text: 'Expired'),
                  Tab(text: 'Next 30'),
                  Tab(text: 'Next 60'),
                  Tab(text: 'Next 90'),
                  Tab(text: '6 Months'),
                  Tab(text: 'Current'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: TabBarView(
                children: [
                  _CredTable(items: _filter(all, windowDays: -1)),
                  _CredTable(items: _filter(all, windowDays: 30)),
                  _CredTable(items: _filter(all, windowDays: 60)),
                  _CredTable(items: _filter(all, windowDays: 90)),
                  _CredTable(items: _filter(all, windowDays: 180)),
                  _CredTable(items: _filter(all, windowDays: 99999)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Credential> _filter(List<Credential> all, {required int windowDays}) {
    final now = DateTime.now();
    if (windowDays == -1) {
      return all.where((c) => c.expirationDate != null && c.expirationDate!.isBefore(now)).toList()..sort((a, b) => a.expirationDate!.compareTo(b.expirationDate!));
    }

    if (windowDays == 99999) {
      return all.where((c) {
        final exp = c.expirationDate;
        if (exp == null) return true;
        return exp.isAfter(now.add(const Duration(days: 180)));
      }).toList();
    }

    final end = now.add(Duration(days: windowDays));
    return all.where((c) {
      final exp = c.expirationDate;
      if (exp == null) return false;
      if (exp.isBefore(now)) return false;
      return exp.isBefore(end) || exp.isAtSameMomentAs(end);
    }).toList()
      ..sort((a, b) => a.expirationDate!.compareTo(b.expirationDate!));
  }
}

class _CredTable extends StatelessWidget {
  final List<Credential> items;
  const _CredTable({required this.items});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalController>();
    final cs = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return Card(
        child: Center(
          child: Text('No credentials in this category.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 64,
          columns: const [
            DataColumn(label: Text('Member')),
            DataColumn(label: Text('Credential')),
            DataColumn(label: Text('Issuer')),
            DataColumn(label: Text('Issue Date')),
            DataColumn(label: Text('Expiration')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Verification')),
          ],
          rows: items.map((c) {
            final member = portal.db.users.cast().firstWhere((u) => u.id == c.memberId, orElse: () => null);
            final tone = _toneFor(c);
            return DataRow(cells: [
              DataCell(Text(member?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w900))),
              DataCell(Text(c.credentialName)),
              DataCell(Text(c.issuer)),
              DataCell(Text(c.issueDate == null ? '—' : _date(c.issueDate!))),
              DataCell(Text(c.expirationDate == null ? '—' : _date(c.expirationDate!))),
              DataCell(StatusPill(text: _statusLabel(c), icon: Icons.circle, backgroundColor: tone.withValues(alpha: 0.10), foregroundColor: tone, maxWidth: 200)),
              DataCell(Text(c.verificationStatus.label)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  static Color _toneFor(Credential c) {
    final exp = c.expirationDate;
    if (exp == null) return Colors.grey;
    final days = exp.difference(DateTime.now()).inDays;
    if (days < 0) return FireOpsSemanticColors.expired;
    if (days <= 60) return FireOpsSemanticColors.expiring;
    return FireOpsSemanticColors.current;
  }

  static String _statusLabel(Credential c) {
    final exp = c.expirationDate;
    if (exp == null) return 'Missing expiration';
    final days = exp.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days <= 60) return 'Expiring';
    return 'Current';
  }

  static String _date(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';
}
