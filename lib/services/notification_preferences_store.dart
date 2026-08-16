import 'package:shared_preferences/shared_preferences.dart';

/// Local toggles for future Daily Focus / cert-expiry / target-date reminders.
///
/// Data layer only — no OS notification permission or scheduling is wired yet.
class NotificationPreferencesStore {
  static const String _kDailyFocus = 'fireops.notifications.dailyFocus';
  static const String _kCertExpiry = 'fireops.notifications.certExpiry';
  static const String _kTargetDateRisk = 'fireops.notifications.targetDateRisk';

  Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      dailyFocusReminders: prefs.getBool(_kDailyFocus) ?? false,
      certificationExpiryAlerts: prefs.getBool(_kCertExpiry) ?? true,
      targetDateRiskAlerts: prefs.getBool(_kTargetDateRisk) ?? true,
    );
  }

  Future<void> save(NotificationPreferences value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyFocus, value.dailyFocusReminders);
    await prefs.setBool(_kCertExpiry, value.certificationExpiryAlerts);
    await prefs.setBool(_kTargetDateRisk, value.targetDateRiskAlerts);
  }
}

class NotificationPreferences {
  final bool dailyFocusReminders;
  final bool certificationExpiryAlerts;
  final bool targetDateRiskAlerts;

  const NotificationPreferences({
    required this.dailyFocusReminders,
    required this.certificationExpiryAlerts,
    required this.targetDateRiskAlerts,
  });

  NotificationPreferences copyWith({
    bool? dailyFocusReminders,
    bool? certificationExpiryAlerts,
    bool? targetDateRiskAlerts,
  }) {
    return NotificationPreferences(
      dailyFocusReminders:
          dailyFocusReminders ?? this.dailyFocusReminders,
      certificationExpiryAlerts:
          certificationExpiryAlerts ?? this.certificationExpiryAlerts,
      targetDateRiskAlerts:
          targetDateRiskAlerts ?? this.targetDateRiskAlerts,
    );
  }
}
