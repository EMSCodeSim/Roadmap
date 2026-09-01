import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/advancement_analyzer.dart';
import 'package:firepath/services/career_intelligence.dart';
import 'package:firepath/services/career_pdf_export.dart';
import 'package:firepath/state/app_state.dart';

class PromotionPortfolioDraft {
  final String executiveSummary;
  final Set<String> accomplishmentIds;
  final Set<String> storyIds;
  final bool includeStrengths;
  final bool includeReadiness;
  final bool includeCompetencies;
  final bool includeLeadership;
  final bool includeProjects;
  final bool includeCredentials;
  final bool includeGaps;
  final bool includeChecklist;

  const PromotionPortfolioDraft({
    required this.executiveSummary,
    required this.accomplishmentIds,
    required this.storyIds,
    required this.includeStrengths,
    required this.includeReadiness,
    required this.includeCompetencies,
    required this.includeLeadership,
    required this.includeProjects,
    required this.includeCredentials,
    required this.includeGaps,
    required this.includeChecklist,
  });
}

class EditablePromotionPortfolio {
  const EditablePromotionPortfolio._();

  static PromotionPortfolioDraft defaultDraft({
    required AppState app,
    required List<CareerRecord> records,
  }) {
    final accomplishments = rankedRecords(records).take(7).map((e) => e.id).toSet();
    final stories = storyCandidates(records).take(6).map((e) => e.id).toSet();
    return PromotionPortfolioDraft(
      executiveSummary: buildExecutiveSummary(app: app, records: records),
      accomplishmentIds: accomplishments,
      storyIds: stories,
      includeStrengths: true,
      includeReadiness: true,
      includeCompetencies: true,
      includeLeadership: true,
      includeProjects: true,
      includeCredentials: true,
      includeGaps: true,
      includeChecklist: true,
    );
  }

  static String buildExecutiveSummary({
    required AppState app,
    required List<CareerRecord> records,
  }) {
    final snapshot = CareerIntelligence.analyze(records);
    final advancement = AdvancementAnalyzer.analyze(app: app, records: records);
    final roles = app.profile.currentRoles.isEmpty
        ? 'fire / EMS professional'
        : app.profile.currentRoles.join(', ');
    final years = app.profile.yearsOfService;
    final parts = <String>[
      '${years == null ? 'Experienced' : '$years-year'} $roles with ${snapshot.totalRecords} documented career activities across ${snapshot.yearsDocumented} year${snapshot.yearsDocumented == 1 ? '' : 's'}.',
    ];
    if (snapshot.totalHours > 0) {
      parts.add('${snapshot.totalHours.toStringAsFixed(1)} documented hours are currently captured in Career Road.');
    }
    if (snapshot.strongestArea != null) {
      parts.add('The strongest documented career area is ${snapshot.strongestArea!.type.label.toLowerCase()}.');
    }
    if (app.selectedGoal != null) {
      parts.add('Current advancement target: ${app.selectedGoal!.title}, with a Career Road readiness indicator of ${advancement.readinessScore}%.');
    }
    return parts.join(' ');
  }

  static List<CareerRecord> rankedRecords(List<CareerRecord> records) {
    final list = [...records];
    list.sort((a, b) {
      final byScore = _score(b).compareTo(_score(a));
      if (byScore != 0) return byScore;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  static List<CareerRecord> storyCandidates(List<CareerRecord> records) =>
      rankedRecords(records)
          .where(
            (r) =>
                (r.summary ?? '').trim().isNotEmpty &&
                (r.impact ?? '').trim().isNotEmpty,
          )
          .toList();

  static int _score(CareerRecord r) {
    var score = 0;
    if (r.highlight) score += 6;
    if (r.type == CareerRecordType.leadership) score += 5;
    if (r.type == CareerRecordType.project) score += 5;
    if (r.type == CareerRecordType.achievement) score += 5;
    if (r.type == CareerRecordType.teaching) score += 4;
    if ((r.impact ?? '').trim().isNotEmpty) score += 4;
    if ((r.summary ?? '').trim().isNotEmpty) score += 2;
    if ((r.roleOrAssignment ?? '').trim().isNotEmpty) score += 2;
    return score;
  }

  static Future<Uint8List> buildPdf({
    required AppState app,
    required List<CareerRecord> records,
    required CareerExportIdentity identity,
    required PromotionPortfolioDraft draft,
  }) async {
    final advancement = AdvancementAnalyzer.analyze(app: app, records: records);
    final snapshot = CareerIntelligence.analyze(records);
    final byId = {for (final r in records) r.id: r};
    final accomplishments = draft.accomplishmentIds
        .map((id) => byId[id])
        .whereType<CareerRecord>()
        .toList()
      ..sort((a, b) => _score(b).compareTo(_score(a)));
    final stories = draft.storyIds
        .map((id) => byId[id])
        .whereType<CareerRecord>()
        .toList()
      ..sort((a, b) => _score(b).compareTo(_score(a)));
    final leadership = rankedRecords(records)
        .where((r) => r.type == CareerRecordType.leadership || r.type == CareerRecordType.teaching)
        .take(10)
        .toList();
    final projects = rankedRecords(records)
        .where((r) => r.type == CareerRecordType.project || r.type == CareerRecordType.achievement)
        .take(10)
        .toList();

    final doc = pw.Document(title: 'Promotion Portfolio');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 34),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        ),
        build: (context) => [
          _header(identity, app),
          pw.SizedBox(height: 14),
          _summaryStrip([
            ('Readiness', '${advancement.readinessScore}%'),
            ('Requirements', '${advancement.completedRequirements}/${advancement.totalRequirements}'),
            ('Evidence', '${advancement.evidenceCovered}/${advancement.evidenceExpected}'),
            ('Stories', '${stories.length}'),
          ]),
          pw.SizedBox(height: 16),
          _section('Candidate Profile'),
          _body(draft.executiveSummary.trim().isEmpty ? buildExecutiveSummary(app: app, records: records) : draft.executiveSummary.trim()),
          if (app.selectedGoal != null) _body('Target position: ${app.selectedGoal!.title}'),
          if ((app.profile.departmentName ?? '').trim().isNotEmpty) _body('Current department: ${app.profile.departmentName!.trim()}'),
          if (app.profile.yearsOfService != null) _body('Years of service: ${app.profile.yearsOfService}'),
          if (accomplishments.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _section('Selected Accomplishments'),
            ...accomplishments.map(_recordBullet),
          ],
          if (draft.includeStrengths) ...[
            pw.SizedBox(height: 12),
            _section('Promotion Strengths'),
            ..._strengths(snapshot, advancement, records).map((s) => _callout(s.$1, s.$2)),
          ],
          if (draft.includeReadiness) ...[
            pw.SizedBox(height: 12),
            _section('Readiness Dashboard'),
            _bullet('Qualifications: ${advancement.completedRequirements}/${advancement.totalRequirements} requirements completed.'),
            _bullet('Experience evidence: ${advancement.evidenceCovered}/${advancement.evidenceExpected} evidence areas supported.'),
            _bullet('Competencies: ${advancement.supportedCompetencies}/${advancement.totalCompetencies} supported.'),
            _bullet('Interview-ready stories selected: ${stories.length}.'),
          ],
          if (draft.includeCompetencies) ...[
            pw.SizedBox(height: 12),
            _section('Promotion Competency Map'),
            ...advancement.competencies.map((c) => _bullet('${c.title}: ${c.exampleCount}/${c.targetExamples} documented examples${c.supported ? ' — supported' : ' — build more evidence'}')),
          ],
          pw.SizedBox(height: 12),
          _section('Interview Story Bank'),
          if (stories.isEmpty)
            _bullet('No interview stories selected. Add records with a clear situation, your role/action, and the result.')
          else
            ...stories.map(_storyBlock),
          if (draft.includeLeadership) ...[
            pw.SizedBox(height: 12),
            _section('Leadership & Instruction Evidence'),
            if (leadership.isEmpty) _bullet('No leadership or teaching records selected by the career record yet.') else ...leadership.map(_recordBullet),
          ],
          if (draft.includeProjects) ...[
            pw.SizedBox(height: 12),
            _section('Projects, Achievements & Impact'),
            if (projects.isEmpty) _bullet('No project or achievement records documented yet.') else ...projects.map(_recordBullet),
          ],
          if (draft.includeCredentials) ...[
            pw.SizedBox(height: 12),
            _section('Credentials'),
            ...app.certifications.where((c) => c.status.name != 'expired').take(24).map((c) => _bullet(app.certificationDisplayName(c))),
          ],
          if (draft.includeGaps) ...[
            pw.SizedBox(height: 12),
            _section('Evidence Gaps / Development Plan'),
            if (advancement.evidenceGaps.isEmpty)
              _bullet('No current roadmap evidence gaps identified.')
            else
              ...advancement.evidenceGaps.take(10).map((g) => _bullet('${g.requirement.name} — ${g.isComplete ? 'requirement is complete but supporting career evidence is missing' : 'requirement and supporting evidence still need attention'}')),
            _callout(advancement.recommendation.title, advancement.recommendation.reason),
          ],
          if (draft.includeChecklist) ...[
            pw.SizedBox(height: 12),
            _section('Portfolio Review Checklist'),
            _bullet('Verify department-specific eligibility and promotional requirements.'),
            _bullet('Confirm certifications and expiration dates against official records.'),
            _bullet('Use examples that clearly show your role, actions, and result.'),
            _bullet('Bring supporting documentation when allowed by the promotion process.'),
          ],
          pw.SizedBox(height: 12),
          pw.Text('Generated from the user\'s locally stored Career Road information. Review this packet before using it for an application, promotion process, or official record.', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        ],
      ),
    );
    return doc.save();
  }

  static final PdfColor _navy = PdfColor.fromHex('#0B1F33');
  static final PdfColor _gold = PdfColor.fromHex('#B78A3B');
  static final PdfColor _light = PdfColor.fromHex('#EEF2F5');

  static pw.Widget _header(CareerExportIdentity identity, AppState app) {
    final name = identity.name.trim().isEmpty
        ? (app.profile.currentRoles.isEmpty ? 'Fire / EMS Professional' : app.profile.currentRoles.join(', '))
        : identity.name.trim();
    final contact = [identity.email, identity.phone, identity.location]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(' • ');
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(color: _navy, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PROMOTION PORTFOLIO', style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(name, style: pw.TextStyle(color: _gold, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (contact.isNotEmpty) pw.Text(contact, style: const pw.TextStyle(color: PdfColors.white, fontSize: 8.5)),
              ],
            ),
          ),
          pw.Text('Responder Roadmap', style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _summaryStrip(List<(String, String)> metrics) => pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(color: _light, borderRadius: pw.BorderRadius.circular(4)),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: metrics.map((m) => pw.Column(children: [
        pw.Text(m.$2, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _navy)),
        pw.Text(m.$1, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
      ])).toList(),
    ),
  );

  static pw.Widget _section(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _navy)),
  );

  static pw.Widget _body(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2)),
  );

  static pw.Widget _bullet(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('• ', style: pw.TextStyle(color: _gold, fontWeight: pw.FontWeight.bold)),
      pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 9.2, lineSpacing: 2))),
    ]),
  );

  static pw.Widget _recordBullet(CareerRecord r) {
    final impact = (r.impact ?? '').trim();
    final role = (r.roleOrAssignment ?? '').trim();
    final extra = [if (role.isNotEmpty) role, if (impact.isNotEmpty) impact].join(' — ');
    return _bullet('${r.date.month}/${r.date.day}/${r.date.year} — ${r.title}${extra.isEmpty ? '' : ': $extra'}');
  }

  static pw.Widget _storyBlock(CareerRecord r) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 7),
    padding: const pw.EdgeInsets.all(9),
    decoration: pw.BoxDecoration(color: _light, borderRadius: pw.BorderRadius.circular(4)),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(r.title, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _navy)),
      if ((r.roleOrAssignment ?? '').trim().isNotEmpty) pw.Text('Role: ${r.roleOrAssignment!.trim()}', style: const pw.TextStyle(fontSize: 8.5)),
      if ((r.summary ?? '').trim().isNotEmpty) pw.Text('Situation / action: ${r.summary!.trim()}', style: const pw.TextStyle(fontSize: 8.5)),
      if ((r.impact ?? '').trim().isNotEmpty) pw.Text('Result / impact: ${r.impact!.trim()}', style: const pw.TextStyle(fontSize: 8.5)),
    ]),
  );

  static pw.Widget _callout(String title, String detail) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 6),
    padding: const pw.EdgeInsets.all(9),
    decoration: pw.BoxDecoration(color: _light, borderRadius: pw.BorderRadius.circular(4)),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title, style: pw.TextStyle(fontSize: 9.3, fontWeight: pw.FontWeight.bold, color: _navy)),
      pw.SizedBox(height: 2),
      pw.Text(detail, style: const pw.TextStyle(fontSize: 8.7, lineSpacing: 2)),
    ]),
  );

  static List<(String, String)> _strengths(
    CareerIntelligenceSnapshot snapshot,
    AdvancementAnalysis advancement,
    List<CareerRecord> records,
  ) {
    final out = <(String, String)>[];
    for (final c in advancement.competencies.where((c) => c.supported).take(3)) {
      out.add((c.title, '${c.exampleCount} documented examples support this competency.'));
    }
    if (out.length < 3 && snapshot.strongestArea != null) {
      out.add((snapshot.strongestArea!.type.label, '${snapshot.strongestArea!.count} records make this one of the strongest documented areas.'));
    }
    final impactCount = records.where((r) => (r.impact ?? '').trim().isNotEmpty).length;
    if (out.length < 4 && impactCount > 0) out.add(('Results / impact', '$impactCount records include a documented result or impact statement.'));
    if (out.isEmpty) out.add(('Career record foundation', 'Continue documenting meaningful work so evidence-backed strengths can be surfaced.'));
    return out.take(4).toList();
  }
}
