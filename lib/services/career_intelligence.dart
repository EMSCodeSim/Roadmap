import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/advancement_analyzer.dart';
import 'package:firepath/state/app_state.dart';

class CareerAreaInsight {
  final CareerRecordType type;
  final int count;
  final double hours;

  const CareerAreaInsight({
    required this.type,
    required this.count,
    required this.hours,
  });
}

class CareerIntelligenceSnapshot {
  final int totalRecords;
  final double totalHours;
  final int highlightCount;
  final int yearsDocumented;
  final CareerAreaInsight? strongestArea;
  final CareerAreaInsight? developmentGap;
  final List<CareerAreaInsight> areas;
  final List<CareerRecord> highlights;

  const CareerIntelligenceSnapshot({
    required this.totalRecords,
    required this.totalHours,
    required this.highlightCount,
    required this.yearsDocumented,
    required this.strongestArea,
    required this.developmentGap,
    required this.areas,
    required this.highlights,
  });
}

class CareerIntelligence {
  const CareerIntelligence._();

  static CareerIntelligenceSnapshot analyze(List<CareerRecord> records) {
    final grouped = <CareerRecordType, List<CareerRecord>>{};
    for (final record in records) {
      (grouped[record.type] ??= <CareerRecord>[]).add(record);
    }

    final areas = CareerRecordType.values.map((type) {
      final items = grouped[type] ?? const <CareerRecord>[];
      return CareerAreaInsight(
        type: type,
        count: items.length,
        hours: items.fold<double>(0, (sum, item) => sum + (item.hours ?? 0)),
      );
    }).toList();

    final activeAreas = areas.where((area) => area.count > 0).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final growthAreas = areas
        .where((area) => area.type == CareerRecordType.leadership || area.type == CareerRecordType.teaching || area.type == CareerRecordType.project || area.type == CareerRecordType.achievement)
        .toList()
      ..sort((a, b) => a.count.compareTo(b.count));

    final years = records.map((e) => e.date.year).toSet();
    final highlights = records.where((record) {
      if (record.highlight) return true;
      if (record.type == CareerRecordType.achievement || record.type == CareerRecordType.project) return true;
      return (record.impact ?? '').trim().isNotEmpty &&
          (record.type == CareerRecordType.leadership || record.type == CareerRecordType.teaching);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return CareerIntelligenceSnapshot(
      totalRecords: records.length,
      totalHours: records.fold<double>(0, (sum, item) => sum + (item.hours ?? 0)),
      highlightCount: records.where((e) => e.highlight).length,
      yearsDocumented: years.length,
      strongestArea: activeAreas.isEmpty ? null : activeAreas.first,
      developmentGap: growthAreas.isEmpty ? null : growthAreas.first,
      areas: areas,
      highlights: highlights.take(20).toList(),
    );
  }

  static String buildAnnualReview({
    required AppState app,
    required List<CareerRecord> records,
    required int year,
  }) {
    final yearRecords = records.where((e) => e.date.year == year).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final snapshot = analyze(yearRecords);
    final buffer = StringBuffer();

    buffer.writeln('$year CAREER REVIEW');
    buffer.writeln('FireOps Career Road');
    buffer.writeln();
    buffer.writeln('YEAR AT A GLANCE');
    buffer.writeln('- ${snapshot.totalRecords} documented activities');
    if (snapshot.totalHours > 0) {
      buffer.writeln('- ${snapshot.totalHours.toStringAsFixed(1)} documented hours');
    }
    buffer.writeln('- ${snapshot.highlightCount} marked career highlights');
    if (app.selectedGoal != null) {
      buffer.writeln('- Active career goal: ${app.selectedGoal!.title}');
      final roadmap = app.roadmap;
      if (roadmap != null) {
        buffer.writeln('- Current goal readiness: ${(roadmap.percentComplete * 100).round()}%');
      }
    }
    buffer.writeln();

    buffer.writeln('ACTIVITY BY AREA');
    final nonZero = snapshot.areas.where((e) => e.count > 0).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    if (nonZero.isEmpty) {
      buffer.writeln('- No activities documented for this year.');
    } else {
      for (final area in nonZero) {
        final hours = area.hours > 0 ? ' • ${area.hours.toStringAsFixed(1)} hr' : '';
        buffer.writeln('- ${area.type.label}: ${area.count}$hours');
      }
    }
    buffer.writeln();

    buffer.writeln('CAREER HIGHLIGHTS');
    final highlights = snapshot.highlights.take(8).toList();
    if (highlights.isEmpty) {
      buffer.writeln('- No highlights marked yet. Add important achievements, leadership examples, projects, and meaningful teaching moments as they happen.');
    } else {
      for (final record in highlights) {
        final impact = (record.impact ?? '').trim();
        buffer.writeln('- ${_fmt(record.date)} — ${record.title}${impact.isEmpty ? '' : ' | $impact'}');
      }
    }
    buffer.writeln();

    if (snapshot.strongestArea != null) {
      buffer.writeln('STRENGTH SIGNAL');
      buffer.writeln('- Your most documented area this year was ${snapshot.strongestArea!.type.label.toLowerCase()} with ${snapshot.strongestArea!.count} entries.');
      buffer.writeln();
    }
    if (snapshot.developmentGap != null) {
      buffer.writeln('DEVELOPMENT OPPORTUNITY');
      buffer.writeln('- Your professional-growth record has relatively little ${snapshot.developmentGap!.type.label.toLowerCase()} evidence. Consider intentionally capturing examples in this area next year.');
      buffer.writeln();
    }

    buffer.writeln('NEXT YEAR');
    final advancement = AdvancementAnalyzer.analyze(app: app, records: records);
    buffer.writeln('- ${advancement.recommendation.title}: ${advancement.recommendation.reason}');
    buffer.writeln();
    buffer.writeln('This review is a personal career-development summary. Verify official training, credential, promotional, and personnel records with the appropriate department or certifying authority.');
    return buffer.toString().trim();
  }

  static String buildPromotionPortfolio({
    required AppState app,
    required List<CareerRecord> records,
  }) {
    final snapshot = analyze(records);
    final base = AdvancementAnalyzer.buildPromotionBrief(app: app, records: records);
    final buffer = StringBuffer();
    buffer.writeln('CAREER PORTFOLIO SNAPSHOT');
    buffer.writeln('- ${snapshot.totalRecords} documented career activities across ${snapshot.yearsDocumented} year${snapshot.yearsDocumented == 1 ? '' : 's'}');
    if (snapshot.totalHours > 0) {
      buffer.writeln('- ${snapshot.totalHours.toStringAsFixed(1)} documented hours');
    }
    buffer.writeln('- ${snapshot.highlightCount} marked career highlights');
    if (snapshot.strongestArea != null) {
      buffer.writeln('- Strongest documented area: ${snapshot.strongestArea!.type.label} (${snapshot.strongestArea!.count} records)');
    }
    buffer.writeln();
    buffer.writeln(base);
    return buffer.toString().trim();
  }

  static String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';
}
