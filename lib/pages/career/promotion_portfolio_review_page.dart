import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/career_pdf_export.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/editable_promotion_portfolio.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';

class PromotionPortfolioReviewPage extends StatefulWidget {
  const PromotionPortfolioReviewPage({super.key});

  @override
  State<PromotionPortfolioReviewPage> createState() =>
      _PromotionPortfolioReviewPageState();
}

class _PromotionPortfolioReviewPageState
    extends State<PromotionPortfolioReviewPage> {
  final CareerRecordStore _recordStore = CareerRecordStore();
  final CareerExportIdentityStore _identityStore = CareerExportIdentityStore();
  final TextEditingController _summary = TextEditingController();

  List<CareerRecord> _records = const [];
  CareerExportIdentity _identity = const CareerExportIdentity(
    name: '',
    email: '',
    phone: '',
    location: '',
  );
  Set<String> _accomplishments = <String>{};
  Set<String> _stories = <String>{};
  bool _strengths = true;
  bool _readiness = true;
  bool _competencies = true;
  bool _leadership = true;
  bool _projects = true;
  bool _credentials = true;
  bool _gaps = true;
  bool _checklist = true;
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    final results = await Future.wait([
      _recordStore.load(),
      _identityStore.load(),
    ]);
    final records = results[0] as List<CareerRecord>;
    final identity = results[1] as CareerExportIdentity;
    final draft = EditablePromotionPortfolio.defaultDraft(
      app: app,
      records: records,
    );
    if (!mounted) return;
    setState(() {
      _records = records;
      _identity = identity;
      _summary.text = draft.executiveSummary;
      _accomplishments = {...draft.accomplishmentIds};
      _stories = {...draft.storyIds};
      _strengths = draft.includeStrengths;
      _readiness = draft.includeReadiness;
      _competencies = draft.includeCompetencies;
      _leadership = draft.includeLeadership;
      _projects = draft.includeProjects;
      _credentials = draft.includeCredentials;
      _gaps = draft.includeGaps;
      _checklist = draft.includeChecklist;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  PromotionPortfolioDraft get _draft => PromotionPortfolioDraft(
        executiveSummary: _summary.text.trim(),
        accomplishmentIds: {..._accomplishments},
        storyIds: {..._stories},
        includeStrengths: _strengths,
        includeReadiness: _readiness,
        includeCompetencies: _competencies,
        includeLeadership: _leadership,
        includeProjects: _projects,
        includeCredentials: _credentials,
        includeGaps: _gaps,
        includeChecklist: _checklist,
      );

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final accomplishmentCandidates =
        EditablePromotionPortfolio.rankedRecords(_records).take(14).toList();
    final storyCandidates =
        EditablePromotionPortfolio.storyCandidates(_records).take(12).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toCareerIntelligence(),
        title: const Text('Review Promotion Portfolio'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
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
                        'Review before you generate.',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        app.selectedGoal == null
                            ? 'Edit the summary, choose the strongest accomplishments and interview stories, and remove any sections you do not want in the packet.'
                            : 'Target: ${app.selectedGoal!.title}. Edit the summary, choose the strongest accomplishments and interview stories, and remove any sections you do not want in the packet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionLabel('CANDIDATE SUMMARY'),
                const SizedBox(height: 8),
                TextField(
                  controller: _summary,
                  minLines: 5,
                  maxLines: 9,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write the summary you want on the first page.',
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _summary.text = EditablePromotionPortfolio.buildExecutiveSummary(
                        app: app,
                        records: _records,
                      );
                    }),
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Restore suggested summary'),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionLabel('SELECTED ACCOMPLISHMENTS'),
                const SizedBox(height: 4),
                Text(
                  'Choose the records you want hiring or promotional reviewers to notice first.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                if (accomplishmentCandidates.isEmpty)
                  const _EmptyBox(
                    text: 'No career records yet. Add accomplishments, projects, leadership, training, or achievements to your Career Record first.',
                  )
                else
                  ...accomplishmentCandidates.map(
                    (r) => _RecordChoice(
                      record: r,
                      selected: _accomplishments.contains(r.id),
                      onChanged: (selected) => setState(() {
                        selected
                            ? _accomplishments.add(r.id)
                            : _accomplishments.remove(r.id);
                      }),
                    ),
                  ),
                const SizedBox(height: 18),
                _SectionLabel('INTERVIEW STORY BANK'),
                const SizedBox(height: 4),
                Text(
                  'Only records with both a situation/action summary and a documented result are suggested here.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                if (storyCandidates.isEmpty)
                  const _EmptyBox(
                    text: 'No interview-ready stories yet. Add a summary and result/impact to strong career records.',
                  )
                else
                  ...storyCandidates.map(
                    (r) => _RecordChoice(
                      record: r,
                      selected: _stories.contains(r.id),
                      story: true,
                      onChanged: (selected) => setState(() {
                        selected ? _stories.add(r.id) : _stories.remove(r.id);
                      }),
                    ),
                  ),
                const SizedBox(height: 18),
                _SectionLabel('INCLUDED SECTIONS'),
                const SizedBox(height: 8),
                _ToggleCard(
                  children: [
                    _switch('Promotion strengths', _strengths,
                        (v) => setState(() => _strengths = v)),
                    _switch('Readiness dashboard', _readiness,
                        (v) => setState(() => _readiness = v)),
                    _switch('Competency map', _competencies,
                        (v) => setState(() => _competencies = v)),
                    _switch('Leadership & instruction', _leadership,
                        (v) => setState(() => _leadership = v)),
                    _switch('Projects & achievements', _projects,
                        (v) => setState(() => _projects = v)),
                    _switch('Credentials', _credentials,
                        (v) => setState(() => _credentials = v)),
                    _switch('Evidence gaps / development plan', _gaps,
                        (v) => setState(() => _gaps = v)),
                    _switch('Portfolio review checklist', _checklist,
                        (v) => setState(() => _checklist = v)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nothing selected here changes your underlying Career Record. These choices only control this generated portfolio.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    top: BorderSide(color: cs.outline.withValues(alpha: .14)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _working ? null : () => _preview(app),
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Preview PDF'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _working ? null : () => _share(app),
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text('Share PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged: onChanged,
      );

  Future<void> _preview(AppState app) => _run(() async {
        await Printing.layoutPdf(
          name: 'FireOps_Promotion_Portfolio.pdf',
          onLayout: (_) => EditablePromotionPortfolio.buildPdf(
            app: app,
            records: _records,
            identity: _identity,
            draft: _draft,
          ),
        );
      });

  Future<void> _share(AppState app) => _run(() async {
        final bytes = await EditablePromotionPortfolio.buildPdf(
          app: app,
          records: _records,
          identity: _identity,
          draft: _draft,
        );
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'FireOps_Promotion_Portfolio.pdf',
        );
      });

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
      );
}

class _RecordChoice extends StatelessWidget {
  final CareerRecord record;
  final bool selected;
  final bool story;
  final ValueChanged<bool> onChanged;

  const _RecordChoice({
    required this.record,
    required this.selected,
    required this.onChanged,
    this.story = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final detail = story
        ? (record.impact ?? '').trim()
        : [(record.roleOrAssignment ?? '').trim(), (record.impact ?? '').trim()]
            .where((e) => e.isNotEmpty)
            .join(' • ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? cs.primaryContainer.withValues(alpha: .42) : cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected
              ? cs.primary.withValues(alpha: .28)
              : cs.outline.withValues(alpha: .14),
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (v) => onChanged(v ?? false),
        title: Text(
          record.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          detail.isEmpty
              ? '${record.type.label} • ${record.date.month}/${record.date.day}/${record.date.year}'
              : '${record.type.label} • $detail',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final List<Widget> children;
  const _ToggleCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .14),
          ),
        ),
        child: Column(children: children),
      );
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(text),
      );
}
