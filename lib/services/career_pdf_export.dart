import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/department_transfer.dart';
import 'package:firepath/services/advancement_analyzer.dart';
import 'package:firepath/services/career_intelligence.dart';
import 'package:firepath/services/department_transfer_service.dart';
import 'package:firepath/state/app_state.dart';

class CareerExportIdentity {
  final String name;
  final String email;
  final String phone;
  final String location;

  const CareerExportIdentity({
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
  });

  factory CareerExportIdentity.empty() =>
      const CareerExportIdentity(name: '', email: '', phone: '', location: '');

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'location': location,
  };

  factory CareerExportIdentity.fromJson(Map<String, dynamic> json) =>
      CareerExportIdentity(
        name: (json['name'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        location: (json['location'] as String?) ?? '',
      );
}

class CareerExportIdentityStore {
  static const _key = 'career_export_identity_v1';

  Future<CareerExportIdentity> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return CareerExportIdentity.empty();
    try {
      return CareerExportIdentity.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return CareerExportIdentity.empty();
    }
  }

  Future<void> save(CareerExportIdentity identity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(identity.toJson()));
  }
}

class CareerPdfExport {
  const CareerPdfExport._();

  static Future<Uint8List> buildCareerPortfolio({
    required AppState app,
    required List<CareerRecord> records,
    required CareerExportIdentity identity,
  }) async {
    final snapshot = CareerIntelligence.analyze(records);
    final advancement = AdvancementAnalyzer.analyze(app: app, records: records);
    final doc = pw.Document(title: 'FireOps Career Portfolio');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        footer: _footer,
        build: (context) => [
          _header(identity, 'CAREER PORTFOLIO', app),
          pw.SizedBox(height: 14),
          _summaryStrip([
            ('Career records', '${snapshot.totalRecords}'),
            ('Years documented', '${snapshot.yearsDocumented}'),
            ('Documented hours', snapshot.totalHours.toStringAsFixed(1)),
            ('Career highlights', '${snapshot.highlightCount}'),
          ]),
          pw.SizedBox(height: 18),
          _sectionTitle('Career Direction'),
          _body('Current role: ${_roles(app)}'),
          _body(
            'Active goal: ${app.selectedGoal?.title ?? 'No active goal selected'}',
          ),
          if (app.profile.yearsOfService != null)
            _body('Years of service: ${app.profile.yearsOfService}'),
          if ((app.profile.departmentName ?? '').trim().isNotEmpty)
            _body('Department: ${app.profile.departmentName}'),
          pw.SizedBox(height: 12),
          _sectionTitle('Advancement Readiness'),
          _body(
            'Readiness score: ${advancement.readinessScore}% — ${advancement.readinessLabel}',
          ),
          _body(
            'Requirements complete: ${advancement.completedRequirements}/${advancement.totalRequirements}',
          ),
          _body(
            'Evidence coverage: ${advancement.evidenceCovered}/${advancement.evidenceExpected}',
          ),
          _body('Interview-ready stories: ${advancement.storyReadyCount}'),
          pw.SizedBox(height: 12),
          _sectionTitle('Current Credentials'),
          ..._credentialLines(app),
          pw.SizedBox(height: 12),
          _sectionTitle('Career Highlights'),
          ..._recordBullets(snapshot.highlights.take(12)),
          pw.SizedBox(height: 12),
          _sectionTitle('Leadership, Teaching & Projects'),
          ..._recordBullets(
            records
                .where(
                  (r) =>
                      r.type == CareerRecordType.leadership ||
                      r.type == CareerRecordType.teaching ||
                      r.type == CareerRecordType.project,
                )
                .take(18),
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Development Priorities'),
          _body(
            '${advancement.recommendation.title}: ${advancement.recommendation.reason}',
          ),
          if (advancement.evidenceGaps.isNotEmpty)
            ...advancement.evidenceGaps
                .take(8)
                .map((gap) => _bullet(gap.requirement.name)),
          pw.SizedBox(height: 12),
          _disclaimer(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildResume({
    required AppState app,
    required List<CareerRecord> records,
    required CareerExportIdentity identity,
  }) async {
    final highlights =
        records
            .where(
              (r) =>
                  r.highlight ||
                  r.type == CareerRecordType.achievement ||
                  r.type == CareerRecordType.project,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final leadership =
        records
            .where(
              (r) =>
                  r.type == CareerRecordType.leadership ||
                  r.type == CareerRecordType.teaching,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final doc = pw.Document(title: 'Professional Resume');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(42, 36, 42, 36),
        footer: _footer,
        build: (context) => [
          pw.Text(
            identity.name.trim().isEmpty
                ? 'FIRE / EMS PROFESSIONAL'
                : identity.name.trim().toUpperCase(),
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _contactLine(identity),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.Divider(color: _navy, thickness: 1.5),
          _resumeHeading('PROFESSIONAL PROFILE'),
          _body(_profileSummary(app, records)),
          _resumeHeading('CURRENT ROLE & CAREER DIRECTION'),
          _body(_roles(app)),
          if ((app.profile.departmentName ?? '').trim().isNotEmpty)
            _body(app.profile.departmentName!.trim()),
          if (app.selectedGoal != null)
            _body('Career development target: ${app.selectedGoal!.title}'),
          _resumeHeading('CREDENTIALS'),
          pw.Wrap(
            spacing: 10,
            runSpacing: 4,
            children: app.certifications
                .where((c) => c.status.name != 'expired')
                .take(18)
                .map(
                  (c) => pw.Text(
                    '• ${app.certificationDisplayName(c)}',
                    style: const pw.TextStyle(fontSize: 9.5),
                  ),
                )
                .toList(),
          ),
          _resumeHeading('SELECTED ACCOMPLISHMENTS'),
          ..._resumeRecords(highlights.take(8)),
          _resumeHeading('LEADERSHIP / INSTRUCTION'),
          ..._resumeRecords(leadership.take(8)),
          _resumeHeading('PROFESSIONAL DEVELOPMENT'),
          _body(_developmentSummary(records)),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildPromotionPacket({
    required AppState app,
    required List<CareerRecord> records,
    required CareerExportIdentity identity,
  }) async {
    final advancement = AdvancementAnalyzer.analyze(app: app, records: records);
    final stories = advancement.promotionStories;
    final doc = pw.Document(title: 'Promotion Preparation Packet');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        footer: _footer,
        build: (context) => [
          _header(identity, 'PROMOTION PREPARATION PACKET', app),
          pw.SizedBox(height: 14),
          _summaryStrip([
            ('Readiness', '${advancement.readinessScore}%'),
            (
              'Requirements',
              '${advancement.completedRequirements}/${advancement.totalRequirements}',
            ),
            (
              'Evidence',
              '${advancement.evidenceCovered}/${advancement.evidenceExpected}',
            ),
            ('Stories', '${advancement.storyReadyCount}'),
          ]),
          pw.SizedBox(height: 18),
          _sectionTitle('Next Best Step'),
          _body(
            '${advancement.recommendation.title} — ${advancement.recommendation.reason}',
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Promotion Competency Map'),
          ...advancement.competencies.map(
            (c) => _bullet(
              '${c.title}: ${c.exampleCount}/${c.targetExamples} examples${c.supported ? ' — supported' : ' — build more evidence'}',
            ),
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Evidence Gaps'),
          if (advancement.evidenceGaps.isEmpty)
            _bullet('No current roadmap evidence gaps identified.')
          else
            ...advancement.evidenceGaps
                .take(12)
                .map((g) => _bullet(g.requirement.name)),
          pw.SizedBox(height: 12),
          _sectionTitle('Interview Story Bank'),
          ...stories.take(10).map((record) => _storyBlock(record)),
          pw.SizedBox(height: 12),
          _sectionTitle('Credentials'),
          ..._credentialLines(app),
          pw.SizedBox(height: 12),
          _disclaimer(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildTransferReport({
    required AppState app,
    required DepartmentTransferEvaluation evaluation,
    required CareerExportIdentity identity,
  }) async {
    final doc = pw.Document(title: 'Department Transfer Readiness');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        footer: _footer,
        build: (context) => [
          _header(identity, 'DEPARTMENT TRANSFER READINESS', app),
          pw.SizedBox(height: 12),
          _body(
            'Target department: ${evaluation.plan.departmentName.trim().isEmpty ? 'Not specified' : evaluation.plan.departmentName.trim()}',
          ),
          if ((evaluation.plan.targetRole ?? '').trim().isNotEmpty)
            _body('Target role: ${evaluation.plan.targetRole}'),
          pw.SizedBox(height: 10),
          _summaryStrip([
            ('Matched', '${evaluation.satisfiedCount}'),
            ('Requirements', '${evaluation.totalCount}'),
            ('Overlap', '${(evaluation.percent * 100).round()}%'),
          ]),
          pw.SizedBox(height: 18),
          _sectionTitle('Likely Transferable'),
          ...evaluation.items
              .where((e) => e.satisfied)
              .map((e) => _statusRow(e.requirement.title, e.reason, true)),
          pw.SizedBox(height: 12),
          _sectionTitle('Gaps / Verify With Receiving Department'),
          if (evaluation.gaps.isEmpty)
            _bullet('No obvious gaps identified from the information entered.')
          else
            ...evaluation.gaps.map(
              (e) => _statusRow(e.requirement.title, e.reason, false),
            ),
          pw.SizedBox(height: 12),
          _body(
            DepartmentTransferService.buildComparisonText(
              evaluation,
            ).split('\n').last,
          ),
        ],
      ),
    );
    return doc.save();
  }

  static final PdfColor _navy = PdfColor.fromHex('#0B1F33');
  static final PdfColor _gold = PdfColor.fromHex('#B78A3B');
  static final PdfColor _light = PdfColor.fromHex('#EEF2F5');

  static pw.Widget _header(
    CareerExportIdentity identity,
    String title,
    AppState app,
  ) {
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
                  identity.name.trim().isEmpty
                      ? _roles(app)
                      : identity.name.trim(),
                  style: pw.TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (_contactLine(identity).isNotEmpty)
                  pw.Text(
                    _contactLine(identity),
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8.5,
                    ),
                  ),
              ],
            ),
          ),
          pw.Text(
            'FireOps Career Road',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryStrip(List<(String, String)> metrics) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _light,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: metrics
              .map(
                (m) => pw.Column(
                  children: [
                    pw.Text(
                      m.$2,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    pw.Text(
                      m.$1,
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      );

  static pw.Widget _sectionTitle(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _navy,
      ),
    ),
  );

  static pw.Widget _resumeHeading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12, bottom: 5),
    child: pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 1)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _navy,
        ),
      ),
    ),
  );

  static pw.Widget _body(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2),
    ),
  );

  static pw.Widget _bullet(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(left: 8, bottom: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '• ',
          style: pw.TextStyle(color: _gold, fontWeight: pw.FontWeight.bold),
        ),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(fontSize: 9.3, lineSpacing: 2),
          ),
        ),
      ],
    ),
  );

  static Iterable<pw.Widget> _credentialLines(AppState app) {
    final certs = app.certifications
        .where((c) => c.status.name != 'expired')
        .toList();
    if (certs.isEmpty) return [_bullet('No current certifications recorded.')];
    return certs.take(24).map((c) => _bullet(app.certificationDisplayName(c)));
  }

  static Iterable<pw.Widget> _recordBullets(Iterable<CareerRecord> records) {
    final list = records.toList();
    if (list.isEmpty) return [_bullet('No entries documented yet.')];
    return list.map(
      (r) => _bullet(
        '${_date(r.date)} — ${r.title}${(r.impact ?? '').trim().isEmpty ? '' : ': ${r.impact!.trim()}'}',
      ),
    );
  }

  static Iterable<pw.Widget> _resumeRecords(Iterable<CareerRecord> records) =>
      records.map(
        (r) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                r.title,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if ((r.roleOrAssignment ?? '').trim().isNotEmpty)
                pw.Text(
                  r.roleOrAssignment!.trim(),
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey700,
                  ),
                ),
              if ((r.impact ?? '').trim().isNotEmpty)
                pw.Text(
                  r.impact!.trim(),
                  style: const pw.TextStyle(fontSize: 8.8, lineSpacing: 2),
                ),
            ],
          ),
        ),
      );

  static pw.Widget _storyBlock(CareerRecord record) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 7),
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          record.title,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: _navy,
          ),
        ),
        if ((record.roleOrAssignment ?? '').trim().isNotEmpty)
          _body('Role: ${record.roleOrAssignment!.trim()}'),
        if ((record.summary ?? '').trim().isNotEmpty)
          _body('Situation / Action: ${record.summary!.trim()}'),
        if ((record.impact ?? '').trim().isNotEmpty)
          _body('Result: ${record.impact!.trim()}'),
      ],
    ),
  );

  static pw.Widget _statusRow(String title, String reason, bool satisfied) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 5),
        padding: const pw.EdgeInsets.all(7),
        decoration: pw.BoxDecoration(
          color: satisfied
              ? PdfColor.fromHex('#EEF7F0')
              : PdfColor.fromHex('#FFF4EC'),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              satisfied ? '✓' : '○',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: satisfied ? PdfColors.green700 : PdfColors.orange700,
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 9.3,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    reason,
                    style: const pw.TextStyle(
                      fontSize: 8.3,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  static pw.Widget _disclaimer() => pw.Container(
    padding: const pw.EdgeInsets.all(8),
    color: PdfColors.grey100,
    child: pw.Text(
      'Personal professional-development document generated by FireOps Career Road. Verify official credentials, personnel records, promotional eligibility, and department requirements with the appropriate authority.',
      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
    ),
  );

  static pw.Widget _footer(pw.Context context) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'FireOps Career Road',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
      ),
      pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
      ),
    ],
  );

  static String _roles(AppState app) => app.profile.currentRoles.isEmpty
      ? 'Fire / EMS professional'
      : app.profile.currentRoles.join(' / ');

  static String _contactLine(CareerExportIdentity identity) => [
    identity.location,
    identity.phone,
    identity.email,
  ].where((e) => e.trim().isNotEmpty).join(' • ');

  static String _profileSummary(AppState app, List<CareerRecord> records) {
    final years = app.profile.yearsOfService;
    final leadership = records
        .where(
          (r) =>
              r.type == CareerRecordType.leadership ||
              r.type == CareerRecordType.teaching ||
              r.type == CareerRecordType.project,
        )
        .length;
    return '${years == null ? 'Experienced' : '$years-year'} fire/EMS professional with a documented record spanning operations, training, professional development, and ${leadership > 0 ? '$leadership leadership/instruction/project examples' : 'career advancement work'}. Current focus: ${app.selectedGoal?.title ?? 'continued professional growth'}.';
  }

  static String _developmentSummary(List<CareerRecord> records) {
    final training = records
        .where((r) => r.type == CareerRecordType.training)
        .length;
    final education = records
        .where((r) => r.type == CareerRecordType.education)
        .length;
    final hours = records.fold<double>(0, (sum, r) => sum + (r.hours ?? 0));
    return '$training documented training activities, $education education records, and ${hours.toStringAsFixed(1)} total documented career-development hours.';
  }

  static String _date(DateTime d) => '${d.month}/${d.day}/${d.year}';
}
