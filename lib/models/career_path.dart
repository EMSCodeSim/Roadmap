/// Personal Roadmap career path selection (Fire / EMS / Both).
///
/// This is private career-development metadata only. It must never alter
/// Department Mode roles, memberships, or official department records.
enum CareerPath {
  fire,
  ems,
  both,
}

extension CareerPathX on CareerPath {
  /// Canonical persistence values: FIRE / EMS / BOTH.
  String get storageValue => switch (this) {
        CareerPath.fire => 'FIRE',
        CareerPath.ems => 'EMS',
        CareerPath.both => 'BOTH',
      };

  String get shortLabel => switch (this) {
        CareerPath.fire => 'Fire',
        CareerPath.ems => 'EMS',
        CareerPath.both => 'Fire & EMS',
      };

  String get choiceTitle => switch (this) {
        CareerPath.fire => 'Fire',
        CareerPath.ems => 'EMS',
        CareerPath.both => 'Fire & EMS',
      };

  String get choiceEmoji => switch (this) {
        CareerPath.fire => '🚒',
        CareerPath.ems => '🚑',
        CareerPath.both => '🚒 + 🚑',
      };

  String get choiceSubtitle => switch (this) {
        CareerPath.fire => 'Firefighter and fire officer progression',
        CareerPath.ems => 'EMT through EMS leadership progression',
        CareerPath.both => 'One personal roadmap for both sides of your career',
      };

  bool get includesFire => this == CareerPath.fire || this == CareerPath.both;
  bool get includesEms => this == CareerPath.ems || this == CareerPath.both;

  static CareerPath? tryParse(Object? raw) {
    if (raw is! String) return null;
    switch (raw.trim().toUpperCase()) {
      case 'FIRE':
        return CareerPath.fire;
      case 'EMS':
        return CareerPath.ems;
      case 'BOTH':
      case 'FIRE_AND_EMS':
      case 'FIRE+EMS':
        return CareerPath.both;
      default:
        return null;
    }
  }
}

/// Copy and labeling helpers that adapt Personal Roadmap language to the
/// user's selected career path without forking the app into separate products.
class CareerPathCopy {
  CareerPathCopy._();

  /// Effective Personal path for UI. Legacy profiles without a stored value
  /// are treated as Fire so existing roadmaps keep working.
  static CareerPath effective(CareerPath? stored) => stored ?? CareerPath.fire;

  /// Which track should be emphasized on Personal Home for BOTH users.
  static CareerPath emphasisTrack({
    required CareerPath? careerPath,
    CareerPath? primaryTrack,
  }) {
    final path = effective(careerPath);
    if (path != CareerPath.both) return path;
    final primary = primaryTrack;
    if (primary == CareerPath.fire || primary == CareerPath.ems) {
      return primary!;
    }
    return CareerPath.fire;
  }

  static String trackLabelForGoalCategory(String? category) {
    final c = (category ?? '').trim().toLowerCase();
    if (c.startsWith('ems')) return 'EMS';
    if (c == 'operations' || c == 'fire') return 'Fire';
    return '';
  }

  static bool isEmsGoalId(String? goalId) {
    final id = (goalId ?? '').trim().toLowerCase();
    return id.startsWith('ems_');
  }

  static bool isFireGoalId(String? goalId) {
    final id = (goalId ?? '').trim().toLowerCase();
    return id.startsWith('ops_');
  }

  static String welcomeHeadline(CareerPath path) => switch (path) {
        CareerPath.fire => 'Your fire career, organized.',
        CareerPath.ems => 'Your EMS career, organized.',
        CareerPath.both => 'Your Fire & EMS career, organized.',
      };

  static String welcomeSupporting(CareerPath path) => switch (path) {
        CareerPath.fire =>
          'Plan where you are, where you want to go, and what to work on next — certifications, task books, and experience in one personal roadmap.',
        CareerPath.ems =>
          'Plan where you are, where you want to go, and what to work on next — certifications, training, and experience in one personal roadmap.',
        CareerPath.both =>
          'Manage both sides of your career in one personal roadmap. See the next useful step without switching apps.',
      };

  static String homeProductLine(CareerPath path) => switch (path) {
        CareerPath.fire => 'Plan and track your fire career.',
        CareerPath.ems => 'Plan and track your EMS career.',
        CareerPath.both => 'Manage Fire and EMS in one personal roadmap.',
      };

  /// Neutral product language unless the content itself is Fire- or EMS-specific.
  static String taskBookLabel(CareerPath path) => 'Task Book';

  static String careerGoalLabel(CareerPath path) => 'Career Goal';
}
