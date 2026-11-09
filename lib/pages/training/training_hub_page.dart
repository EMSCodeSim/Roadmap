import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/career_stats.dart';
import 'package:firepath/services/certification_urgency.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/section_header.dart';

/// Personal record cabinet: activity, credentials, completed training,
/// statistics, and portable exports. Department approvals and Training Sheet
/// closeout remain in the Department workspace.
class TrainingHubPage extends StatefulWidget {
  const TrainingHubPage({super.key});

  @override
  State<TrainingHubPage> createState() => _TrainingHubPageState();
}

class _TrainingHubPageState extends State<TrainingHubPage> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    QuickLogLauncher.recordRevision.addListener(_loadRecords);
    _loadRecords();
  }

  @override
  void dispose() {
    QuickLogLauncher.recordRevision.removeListener(_loadRecords);
    super.dispose();
  }

  Future<void> _loadRecords() async {
    try {
      final loaded = await _store.load();
      if (!mounted) return;
      setState(() {
        _records = loaded;
        _loadError = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Your activity history could not be loaded.';
        _loading = false;
      });
    }
  }

  bool _isTaskBookEvidence(CareerRecord record) =>
      record.type == CareerRecordType.taskBookEvidence ||
      record.tags.contains('task-book');

  List<CareerRecord> get _personalRecords =>
      _records.where((record) => !_isTaskBookEvidence(record)).toList();

  List<CareerRecord> get _trainingRecords => _personalRecords
      .where((record) => record.type == CareerRecordType.training)
      .toList();

  CareerStats get _careerStats => CareerStats.fromRecords(_personalRecords);

  CareerStats get _yearStats {
    final year = DateTime.now().year;
    return CareerStats.fromRecords(
      _personalRecords.where((record) => record.date.year == year).toList(),
    );
  }

  Future<void> _showExportOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.ios_share_outlined),
              title: const Text('Share personal record PDF'),
              subtitle: const Text('Activity, training totals, and credentials'),
              onTap: () => Navigator.pop(sheetContext, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Print personal record'),
              subtitle: const Text('Open the system print options'),
              onTap: () => Navigator.pop(sheetContext, 'print'),
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup & restore'),
              subtitle: const Text('Manage a full portfolio backup'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.personalLog);
              },
            ),
          ],
        ),
      ),
    );
    if (action == 'share') await _sharePdf();
    if (action == 'print') await _printPdf();
  }

  pw.Document _buildPdf() {
    final app = context.read<AppState>();
    final records = _personalRecords;
    final training = records
        .where((record) => record.type == CareerRecordType.training)
        .toList();
    final activity = records
        .where((record) => record.type != CareerRecordType.training)
        .toList();
    final stats = CareerStats.fromRecords(records);
    final certs = app.certifications;
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'Responder Roadmap - Personal Record',
            style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Generated ' + CareerStats.formatDate(DateTime.now())),
          pw.SizedBox(height: 14),
          pw.Text('Career summary',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            'Training: ' + stats.trainingLabel +
                ' | Calls: ' + stats.calls.toString() +
                ' | Skills: ' + stats.skillRepetitions.toString() +
                ' | Driving: ' + stats.driveLabel,
          ),
          pw.SizedBox(height: 14),
          pw.Text('Credentials (' + certs.length.toString() + ')',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          if (certs.isEmpty)
            pw.Text('No credentials on file.')
          else
            ...certs.map((cert) => pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 5),
                  child: pw.Text(cert.name + ' - ' + _certDateSummary(cert)),
                )),
          pw.SizedBox(height: 14),
          pw.Text('Training history (' + training.length.toString() + ')',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          if (training.isEmpty)
            pw.Text('No training records on file.')
          else
            ...training.map(_pdfRecord),
          pw.SizedBox(height: 14),
          pw.Text('Activity history (' + activity.length.toString() + ')',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          if (activity.isEmpty)
            pw.Text('No other activity records on file.')
          else
            ...activity.map(_pdfRecord),
          pw.SizedBox(height: 10),
          pw.Text(
            'This report contains personal records from Responder Roadmap. '
            'Department approvals and RMS closeout status remain in the department record.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
    return pdf;
  }

  pw.Widget _pdfRecord(CareerRecord record) => pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 5),
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              CareerStats.formatDate(record.date) + ' - ' + record.title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text([
              record.type.shortLabel,
              if (record.category.trim().isNotEmpty) record.category,
              if (record.hours != null && record.hours! > 0)
                CareerStats.formatDurationHours(record.hours!),
            ].join(' | ')),
            if ((record.summary ?? '').trim().isNotEmpty)
              pw.Text(record.summary!.trim()),
            if ((record.evidenceReference ?? '').trim().isNotEmpty)
              pw.Text('Evidence: ' + record.evidenceReference!.trim()),
          ],
        ),
      );

  Future<void> _sharePdf() async {
    try {
      final bytes = await _buildPdf().save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'responder-roadmap-personal-record.pdf',
      );
    } catch (_) {
      _showExportError();
    }
  }

  Future<void> _printPdf() async {
    try {
      final bytes = await _buildPdf().save();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      _showExportError();
    }
  }

  void _showExportError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The personal record could not be exported.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final records = _personalRecords;
    final training = _trainingRecords;
    final certs = app.certifications;
    final urgent = CertificationUrgency.urgent(certs);
    final stats = _careerStats;
    final yearStats = _yearStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(
            tooltip: 'Export or print records',
            onPressed: _showExportOptions,
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecords,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text(
                'Your work, credentials, and training history.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              _QuickActionsRow(
                onQuickAdd: () => QuickLogLauncher.open(context),
                onOpenCertificates: () => context.push(AppRoutes.certifications),
                onOpenStats: () => context.push(AppRoutes.personalLog),
              ),
              const SizedBox(height: 16),
              if (urgent.isNotEmpty) ...[
                _NeedsAttentionCard(
                  expired: urgent.where((item) => item.isExpired).length,
                  expiring: urgent.where((item) => item.isExpiringSoon).length,
                  onTap: () => context.push(AppRoutes.certifications),
                ),
                const SizedBox(height: 16),
              ],
              _SectionTitle(title: 'At a glance', icon: Icons.insights_outlined, action: 'Full stats', onAction: () => context.push(AppRoutes.personalLog)),
              const SizedBox(height: 8),
              _StatsStrip(
                year: DateTime.now().year,
                yearStats: yearStats,
                careerStats: stats,
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: 'Quick logs', icon: Icons.folder_copy_outlined, action: 'All logs', onAction: () => context.push(AppRoutes.personalLog)),
              const SizedBox(height: 8),
              if (_loading)
                const _LoadingCard()
              else if (_loadError != null)
                _MessageCard(message: _loadError!, actionLabel: 'Retry', onAction: _loadRecords)
              else if (records.isEmpty)
                _MessageCard(
                  message: 'Your Quick Add history will appear here.',
                  actionLabel: 'Quick Add',
                  onAction: () => QuickLogLauncher.open(context),
                )
              else
                _RecordPreviewCard(
                  records: records.take(3).toList(),
                  onOpen: () => context.push(AppRoutes.personalLog),
                ),
              const SizedBox(height: 18),
              _SectionTitle(title: 'Certificates & licenses', icon: Icons.workspace_premium_outlined, action: 'Open', onAction: () => context.push(AppRoutes.certifications)),
              const SizedBox(height: 8),
              _CredentialCard(
                certs: certs,
                urgent: urgent.take(3).toList(),
                onOpen: () => context.push(AppRoutes.certifications),
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: 'Training records', icon: Icons.school_outlined, action: 'All training', onAction: () => context.push(AppRoutes.personalLog)),
              const SizedBox(height: 8),
              if (_loading)
                const _LoadingCard()
              else if (_loadError != null)
                _MessageCard(message: _loadError!, actionLabel: 'Retry', onAction: _loadRecords)
              else
                _TrainingHistoryCard(
                  records: training.take(3).toList(),
                  allRecords: training,
                  stats: stats,
                  onOpen: () => context.push(AppRoutes.personalLog),
                ),
              const SizedBox(height: 18),
              _SectionTitle(title: 'Stats & exports', icon: Icons.ios_share_outlined),
              const SizedBox(height: 8),
              _ExportCard(
                year: DateTime.now().year,
                yearStats: yearStats,
                careerStats: stats,
                onStats: () => context.push(AppRoutes.personalLog),
                onExport: _showExportOptions,
              ),
              const SizedBox(height: 10),
              Text(
                'Department assignments, instructor approvals, and Training Sheet closeout stay in Department.',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, this.action, this.onAction});
  final String title;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
                ),
                child: Icon(icon, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: SectionHeader(title: title)),
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.onQuickAdd, required this.onOpenCertificates, required this.onOpenStats});
  final VoidCallback onQuickAdd;
  final VoidCallback onOpenCertificates;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.add_rounded,
            title: 'Quick Add',
            subtitle: 'Log now',
            color: cs.primary,
            background: cs.primaryContainer.withValues(alpha: 0.55),
            onTap: onQuickAdd,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Certificates',
            subtitle: 'Renewals',
            color: cs.tertiary,
            background: cs.tertiaryContainer.withValues(alpha: 0.55),
            onTap: onOpenCertificates,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.insights_outlined,
            title: 'Stats',
            subtitle: 'Year view',
            color: cs.secondary,
            background: cs.secondaryContainer.withValues(alpha: 0.55),
            onTap: onOpenStats,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.background, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
            Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.year, required this.yearStats, required this.careerStats});
  final int year;
  final CareerStats yearStats;
  final CareerStats careerStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final values = [
      (CareerStats.formatDurationHours(yearStats.trainingHours), year.toString() + ' training'),
      (CareerStats.formatDurationHours(careerStats.trainingHours), 'Career training'),
      (careerStats.calls.toString(), 'Calls logged'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 16) / 3;
      return Row(
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            SizedBox(
              width: width,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(values[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
                      const SizedBox(height: 3),
                      Text(values[i].$2, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _NeedsAttentionCard extends StatelessWidget {
  const _NeedsAttentionCard({required this.expired, required this.expiring, required this.onTap});
  final int expired;
  final int expiring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = expired + expiring;
    final title = expired > 0
        ? expired.toString() + ' expired credential' + (expired == 1 ? '' : 's')
        : 'Credential renewal coming up';
    return Card(
      color: (expired > 0 ? cs.errorContainer : cs.tertiaryContainer).withValues(alpha: 0.75),
      child: ListTile(
        onTap: onTap,
        leading: Icon(expired > 0 ? Icons.error_outline_rounded : Icons.event_busy_outlined),
        title: Text(title),
        subtitle: Text(count.toString() + ' credential' + (count == 1 ? '' : 's') + ' need attention. Review renewal dates.'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({required this.certs, required this.urgent, required this.onOpen});
  final List<Certification> certs;
  final List<CertificationUrgencyItem> urgent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final current = certs.where((cert) => cert.status == CertificationStatus.current).length;
    final expired = certs.where((cert) => cert.status == CertificationStatus.expired).length;
    final expiring = certs.where((cert) => cert.status == CertificationStatus.expiringSoon).length;
    if (certs.isEmpty) {
      return _MessageCard(
        message: 'Add your licenses and certificates to track renewal dates.',
        actionLabel: 'Add credential',
        onAction: onOpen,
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(certs.length.toString() + ' credentials',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(current.toString() + ' current  ·  ' + expiring.toString() + ' expiring  ·  ' + expired.toString() + ' expired',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (urgent.isNotEmpty)
            ...urgent.map((item) => ListTile(
                  dense: true,
                  leading: Icon(item.isExpired ? Icons.error_outline : Icons.schedule_outlined),
                  title: Text(item.cert.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_certDateSummary(item.cert)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: onOpen,
                ))
          else
            const ListTile(
              dense: true,
              leading: Icon(Icons.verified_outlined),
              title: Text('All tracked credentials are current'),
            ),
        ],
      ),
    );
  }
}

class _TrainingHistoryCard extends StatelessWidget {
  const _TrainingHistoryCard({required this.records, required this.allRecords, required this.stats, required this.onOpen});
  final List<CareerRecord> records;
  final List<CareerRecord> allRecords;
  final CareerStats stats;
  final VoidCallback onOpen;

  Map<String, double> get _hoursByCategory {
    final result = <String, double>{};
    for (final record in allRecords) {
      final category = record.category.trim().isEmpty ? 'Other training' : record.category.trim();
      result[category] = (result[category] ?? 0) + (record.hours ?? 0);
    }
    return result;
  }

  Map<String, double> get _hoursByShift {
    final result = <String, double>{};
    for (final record in allRecords) {
      final raw = record.details['shift'] ?? record.details['shiftName'] ?? record.details['shiftCode'];
      if (raw is! String || raw.trim().isEmpty) continue;
      final shift = raw.trim();
      result[shift] = (result[shift] ?? 0) + (record.hours ?? 0);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _hoursByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final shifts = _hoursByShift.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Text(
                CareerStats.formatDurationHours(stats.trainingHours) + ' across ' + allRecords.length.toString() + ' training records',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
              TextButton(onPressed: onOpen, child: const Text('View')),
            ]),
            if (allRecords.isEmpty)
              const Text('Completed classes logged here appear in your personal activity history.')
            else ...[
              for (final record in records)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(record.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(CareerStats.formatDate(record.date) + '  ·  ' + (record.category.trim().isEmpty ? 'Training' : record.category)),
                  trailing: Text(record.hours == null ? '' : CareerStats.formatDurationHours(record.hours!)),
                  onTap: onOpen,
                ),
              if (categories.isNotEmpty) ...[
                const Divider(),
                Text('Hours by category', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                for (final item in categories.take(3))
                  _BreakdownRow(label: item.key, value: CareerStats.formatDurationHours(item.value)),
              ],
              if (shifts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Hours by shift', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                for (final item in shifts)
                  _BreakdownRow(label: item.key, value: CareerStats.formatDurationHours(item.value)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordPreviewCard extends StatelessWidget {
  const _RecordPreviewCard({required this.records, required this.onOpen});
  final List<CareerRecord> records;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            for (final record in records)
              ListTile(
                dense: true,
                leading: Icon(_iconFor(record.type)),
                title: Text(record.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(CareerStats.formatDate(record.date) + '  ·  ' + record.type.shortLabel),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onOpen,
              ),
          ],
        ),
      );
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.year, required this.yearStats, required this.careerStats, required this.onStats, required this.onExport});
  final int year;
  final CareerStats yearStats;
  final CareerStats careerStats;
  final VoidCallback onStats;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Review activity by year or across your career. Export a shareable record for renewals, applications, or audits.'),
              const SizedBox(height: 8),
              Text(year.toString() + ': ' + CareerStats.formatDurationHours(yearStats.trainingHours) + ' training logged',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(onPressed: onStats, icon: const Icon(Icons.insights_outlined), label: const Text('Yearly & career stats')),
                  FilledButton.tonalIcon(onPressed: onExport, icon: const Icon(Icons.ios_share_outlined), label: const Text('Export or print')),
                ],
              ),
            ],
          ),
        ),
      );
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.actionLabel, this.onAction});
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(message),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: onAction, child: Text(actionLabel!))),
            ],
          ]),
        ),
      );
}

IconData _iconFor(CareerRecordType type) => switch (type) {
      CareerRecordType.operationalExperience => Icons.local_fire_department_outlined,
      CareerRecordType.skill => Icons.fact_check_outlined,
      CareerRecordType.training => Icons.school_outlined,
      CareerRecordType.achievement => Icons.workspace_premium_outlined,
      CareerRecordType.leadership => Icons.groups_outlined,
      CareerRecordType.teaching => Icons.cast_for_education_outlined,
      CareerRecordType.project => Icons.task_alt_outlined,
      CareerRecordType.education => Icons.menu_book_outlined,
      CareerRecordType.taskBookEvidence => Icons.checklist_outlined,
    };

String _certDateSummary(Certification cert) {
  final parts = <String>[];
  if (cert.issueDate != null) {
    parts.add('Issued ' + CareerStats.formatDate(cert.issueDate!));
  }
  if (cert.doesNotExpire || cert.expirationDate == null) {
    parts.add('No expiration');
  } else {
    final status = cert.status == CertificationStatus.expired
        ? 'Expired'
        : cert.status == CertificationStatus.expiringSoon
            ? 'Due '
            : 'Expires ';
    parts.add(status + CareerStats.formatDate(cert.expirationDate!));
  }
  if (parts.isEmpty) parts.add('Issue and renewal dates not recorded');
  return parts.join('  ·  ');
}
