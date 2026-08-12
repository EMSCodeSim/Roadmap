import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/advancement_analyzer.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/state/app_state.dart';

class CareerHubPage extends StatefulWidget {
  const CareerHubPage({super.key});

  @override
  State<CareerHubPage> createState() => _CareerHubPageState();
}

class _CareerHubPageState extends State<CareerHubPage> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = <CareerRecord>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _store.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _saveRecord(CareerRecord record) async {
    final next = [..._records, record]..sort((a, b) => b.date.compareTo(a.date));
    await _store.save(next);
    if (!mounted) return;
    setState(() => _records = next);
  }

  Future<void> _openVault() async {
    await context.push(AppRoutes.careerVault);
    await _load();
  }

  Future<void> _showBrief(AppState app) async {
    final brief = AdvancementAnalyzer.buildPromotionBrief(app: app, records: _records);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Promotion prep brief'),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: SelectableText(
              brief,
              style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: brief));
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion brief copied.')));
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy brief'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRecommendation(AppState app, AdvancementAnalysis analysis) async {
    final recommendation = analysis.recommendation;
    switch (recommendation.kind) {
      case AdvancementActionKind.chooseGoal:
      case AdvancementActionKind.workRoadmap:
        context.go(AppRoutes.myPath);
        return;
      case AdvancementActionKind.documentRequirement:
        final status = analysis.requirementStatuses
            .where((item) => item.requirement.id == recommendation.requirementId)
            .firstOrNull;
        await _captureEvidence(app: app, requirementStatus: status);
        return;
      case AdvancementActionKind.buildCompetency:
        final competency = analysis.competencies
            .where((item) => item.id == recommendation.competencyId)
            .firstOrNull;
        await _captureEvidence(app: app, competency: competency);
        return;
      case AdvancementActionKind.maintainMomentum:
        await _openVault();
        return;
    }
  }

  Future<void> _captureEvidence({
    required AppState app,
    RequirementEvidenceStatus? requirementStatus,
    AdvancementCompetency? competency,
  }) async {
    final now = DateTime.now();
    final requirement = requirementStatus?.requirement;
    var type = competency?.suggestedType ?? _suggestedTypeForRequirement(requirement);
    var highlight = false;

    final title = TextEditingController(
      text: requirement == null ? '' : 'Evidence for ${requirement.name}',
    );
    final role = TextEditingController();
    final summary = TextEditingController();
    final impact = TextEditingController();
    final evidence = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<CareerRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(requirement != null ? 'Document roadmap evidence' : 'Add promotion example'),
          content: SizedBox(
            width: 650,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (requirement != null)
                      _CaptureContextBanner(
                        icon: Icons.route_outlined,
                        title: requirement.name,
                        text: 'This record will be linked directly to your ${app.selectedGoal?.title ?? 'current'} roadmap.',
                      )
                    else if (competency != null)
                      _CaptureContextBanner(
                        icon: Icons.track_changes_outlined,
                        title: competency.title,
                        text: competency.capturePrompt,
                      ),
                    if (requirement != null || competency != null) const SizedBox(height: 14),
                    Text(
                      'Write enough context that you can understand and reuse this example years from now. Do not enter patient names, addresses, DOBs, or other identifying information.',
                      style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                            color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<CareerRecordType>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Evidence type'),
                      items: CareerRecordType.values
                          .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setDialogState(() => type = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: title,
                      autofocus: requirement == null,
                      decoration: const InputDecoration(
                        labelText: 'Short title',
                        hintText: 'Led multi-company drill, resolved crew conflict, completed FO1 assignment…',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Add a short title.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: role,
                      decoration: const InputDecoration(
                        labelText: 'Your role',
                        hintText: 'Acting officer, instructor, project lead, firefighter…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: summary,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Situation and your actions',
                        hintText: 'What was happening, what responsibility did you have, and what did you personally do?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: impact,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Result / impact',
                        hintText: 'What changed, improved, was completed, or was learned?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: evidence,
                      decoration: const InputDecoration(
                        labelText: 'Evidence reference (optional)',
                        hintText: 'Task-book page, evaluation, training record, award letter, project file…',
                      ),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: highlight,
                      onChanged: (value) => setDialogState(() => highlight = value ?? false),
                      title: const Text('Add to promotion story bank'),
                      subtitle: const Text('Use this when it is a strong example you may want for interviews, resumes, or performance reviews.'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final goal = app.selectedGoal;
                final tags = <String>{
                  'promotion',
                  if (goal != null) goal.title,
                  if (competency != null) competency.title,
                }.toList();
                Navigator.pop(
                  dialogContext,
                  CareerRecord(
                    id: now.microsecondsSinceEpoch.toRadixString(36),
                    type: type,
                    title: title.text.trim(),
                    category: competency?.title ?? requirement?.category ?? 'Professional development',
                    date: now,
                    roleOrAssignment: _nullable(role.text),
                    summary: _nullable(summary.text),
                    impact: _nullable(impact.text),
                    evidenceReference: _nullable(evidence.text),
                    hours: null,
                    repetitions: 1,
                    tags: tags,
                    relatedGoalId: goal?.id,
                    relatedRequirementId: requirement?.id,
                    highlight: highlight,
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
              },
              child: const Text('Save evidence'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    role.dispose();
    summary.dispose();
    impact.dispose();
    evidence.dispose();

    if (result != null) {
      await _saveRecord(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Career evidence saved.')));
    }
  }

  CareerRecordType _suggestedTypeForRequirement(Requirement? requirement) {
    if (requirement == null) return CareerRecordType.leadership;
    return switch (requirement.type) {
      RequirementType.taskBook => CareerRecordType.taskBookEvidence,
      RequirementType.experience => CareerRecordType.operationalExperience,
      RequirementType.trainingCourse => CareerRecordType.training,
      RequirementType.course => CareerRecordType.training,
      RequirementType.education => CareerRecordType.education,
      RequirementType.practical => CareerRecordType.skill,
      RequirementType.promotionalTest => CareerRecordType.training,
      RequirementType.interview => CareerRecordType.leadership,
      RequirementType.numericProgress => CareerRecordType.skill,
      RequirementType.custom => CareerRecordType.achievement,
      RequirementType.certification => CareerRecordType.training,
    };
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final analysis = AdvancementAnalyzer.analyze(app: app, records: _records);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth'),
        actions: [
          IconButton(
            tooltip: 'Promotion prep brief',
            onPressed: _loading ? null : () => _showBrief(app),
            icon: const Icon(Icons.description_outlined),
          ),
          IconButton(
            tooltip: 'Career Vault',
            onPressed: _loading ? null : _openVault,
            icon: const Icon(Icons.inventory_2_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                children: [
                  _ReadinessHero(
                    analysis: analysis,
                    onChangeGoal: () => context.go(AppRoutes.myPath),
                  ),
                  const SizedBox(height: 12),
                  _NextMoveCard(
                    recommendation: analysis.recommendation,
                    onAction: () => _handleRecommendation(app, analysis),
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeading(
                    title: 'Promotion Readiness',
                    subtitle: 'Four areas that make you more competitive for the next position.',
                  ),
                  const SizedBox(height: 9),
                  _ProgressPanel(
                    icon: Icons.route_outlined,
                    label: 'Qualifications',
                    value: analysis.roadmapProgress,
                    valueText: analysis.totalRequirements == 0
                        ? 'No target'
                        : '${analysis.completedRequirements}/${analysis.totalRequirements}',
                    detail: 'Roadmap requirements completed for your selected path.',
                  ),
                  const SizedBox(height: 8),
                  _ProgressPanel(
                    icon: Icons.attach_file_outlined,
                    label: 'Experience Evidence',
                    value: analysis.evidenceProgress,
                    valueText: analysis.evidenceExpected == 0
                        ? '—'
                        : '${analysis.evidenceCovered}/${analysis.evidenceExpected}',
                    detail: 'Proof/examples linked so you can recall them later.',
                  ),
                  const SizedBox(height: 8),
                  _ProgressPanel(
                    icon: Icons.hub_outlined,
                    label: 'Leadership / Competencies',
                    value: analysis.competencyProgress,
                    valueText: '${analysis.supportedCompetencies}/${analysis.totalCompetencies}',
                    detail: 'Breadth across leadership, communication, safety, projects, and more.',
                  ),
                  const SizedBox(height: 8),
                  _ProgressPanel(
                    icon: Icons.auto_stories_outlined,
                    label: 'Interview Stories',
                    value: (analysis.storyReadyCount / 5).clamp(0.0, 1.0).toDouble(),
                    valueText: '${analysis.storyReadyCount}/5+',
                    detail: 'Stories documented clearly enough to reuse later.',
                  ),
                  const SizedBox(height: 18),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text('Tools', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    children: [
                      const SizedBox(height: 8),
                      _QuickNavigation(
                        onRoadmap: () => context.go(AppRoutes.myPath),
                        onVault: _openVault,
                        onBrief: () => _showBrief(app),
                        onCerts: () => context.go(AppRoutes.certifications),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionHeading(
                    title: 'Best Next Evidence',
                    subtitle: analysis.goalTitle == null
                        ? 'Choose an advancement target to see which roadmap requirements need supporting career evidence.'
                        : 'These are the strongest places to document examples now so you are not trying to remember them years later.',
                  ),
                  const SizedBox(height: 9),
                  if (analysis.goalTitle == null)
                    _CalloutCard(
                      icon: Icons.flag_outlined,
                      title: 'Select your next role',
                      text: 'Once a target is selected, FireOps can compare your roadmap with your Career Vault and prioritize missing proof.',
                      actionLabel: 'Choose roadmap',
                      onAction: () => context.go(AppRoutes.myPath),
                    )
                  else if (analysis.evidenceGaps.isEmpty)
                    const _PositiveCard(
                      icon: Icons.verified_outlined,
                      title: 'No roadmap evidence gaps identified',
                      text: 'Your evidence-worthy roadmap items all have at least one linked career record. Keep adding strong examples as your responsibilities grow.',
                    )
                  else
                    ...analysis.evidenceGaps.take(5).map(
                          (gap) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _EvidenceGapCard(
                              status: gap,
                              onAdd: () => _captureEvidence(app: app, requirementStatus: gap),
                            ),
                          ),
                        ),
                  const SizedBox(height: 22),
                  const _SectionHeading(
                    title: 'Promotion competency map',
                    subtitle: 'A broad officer or promotional file needs more than certificates. Build examples across the situations interview panels and supervisors commonly ask about.',
                  ),
                  const SizedBox(height: 9),
                  ...analysis.competencies.map(
                    (competency) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CompetencyCard(
                        competency: competency,
                        onCapture: () => _captureEvidence(app: app, competency: competency),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: _SectionHeading(
                          title: 'Promotion story bank',
                          subtitle: 'Strong examples you can reuse for interviews, resumes, evaluations, and future applications.',
                        ),
                      ),
                      TextButton(onPressed: _openVault, child: const Text('Open Vault')),
                    ],
                  ),
                  const SizedBox(height: 9),
                  if (analysis.promotionStories.isEmpty)
                    _CalloutCard(
                      icon: Icons.auto_stories_outlined,
                      title: 'Start collecting career stories',
                      text: 'Document meaningful leadership decisions, projects, teaching, difficult calls, awards, and task-book work with your actions and the result.',
                      actionLabel: 'Add first story',
                      onAction: () => _captureEvidence(
                        app: app,
                        competency: analysis.competencies.where((e) => e.id == 'leadership').firstOrNull,
                      ),
                    )
                  else
                    ...analysis.promotionStories.take(5).map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _StoryCard(record: record),
                          ),
                        ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Professional Growth is a personal planning and memory tool. It does not determine official promotional eligibility. Verify requirements, task-book completion, credentials, and documentation with your department and credentialing bodies.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReadinessHero extends StatelessWidget {
  final AdvancementAnalysis analysis;
  final VoidCallback onChangeGoal;

  const _ReadinessHero({required this.analysis, required this.onChangeGoal});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasGoal = analysis.goalTitle != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 82,
              height: 82,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: hasGoal ? analysis.readinessScore / 100 : 0,
                      strokeWidth: 7,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasGoal ? '${analysis.readinessScore}%' : '—',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text('profile', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasGoal ? 'Target: ${analysis.goalTitle}' : 'Set your advancement target',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysis.readinessLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasGoal
                        ? 'This profile score combines roadmap completion, linked evidence, promotion competency breadth, and reusable career stories.'
                        : 'Choose Engineer, Fire Officer, Lieutenant, Captain, Instructor, or another path so FireOps can prioritize your growth.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onChangeGoal,
                    icon: const Icon(Icons.route_outlined, size: 18),
                    label: Text(hasGoal ? 'Review roadmap' : 'Choose target'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextMoveCard extends StatelessWidget {
  final AdvancementRecommendation recommendation;
  final VoidCallback onAction;

  const _NextMoveCard({required this.recommendation, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.near_me_outlined, color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Text('BEST NEXT MOVE', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
            ],
          ),
          const SizedBox(height: 9),
          Text(recommendation.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(recommendation.reason, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward),
            label: Text(recommendation.actionLabel),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String valueText;
  final String detail;

  const _ProgressPanel({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueText,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: cs.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(valueText, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: value.clamp(0.0, 1.0).toDouble()),
                  const SizedBox(height: 5),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickNavigation extends StatelessWidget {
  final VoidCallback onRoadmap;
  final VoidCallback onVault;
  final VoidCallback onBrief;
  final VoidCallback onCerts;

  const _QuickNavigation({
    required this.onRoadmap,
    required this.onVault,
    required this.onBrief,
    required this.onCerts,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(avatar: const Icon(Icons.route_outlined, size: 18), label: const Text('Roadmap'), onPressed: onRoadmap),
        ActionChip(avatar: const Icon(Icons.inventory_2_outlined, size: 18), label: const Text('Career Vault'), onPressed: onVault),
        ActionChip(avatar: const Icon(Icons.description_outlined, size: 18), label: const Text('Promotion brief'), onPressed: onBrief),
        ActionChip(avatar: const Icon(Icons.verified_outlined, size: 18), label: const Text('Certifications'), onPressed: onCerts),
      ],
    );
  }
}

class _EvidenceGapCard extends StatelessWidget {
  final RequirementEvidenceStatus status;
  final VoidCallback onAdd;

  const _EvidenceGapCard({required this.status, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final requirement = status.requirement;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(requirement.type == RequirementType.taskBook ? Icons.fact_check_outlined : Icons.attach_file_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(requirement.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                _StatusPill(text: status.statusLabel),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              requirement.description.trim().isEmpty
                  ? 'No personal career evidence is linked to this requirement yet.'
                  : requirement.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (status.taskBookProgress != null) ...[
              const SizedBox(height: 9),
              LinearProgressIndicator(value: status.taskBookProgress!.percent),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add evidence'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetencyCard extends StatelessWidget {
  final AdvancementCompetency competency;
  final VoidCallback onCapture;

  const _CompetencyCard({required this.competency, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(competency.supported ? Icons.check_circle_outline : Icons.radio_button_unchecked, size: 20, color: competency.supported ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(competency.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text('${competency.exampleCount}/${competency.targetExamples}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 7),
            LinearProgressIndicator(value: competency.progress),
            const SizedBox(height: 7),
            Text(competency.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            if (!competency.supported) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Build this area'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final CareerRecord record;

  const _StoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ready = (record.roleOrAssignment ?? '').trim().isNotEmpty &&
        (record.summary ?? '').trim().isNotEmpty &&
        (record.impact ?? '').trim().isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(record.highlight ? Icons.star : Icons.auto_stories_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(record.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                _StatusPill(text: ready ? 'Story ready' : 'Add detail'),
              ],
            ),
            const SizedBox(height: 5),
            Text('${record.type.label} • ${_formatDate(record.date)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            if ((record.impact ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 7),
              Text('Result: ${record.impact}', maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}

class _CaptureContextBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _CaptureContextBanner({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.onPrimaryContainer),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;

  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 155),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _CalloutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _CalloutCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 7),
            Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            TextButton.icon(onPressed: onAction, icon: const Icon(Icons.arrow_forward, size: 18), label: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _PositiveCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _PositiveCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _formatDate(DateTime date) {
  const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
