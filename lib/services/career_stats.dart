import 'package:firepath/models/career_record.dart';

/// Shared statistics engine for Career Records.
///
/// Home, Career Record, Growth, and Task Book can all compute consistent totals
/// from the same logic.
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
      final titleLower = r.title.toLowerCase();
      final categoryLower = r.category.toLowerCase();

      switch (r.type) {
        case CareerRecordType.operationalExperience:
          calls += count;
        case CareerRecordType.skill:
          skillReps += count;
          if (hours != null && _looksLikeDriving(titleLower, categoryLower)) {
            driveHrs += hours;
          }
        case CareerRecordType.training:
          if (hours != null) trainingHrs += hours;
        case CareerRecordType.teaching:
          if (hours != null) teachingHrs += hours;
        case CareerRecordType.leadership:
          leadership += 1;
        case CareerRecordType.achievement:
          achievements += 1;
          if (_looksLikeAward(titleLower, categoryLower)) awards += 1;
        case CareerRecordType.project:
          projects += 1;
        case CareerRecordType.taskBookEvidence:
          taskBook += 1;
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

  static bool _looksLikeDriving(String titleLower, String categoryLower) {
    final hay = '$titleLower $categoryLower';
    return hay.contains('drive') ||
        hay.contains('driving') ||
        hay.contains('apparatus') ||
        hay.contains('engine') ||
        hay.contains('truck') ||
        hay.contains('tender');
  }

  static bool _looksLikeAward(String titleLower, String categoryLower) {
    final hay = '$titleLower $categoryLower';
    return hay.contains('award') || hay.contains('recognition') || hay.contains('commendation');
  }

  String get trainingLabel => trainingHours <= 0 ? '0 hr' : formatDurationHours(trainingHours);
  String get driveLabel => driveHours <= 0 ? '0 hr' : formatDurationHours(driveHours);
  String get teachingLabel => teachingHours <= 0 ? '0 hr' : formatDurationHours(teachingHours);

  static String formatDurationHours(double hours) {
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
    final m = (dt.month >= 1 && dt.month <= 12) ? _months[dt.month - 1] : '';
    return '$m ${dt.day}, ${dt.year}';
  }

  static List<int> availableYears(List<CareerRecord> records) {
    final out = <int>{};
    for (final r in records) {
      out.add(r.date.year);
    }
    final list = out.toList();
    list.sort();
    return list;
  }
}
