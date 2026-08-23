import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_pdf_export.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/promotion_portfolio_export.dart';
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
    final goal = app.selectedGoal?.title;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toCareerIntelligence(),
        title: const Text('Career Export Center'),
      ),
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
                        'Build a promotion-ready career package.',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        goal == null
                            ? 'Career Road turns the work you have already logged into a professional summary, resume, and promotion portfolio. Choose an advancement goal to make promotion readiness more specific.'
                            : 'Target: $goal. Career Road uses your saved requirements, credentials, leadership, training, projects, achievements, and interview-ready stories to build a promotion-focused package.',
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
                  'PROMOTION TOOLS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _ExportCard(
                  icon: Icons.summarize_outlined,
                  title: 'Professional Career Summary',
                  description:
                      'An executive-style summary with quantified career signals, strongest documented areas, selected accomplishments, credentials, recent momentum, and your next advancement move.',
                  badge: 'Best first document',
                  onPreview: _working ? null : () => _previewCareerSummary(app),
                  onShare: _working ? null : () => _shareCareerSummary(app),
                ),
                const SizedBox(height: 10),
                _ExportCard(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Promotion Portfolio',
                  description:
                      'Review and edit the candidate summary, accomplishments, interview stories, and included sections before any PDF is generated.',
                  badge: goal == null
                      ? 'Review before PDF'
                      : 'Targeted to $goal • Review before PDF',
                  previewLabel: 'Review / Preview',
                  shareLabel: 'Review / Share',
                  onPreview: _working ? null : _openPromotionReview,
                  onShare: _working ? null : _openPromotionReview,
                ),
                const SizedBox(height: 20),
                Text(
                  'OTHER EXPORTS',
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
                  icon: Icons.fact_check_outlined,
                  title: 'Legacy Promotion Preparation Packet',
                  description:
                      'The original readiness, evidence-gap, competency, and interview-story report remains available for comparison and preparation.',
                  onPreview: _working ? null : () => _previewPromotion(app),
                  onShare: _working ? null : () => _sharePromotion(app),
                ),
                const SizedBox(height: 10),
                _ExportCard(
                  icon: Icons.auto_stories_outlined,
                  title: 'Full Career Portfolio',
                  description:
                      'A broader professional history with career totals, credentials, highlights, advancement readiness, and development priorities.',
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

  Future<void> _openPromotionReview() async {
    await _saveIdentity();
    if (!mounted) return;
    await context.push(AppRoutes.promotionPortfolioReview);
  }

  Future<void> _previewCareerSummary(AppState app) => _run(() async {
    await Printing.layoutPdf(
      name: 'FireOps_Professional_Career_Summary.pdf',
      onLayout: (_) => PromotionPortfolioExport.buildCareerSummary(
        app: app,
        records: _records,
        identity: _identity,
      ),
    );
  });

  Future<void> _shareCareerSummary(AppState app) => _run(() async {
    final bytes = await PromotionPortfolioExport.buildCareerSummary(
      app: app,
      records: _records,
      identity: _identity,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'FireOps_Professional_Career_Summary.pdf',
    );
  });

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
  final String? badge;
  final String previewLabel;
  final String shareLabel;
  final VoidCallback? onPreview;
  final VoidCallback? onShare;

  const _ExportCard({
    required this.icon,
    required this.title,
    required this.description,
    this.badge,
    this.previewLabel = 'Preview / Print',
    this.shareLabel = 'Share PDF',
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
          if ((badge ?? '').isNotEmpty) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
                  label: Text(previewLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(shareLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
