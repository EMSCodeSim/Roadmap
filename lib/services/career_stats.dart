import 'package:firepath/models/career_record.dart';

class CareerSuccessStats {
  final int attempts;
  final int successful;

  const CareerSuccessStats({required this.attempts, required this.successful});

  int get unsuccessful => attempts - successful;
  double? get rate => attempts <= 0 ? null : successful / attempts;
  int? get percent => rate == null ? null : (rate! * 100).round();
}

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
  final int medicalExposures;
  final int hazardExposures;

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
    required this.medicalExposures,
    required this.hazardExposures,
  });

  int get totalExposures => medicalExposures + hazardExposures;

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
        medicalExposures: 0,
        hazardExposures: 0,
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
    var medicalExposures = 0;
    var hazardExposures = 0;

    for (final r in records) {
      final count = r.repetitions < 1 ? 1 : r.repetitions;
      final hours = r.hours;

      if (isMedicalExposureRecord(r)) {
        medicalExposures += count;
        continue;
      }
      if (isHazardExposureRecord(r)) {
        hazardExposures += count;
        continue;
      }

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
      medicalExposures: medicalExposures,
      hazardExposures: hazardExposures,
    );
  }

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

  static bool isMedicalExposureRecord(CareerRecord record) {
    final key = (record.trackingKey ?? '').toLowerCase();
    if (key == 'safety.medical_exposure') return true;
    final hay = '${record.title} ${record.category}'.toLowerCase();
    return hay.contains('medical exposure') ||
        hay.contains('blood exposure') ||
        hay.contains('body fluid exposure');
  }

  static bool isHazardExposureRecord(CareerRecord record) {
    final key = (record.trackingKey ?? '').toLowerCase();
    if (key == 'safety.hazard_exposure') return true;
    final hay = '${record.title} ${record.category}'.toLowerCase();
    return hay.contains('hazard exposure') ||
        hay.contains('chemical exposure') ||
        hay.contains('smoke exposure');
  }

  static bool isExposureRecord(CareerRecord record) =>
      isMedicalExposureRecord(record) || isHazardExposureRecord(record);

  /// Returns measured success statistics for a procedure or skill.
  ///
  /// For a record with multiple attempts and a successful final outcome, one
  /// attempt is counted as successful and the preceding attempts are counted
  /// as unsuccessful. This matches common procedure logging such as an IV that
  /// succeeds on attempt 2: 2 attempts, 1 success, 50% success rate.
  static CareerSuccessStats successFor(
    Iterable<CareerRecord> records, {
    String? trackingKey,
  }) {
    var attempts = 0;
    var successes = 0;
    for (final record in records) {
      if (trackingKey != null && record.trackingKey != trackingKey) continue;
      final count = record.repetitions < 1 ? 1 : record.repetitions;
      if (record.outcome == CareerRecordOutcome.successful) {
        attempts += count;
        successes += 1;
      } else if (record.outcome == CareerRecordOutcome.unsuccessful) {
        attempts += count;
      }
    }
    return CareerSuccessStats(attempts: attempts, successful: successes);
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
