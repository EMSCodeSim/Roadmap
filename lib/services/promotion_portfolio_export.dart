import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/advancement_analyzer.dart';
import 'package:firepath/services/career_intelligence.dart';
import 'package:firepath/services/career_pdf_export.dart';
import 'package:firepath/state/app_state.dart';

class PromotionPortfolioExport {
  const PromotionPortfolioExport._();

  static final PdfColor _navy = PdfColor.fromHex('#0B1F33');
  static final PdfColor _gold = PdfColor.fromHex('#B78A3B');
  static final PdfColor _light = PdfColor.fromHex('#EEF2F5');
  static final PdfColor _green = PdfColor.fromHex('#2E6B57');

  static Future<Uint8List> buildCareerSummary({
    required AppState app,
    required List<CareerRecord> records,
    required CareerExportIdentity identity,
  }) async {
    final snapshot = CareerIntelligence.analyze(records);
    final advancement = AdvancementAnalyzer.analyze(app: app, records: records);
    final recent = [...records]..sort((a, b) => b.date.compareTo(a.date));
    final strengths = _strengths(snapshot, advancement, records);
    final doc = pw.Document(title: 'Professional Career Summary');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 34),
        footer: _footer,
        build: (context) => [
          _header(identity, 'PROFESSIONAL CAREER SUMMARY', app),
          pw.SizedBox(height: 14),
          _summaryStrip([
            ('Career records', '${snapshot.totalRecords}'),
            ('Years captured', '${snapshot.yearsDocumented}'),
            ('Documented hours', snapshot.totalHours.toStringAsFixed(1)),
            ('Promotion readiness', '${advancement.readinessScore}%'),
          ]),
          pw.SizedBox(height: 16),
          _sectionTitle('Executive Summary'),
          _body(_executiveSummary(app, snapshot, advancement, records)),
          pw.SizedBox(height: 10),
          _sectionTitle('Promotion Strengths'),
          ...strengths.map(_strengthBox),
          pw.SizedBox(height: 10),
          _sectionTitle('Career Evidence at a Glance'),
          _evidenceTable(snapshot),
          pw.SizedBox(height: 10),
          _sectionTitle('Selected Accomplishments'),
          ..._recordBullets(_bestRecords(records).take(7)),
          pw.SizedBox(height: 10),
          _sectionTitle('Current Credentials'),
          ..._credentialLines(app, limit: 16),
          pw.SizedBox(height: 10),
          _sectionTitle('Next Advancement Move'),
          _callout(
            advancement.recommendation.title,
            advancement.recommendation.reason,
          ),
          if (recent.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _sectionTitle('Recent Momentum'),
            ..._recordBullets(recent.take(5)),
          ],
          pw.SizedBox(height: 10),
          _disclaimer(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildPromotionPortfolio({
    required AppState app,
    required List<CareerRecord> records,
    required CareerExportIdentity identity,
  }) async {
    final snapshot = CareerIntelligence.analyze(records);
    final advancement = AdvancementAnalyzer.analyze(app: app, records: records);
    final stories = _bestStories(advancement, records);
    final strengths = _strengths(snapshot, advancement, records);
    final leadership = _recordsOf(records, {
      CareerRecordType.leadership,
      CareerRecordType.teaching,
    });
    final projects = _recordsOf(records, {
      CareerRecordType.project,
      CareerRecordType.achievement,
    });
    final doc = pw.Document(title: 'Promotion Portfolio');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 34),
        footer: _footer,
        build: (context) => [
          _header(identity, 'PROMOTION PORTFOLIO', app),
          pw.SizedBox(height: 14),
          _summaryStrip([
            ('Readiness', '${advancement.readinessScore}%'),
            ('Requirements', '${advancement.completedRequirements}/${advancement.totalRequirements}'),
            ('Evidence', '${advancement.evidenceCovered}/${advancement.evidenceExpected}'),
            ('Interview stories', '${advancement.storyReadyCount}'),
          ]),
          pw.SizedBox(height: 16),
          _sectionTitle('Candidate Profile'),
          _body(_executiveSummary(app, snapshot, advancement, records)),
          if (app.selectedGoal != null)
            _body('Target position: ${app.selectedGoal!.title}'),
          if ((app.profile.departmentName ?? '').trim().isNotEmpty)
            _body('Current department: ${app.profile.departmentName!.trim()}'),
          if (app.profile.yearsOfService != null)
            _body('Years of service: ${app.profile.yearsOfService}'),
          pw.SizedBox(height: 10),
          _sectionTitle('Promotion Strengths'),
          ...strengths.map(_strengthBox),
          pw.SizedBox(height: 12),
          _sectionTitle('Readiness Dashboard'),
          _readinessTable(advancement),
          pw.SizedBox(height: 12),
          _sectionTitle('Promotion Competency Map'),
          ...advancement.competencies.map(
            (c) => _statusRow(
              c.title,
              '${c.exampleCount}/${c.targetExamples} documented examples',
              c.supported,
            ),
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Interview Story Bank'),
          if (stories.isEmpty)
            _bullet('No interview-ready stories yet. Add records with your role, actions, and measurable result.')
          else
            ...stories.take(10).map(_storyBlock),
          pw.SizedBox(height: 12),
          _sectionTitle('Leadership & Instruction Evidence'),
          ..._recordBullets(leadership.take(10)),
          pw.SizedBox(height: 12),
          _sectionTitle('Projects, Achievements & Impact'),
          ..._recordBullets(projects.take(10)),
          pw.SizedBox(height: 12),
          _sectionTitle('Credentials'),
          ..._credentialLines(app, limit: 24),
          pw.SizedBox(height: 12),
          _sectionTitle('Evidence Gaps / Development Plan'),
          if (advancement.evidenceGaps.isEmpty)
            _bullet('No current roadmap evidence gaps identified.')
          else
            ...advancement.evidenceGaps.take(10).map(
              (gap) => _bullet(
                '${gap.requirement.name} — ${gap.isComplete ? 'requirement is complete but supporting career evidence is missing' : 'requirement and supporting evidence still need attention'}',
              ),
            ),
          pw.SizedBox(height: 8),
          _callout(
            advancement.recommendation.title,
            advancement.recommendation.reason,
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Portfolio Review Checklist'),
          _bullet('Verify department-specific eligibility and promotional requirements.'),
          _bullet('Confirm certifications and expiration dates against official records.'),
          _bullet('Replace vague stories with examples that clearly show your role, action, and result.'),
          _bullet('Bring supporting documents for major projects, awards, training, or evaluations when allowed.'),
          _bullet('Review this packet before submission; it is generated from your personal Career Road data.'),
          pw.SizedBox(height: 10),
          _disclaimer(),
        ],
      ),
    );
    return doc.save();
  }

  static String _executiveSummary(
    AppState app,
    CareerIntelligenceSnapshot snapshot,
    AdvancementAnalysis advancement,
    List<CareerRecord> records,
  ) {
    final role = app.profile.currentRoles.isEmpty
        ? 'fire / EMS professional'
        : app.profile.currentRoles.join(', ');
    final years = app.profile.yearsOfService;
    final parts = <String>[
      '${years == null ? 'Experienced' : '$years-year'} $role with ${snapshot.totalRecords} documented career activities across ${snapshot.yearsDocumented} year${snapshot.yearsDocumented == 1 ? '' : 's'}.',
    ];
    if (snapshot.totalHours > 0) {
      parts.add('${snapshot.totalHours.toStringAsFixed(1)} hours of training, education, driving, instruction, or other career activity are currently captured.');
    }
    if (snapshot.strongestArea != null) {
      parts.add('The strongest documented evidence area is ${snapshot.strongestArea!.type.label.toLowerCase()}.');
    }
    if (app.selectedGoal != null) {
      parts.add('Current advancement target: ${app.selectedGoal!.title}, with a Career Road readiness indicator of ${advancement.readinessScore}%.');
    }
    final readyStories = records.where((r) => _storyReady(r)).length;
    if (readyStories > 0) {
      parts.add('$readyStories career example${readyStories == 1 ? '' : 's'} currently contain enough context and impact to support interview preparation.');
    }
    return parts.join(' ');
  }

  static List<({String title, String detail})> _strengths(
    CareerIntelligenceSnapshot snapshot,
    AdvancementAnalysis advancement,
    List<CareerRecord> records,
  ) {
    final items = <({String title, String detail})>[];
    final supported = advancement.competencies.where((c) => c.supported).toList();
    for (final c in supported.take(3)) {
      items.add((title: c.title, detail: '${c.exampleCount} documented examples support this competency.'));
    }
    if (items.length < 3 && snapshot.strongestArea != null) {
      items.add((
        title: snapshot.strongestArea!.type.label,
        detail: '${snapshot.strongestArea!.count} records make this one of the best-documented areas in the portfolio.',
      ));
    }
    final impacts = records.where((r) => (r.impact ?? '').trim().isNotEmpty).length;
    if (items.length < 4 && impacts > 0) {
      items.add((
        title: 'Results / impact',
        detail: '$impacts records include a documented result or impact statement.',
      ));
    }
    final highlights = records.where((r) => r.highlight || r.type == CareerRecordType.achievement).length;
    if (items.length < 4 && highlights > 0) {
      items.add((
        title: 'Career accomplishments',
        detail: '$highlights achievements or highlighted career moments are preserved.',
      ));
    }
    if (items.isEmpty) {
      items.add((
        title: 'Career record foundation',
        detail: 'Continue logging meaningful work so Roadmap can surface evidence-backed strengths.',
      ));
    }
    return items.take(4).toList();
  }

  static Iterable<CareerRecord> _bestRecords(List<CareerRecord> records) {
    final list = [...records];
    list.sort((a, b) {
      final aScore = _recordScore(a);
      final bScore = _recordScore(b);
      if (aScore != bScore) return bScore.compareTo(aScore);
      return b.date.compareTo(a.date);
    });
    return list;
  }

  static List<CareerRecord> _bestStories(
    AdvancementAnalysis advancement,
    List<CareerRecord> records,
  ) {
    final merged = <String, CareerRecord>{};
    for (final r in advancement.promotionStories) {
      merged[r.id] = r;
    }
    for (final r in _bestRecords(records).where(_storyReady)) {
      merged[r.id] = r;
    }
    final list = merged.values.toList();
    list.sort((a, b) => _recordScore(b).compareTo(_recordScore(a)));
    return list;
  }

  static int _recordScore(CareerRecord r) {
    var score = 0;
    if (r.highlight) score += 5;
    if (r.type == CareerRecordType.leadership) score += 4;
    if (r.type == CareerRecordType.teaching) score += 3;
    if (r.type == CareerRecordType.project) score += 4;
    if (r.type == CareerRecordType.achievement) score += 4;
    if ((r.summary ?? '').trim().isNotEmpty) score += 2;
    if ((r.impact ?? '').trim().isNotEmpty) score += 4;
    if ((r.roleOrAssignment ?? '').trim().isNotEmpty) score += 2;
    if ((r.evidenceReference ?? '').trim().isNotEmpty) score += 1;
    return score;
  }

  static bool _storyReady(CareerRecord r) =>
      (r.summary ?? '').trim().isNotEmpty &&
      (r.impact ?? '').trim().isNotEmpty;

  static List<CareerRecord> _recordsOf(
    List<CareerRecord> records,
    Set<CareerRecordType> types,
  ) {
    final list = records.where((r) => types.contains(r.type)).toList();
    list.sort((a, b) => _recordScore(b).compareTo(_recordScore(a)));
    return list;
  }

  static pw.Widget _header(
    CareerExportIdentity identity,
    String title,
    AppState app,
  ) {
    final subtitle = identity.name.trim().isNotEmpty
        ? identity.name.trim()
        : (app.profile.currentRoles.isEmpty ? 'Fire / EMS Professional' : app.profile.currentRoles.join(', '));
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (_contactLine(identity).isNotEmpty)
                  pw.Text(
                    _contactLine(identity),
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 8.5),
                  ),
              ],
            ),
          ),
          pw.Text('FireOps Career Road', style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
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

  static pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Text(text.toUpperCase(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _navy)),
      );

  static pw.Widget _body(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2)),
      );

  static pw.Widget _bullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(left: 8, bottom: 3),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('• ', style: pw.TextStyle(color: _gold, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 9.2, lineSpacing: 2))),
        ]),
      );

  static pw.Widget _strengthBox(({String title, String detail}) item) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 5),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: _green, width: 3)),
          color: _light,
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(item.title, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.SizedBox(height: 2),
          pw.Text(item.detail, style: const pw.TextStyle(fontSize: 8.7, color: PdfColors.grey800)),
        ]),
      );

  static pw.Widget _callout(String title, String detail) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#FFF7E8'),
          border: pw.Border(left: pw.BorderSide(color: _gold, width: 4)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: _navy)),
          pw.SizedBox(height: 2),
          pw.Text(detail, style: const pw.TextStyle(fontSize: 8.8, lineSpacing: 2)),
        ]),
      );

  static pw.Widget _evidenceTable(CareerIntelligenceSnapshot snapshot) {
    final rows = snapshot.areas.where((a) => a.count > 0).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    if (rows.isEmpty) return _bullet('No career activities documented yet.');
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
      columnWidths: const {0: pw.FlexColumnWidth(2.2), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(1)},
      children: [
        _tableRow(['Area', 'Records', 'Hours'], header: true),
        ...rows.take(8).map((a) => _tableRow([a.type.label, '${a.count}', a.hours > 0 ? a.hours.toStringAsFixed(1) : '—'])),
      ],
    );
  }

  static pw.Widget _readinessTable(AdvancementAnalysis a) => pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
        columnWidths: const {0: pw.FlexColumnWidth(2.2), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(2.5)},
        children: [
          _tableRow(['Area', 'Status', 'Meaning'], header: true),
          _tableRow(['Roadmap requirements', '${a.completedRequirements}/${a.totalRequirements}', '${(a.roadmapProgress * 100).round()}% complete']),
          _tableRow(['Evidence coverage', '${a.evidenceCovered}/${a.evidenceExpected}', '${(a.evidenceProgress * 100).round()}% supported']),
          _tableRow(['Promotion competencies', '${a.supportedCompetencies}/${a.totalCompetencies}', '${(a.competencyProgress * 100).round()}% developed']),
          _tableRow(['Interview stories', '${a.storyReadyCount}', a.storyReadyCount >= 5 ? 'Strong story bank' : 'Build toward 5 detailed examples']),
        ],
      );

  static pw.TableRow _tableRow(List<String> cells, {bool header = false}) => pw.TableRow(
        decoration: header ? pw.BoxDecoration(color: _navy) : null,
        children: cells.map((text) => pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 8.2,
              color: header ? PdfColors.white : PdfColors.grey900,
              fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        )).toList(),
      );

  static pw.Widget _statusRow(String title, String detail, bool supported) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
            width: 9,
            height: 9,
            margin: const pw.EdgeInsets.only(top: 1, right: 6),
            decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: supported ? _green : _gold),
          ),
          pw.Expanded(child: pw.RichText(text: pw.TextSpan(children: [
            pw.TextSpan(text: '$title — ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _navy)),
            pw.TextSpan(text: detail, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          ]))),
        ]),
      );

  static pw.Widget _storyBlock(CareerRecord r) {
    final role = (r.roleOrAssignment ?? '').trim();
    final summary = (r.summary ?? '').trim();
    final impact = (r.impact ?? '').trim();
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 7),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: .6), borderRadius: pw.BorderRadius.circular(3)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('${_date(r.date)} • ${r.title}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _navy)),
        if (role.isNotEmpty) pw.Text('Role: $role', style: const pw.TextStyle(fontSize: 8.5)),
        if (summary.isNotEmpty) pw.Text('Situation / action: $summary', style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 2)),
        if (impact.isNotEmpty) pw.Text('Result / impact: $impact', style: pw.TextStyle(fontSize: 8.5, lineSpacing: 2, color: _green)),
      ]),
    );
  }

  static Iterable<pw.Widget> _recordBullets(Iterable<CareerRecord> records) {
    final list = records.toList();
    if (list.isEmpty) return [_bullet('No entries documented yet.')];
    return list.map((r) {
      final impact = (r.impact ?? '').trim();
      return _bullet('${_date(r.date)} — ${r.title}${impact.isEmpty ? '' : ' — $impact'}');
    });
  }

  static Iterable<pw.Widget> _credentialLines(AppState app, {required int limit}) {
    final certs = app.certifications.where((c) => c.status.name != 'expired').toList();
    if (certs.isEmpty) return [_bullet('No current certifications recorded.')];
    return certs.take(limit).map((c) => _bullet(app.certificationDisplayName(c)));
  }

  static String _contactLine(CareerExportIdentity identity) => [
        identity.email.trim(),
        identity.phone.trim(),
        identity.location.trim(),
      ].where((e) => e.isNotEmpty).join('  •  ');

  static String _date(DateTime d) => '${d.month}/${d.day}/${d.year}';

  static pw.Widget _disclaimer() => pw.Text(
        'Generated from personal Career Road data. This document is a preparation aid, not an official determination of promotional eligibility, qualification, training completion, or personnel status. Verify all official requirements and records with the applicable department, AHJ, state, credentialing body, or employer.',
        style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey600, lineSpacing: 1.5),
      );

  static pw.Widget _footer(pw.Context context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('FireOps Career Road • ${context.pageNumber}/${context.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
      );
}
