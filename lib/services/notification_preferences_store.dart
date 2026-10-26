import 'package:shared_preferences/shared_preferences.dart';

/// Device-level notification choices. Department alerts are intentionally
/// opt-in and can be changed independently.
class NotificationPreferencesStore {
  static const String _kDailyFocus = 'fireops.notifications.dailyFocus';
  static const String _kCertExpiry = 'fireops.notifications.certExpiry';
  static const String _kTargetDateRisk = 'fireops.notifications.targetDateRisk';
  static const String _kTaskBooks = 'fireops.notifications.taskBooks';
  static const String _kAssignments = 'fireops.notifications.assignments';
  static const String _kNeedsAttention = 'fireops.notifications.needsAttention';

  Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      dailyFocusReminders: prefs.getBool(_kDailyFocus) ?? false,
      certificationExpiryAlerts: prefs.getBool(_kCertExpiry) ?? true,
      targetDateRiskAlerts: prefs.getBool(_kTargetDateRisk) ?? true,
      taskBookAlerts: prefs.getBool(_kTaskBooks) ?? false,
      assignmentAlerts: prefs.getBool(_kAssignments) ?? false,
      needsAttentionAlerts: prefs.getBool(_kNeedsAttention) ?? false,
    );
  }

  Future<void> save(NotificationPreferences value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyFocus, value.dailyFocusReminders);
    await prefs.setBool(_kCertExpiry, value.certificationExpiryAlerts);
    await prefs.setBool(_kTargetDateRisk, value.targetDateRiskAlerts);
    await prefs.setBool(_kTaskBooks, value.taskBookAlerts);
    await prefs.setBool(_kAssignments, value.assignmentAlerts);
    await prefs.setBool(_kNeedsAttention, value.needsAttentionAlerts);
  }
}

class NotificationPreferences {
  final bool dailyFocusReminders;
  final bool certificationExpiryAlerts;
  final bool targetDateRiskAlerts;
  final bool taskBookAlerts;
  final bool assignmentAlerts;
  final bool needsAttentionAlerts;

  const NotificationPreferences({
    required this.dailyFocusReminders,
    required this.certificationExpiryAlerts,
    required this.targetDateRiskAlerts,
    required this.taskBookAlerts,
    required this.assignmentAlerts,
    required this.needsAttentionAlerts,
  });

  NotificationPreferences copyWith({
    bool? dailyFocusReminders,
    bool? certificationExpiryAlerts,
    bool? targetDateRiskAlerts,
    bool? taskBookAlerts,
    bool? assignmentAlerts,
    bool? needsAttentionAlerts,
  }) {
    return NotificationPreferences(
      dailyFocusReminders:
          dailyFocusReminders ?? this.dailyFocusReminders,
      certificationExpiryAlerts:
          certificationExpiryAlerts ?? this.certificationExpiryAlerts,
      targetDateRiskAlerts:
          targetDateRiskAlerts ?? this.targetDateRiskAlerts,
      taskBookAlerts: taskBookAlerts ?? this.taskBookAlerts,
      assignmentAlerts: assignmentAlerts ?? this.assignmentAlerts,
      needsAttentionAlerts:
          needsAttentionAlerts ?? this.needsAttentionAlerts,
    );
  }
}
