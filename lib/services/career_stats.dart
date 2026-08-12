import 'package:firepath/models/career_record.dart';

/// Shared statistics engine for Career Records.
///
/// Home, Career Record, Growth, and Task Book should use this logic so totals
/// stay consistent across the app.
class CareerStats {
  final int calls;
  final int skillRepetitions;
  final double trainingHours;
  final double driveHours;
  final double teachingHours;
  final int leadershipCount;
  final int achievements;
  final int awards;
  final int projects;
  final int taskBookUpdates;

  const CareerStats({
    required this.calls,
    required this.skillRepetitions,
    required this.trainingHours,
    required this.driveHours,
    required this.teachingHours,
    required this.leadershipCount,
    required this.achievements,
    required this.awards,
    required this.projects,
    required this.taskBookUpdates,
  });

  factory CareerStats.empty() => const CareerStats(
        calls: 0,
        skillRepetitions: 0,
        trainingHours: 0,
        driveHours: 0,
        teachingHours: 0,
        leadershipCount: 0,
        achievements: 0,
        awards: 0,
        projects: 0,
        taskBookUpdates: 0,
      );

  factory CareerStats.fromRecords(List<CareerRecord> records) {
    var calls = 0;
    var skillReps = 0;
    var trainingHrs = 0.0;
    var driveHrs = 0.0;
    var teachingHrs = 0.0;
    var leadership = 0;
    var achievements = 0;
    var awards = 0;
    var projects = 0;
    var taskBook = 0;

    for (final r in records) {
      final count = r.repetitions < 1 ? 1 : r.repetitions;
      final hours = r.hours;

      switch (r.type) {
        case CareerRecordType.operationalExperience:
          calls += count;
        case CareerRecordType.skill:
          if (isDrivingRecord(r)) {
            if (hours != null && hours > 0) driveHrs += hours;
          } else {
            skillReps += count;
          }
        case CareerRecordType.training:
          if (hours != null && hours > 0) trainingHrs += hours;
        case CareerRecordType.teaching:
          if (hours != null && hours > 0) teachingHrs += hours;
        case CareerRecordType.leadership:
          leadership += count;
        case CareerRecordType.achievement:
          achievements += count;
          if (isAwardRecord(r)) awards += count;
        case CareerRecordType.project:
          projects += count;
        case CareerRecordType.taskBookEvidence:
          taskBook += count;
        case CareerRecordType.education:
          break;
      }
    }

    return CareerStats(
      calls: calls,
      skillRepetitions: skillReps,
      trainingHours: trainingHrs,
      driveHours: driveHrs,
      teachingHours: teachingHrs,
      leadershipCount: leadership,
      achievements: achievements,
      awards: awards,
      projects: projects,
      taskBookUpdates: taskBook,
    );
  }

  /// Drive time is intentionally stored using the existing `skill` record type
  /// for backward compatibility. A stable tracking key is preferred, with
  /// text matching retained for older records.
  static bool isDrivingRecord(CareerRecord record) {
    final key = (record.trackingKey ?? '').toLowerCase();
    if (key == 'quick.drive_time' || key == 'fire.driver') return true;
    final hay = '${record.title} ${record.category}'.toLowerCase();
    return hay.contains('drive time') ||
        hay.contains('driving') ||
        hay.contains('apparatus driving') ||
        hay.contains('emergency driving');
  }

  static bool isAwardRecord(CareerRecord record) {
    final key = (record.trackingKey ?? '').toLowerCase();
    if (key == 'quick.award') return true;
    final hay = '${record.title} ${record.category}'.toLowerCase();
    return hay.contains('award') ||
        hay.contains('recognition') ||
        hay.contains('commendation');
  }

  String get trainingLabel => formatDurationHours(trainingHours);
  String get driveLabel => formatDurationHours(driveHours);
  String get teachingLabel => formatDurationHours(teachingHours);

  static String formatDurationHours(double hours) {
    if (hours <= 0) return '0 hr';
    final rounded = (hours * 10).roundToDouble() / 10;
    if (rounded == rounded.roundToDouble()) {
      return '${rounded.toInt()} hr';
    }
    return '${rounded.toStringAsFixed(1)} hr';
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  static String formatDate(DateTime dt) {
    final month = _months[dt.month - 1];
    return '$month ${dt.day}, ${dt.year}';
  }

  static List<int> availableYears(List<CareerRecord> records) {
    final years = records.map((r) => r.date.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }
}
