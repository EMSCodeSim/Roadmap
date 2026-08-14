import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/career_pdf_export.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class CareerExportPage extends StatefulWidget {
  const CareerExportPage({super.key});

  @override
  State<CareerExportPage> createState() => _CareerExportPageState();
}

class _CareerExportPageState extends State<CareerExportPage> {
  final CareerRecordStore _recordsStore = CareerRecordStore();
  final CareerExportIdentityStore _identityStore = CareerExportIdentityStore();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  List<CareerRecord> _records = const [];
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _recordsStore.load(),
      _identityStore.load(),
    ]);
    final records = results[0] as List<CareerRecord>;
    final identity = results[1] as CareerExportIdentity;
    if (!mounted) return;
    setState(() {
      _records = records;
      _name.text = identity.name;
      _email.text = identity.email;
      _phone.text = identity.phone;
      _location.text = identity.location;
      _loading = false;
    });
  }

  CareerExportIdentity get _identity => CareerExportIdentity(
    name: _name.text.trim(),
    email: _email.text.trim(),
    phone: _phone.text.trim(),
    location: _location.text.trim(),
  );

  Future<void> _saveIdentity() => _identityStore.save(_identity);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Career Export Center')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turn your career record into a professional document.',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate a polished career portfolio, promotion packet, or resume from the information you have already preserved in Career Road.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'EXPORT IDENTITY',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: .14),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Name for exported documents',
                          hintText: 'Optional',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _location,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'City / State',
                          hintText: 'Example: Denver, CO',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _saveIdentity,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save export info'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'PDF EXPORTS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _ExportCard(
                  icon: Icons.badge_outlined,
                  title: 'Professional Resume',
                  description:
                      'A concise resume built from roles, credentials, accomplishments, leadership, teaching, projects, and professional development.',
                  onPreview: _working ? null : () => _previewResume(app),
                  onShare: _working ? null : () => _shareResume(app),
                ),
                const SizedBox(height: 10),
                _ExportCard(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Promotion Packet',
                  description:
                      'Readiness, evidence gaps, competencies, credentials, and your strongest interview stories in a promotion-focused packet.',
                  onPreview: _working ? null : () => _previewPromotion(app),
                  onShare: _working ? null : () => _sharePromotion(app),
                ),
                const SizedBox(height: 10),
                _ExportCard(
                  icon: Icons.auto_stories_outlined,
                  title: 'Career Portfolio',
                  description:
                      'A fuller professional history with career totals, credentials, highlights, advancement readiness, and development priorities.',
                  onPreview: _working ? null : () => _previewPortfolio(app),
                  onShare: _working ? null : () => _sharePortfolio(app),
                ),
                const SizedBox(height: 14),
                Text(
                  'Exports are generated from your locally stored Career Road information. Review every document before using it for an application, promotion process, or official record.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await _saveIdentity();
      await action();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _previewResume(AppState app) => _run(() async {
    await Printing.layoutPdf(
      name: 'FireOps_Professional_Resume.pdf',
      onLayout: (_) => CareerPdfExport.buildResume(
        app: app,
        records: _records,
        identity: _identity,
      ),
    );
  });

  Future<void> _shareResume(AppState app) => _run(() async {
    final bytes = await CareerPdfExport.buildResume(
      app: app,
      records: _records,
      identity: _identity,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'FireOps_Professional_Resume.pdf',
    );
  });

  Future<void> _previewPromotion(AppState app) => _run(() async {
    await Printing.layoutPdf(
      name: 'FireOps_Promotion_Packet.pdf',
      onLayout: (_) => CareerPdfExport.buildPromotionPacket(
        app: app,
        records: _records,
        identity: _identity,
      ),
    );
  });

  Future<void> _sharePromotion(AppState app) => _run(() async {
    final bytes = await CareerPdfExport.buildPromotionPacket(
      app: app,
      records: _records,
      identity: _identity,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'FireOps_Promotion_Packet.pdf',
    );
  });

  Future<void> _previewPortfolio(AppState app) => _run(() async {
    await Printing.layoutPdf(
      name: 'FireOps_Career_Portfolio.pdf',
      onLayout: (_) => CareerPdfExport.buildCareerPortfolio(
        app: app,
        records: _records,
        identity: _identity,
      ),
    );
  });

  Future<void> _sharePortfolio(AppState app) => _run(() async {
    final bytes = await CareerPdfExport.buildCareerPortfolio(
      app: app,
      records: _records,
      identity: _identity,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'FireOps_Career_Portfolio.pdf',
    );
  });
}

class _ExportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onPreview;
  final VoidCallback? onShare;

  const _ExportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPreview,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Preview / Print'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Share PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
