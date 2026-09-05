import 'package:shared_preferences/shared_preferences.dart';

class TaskBookSetupStore {
  static const String _reviewPendingKey = 'task_book_review_pending_v1';
  static const String _missingStatePromptKey = 'profile_missing_state_prompt_dismissed_v1';
  static const String _lastKnownStateKey = 'profile_last_known_state_v1';
  static const String _gettingStartedPendingKey = 'getting_started_pending_v1';

  Future<bool> isReviewPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reviewPendingKey) ?? false;
  }

  Future<void> setReviewPending(bool pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewPendingKey, pending);
  }

  Future<bool> missingStatePromptDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_missingStatePromptKey) ?? false;
  }

  Future<void> setMissingStatePromptDismissed(bool dismissed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_missingStatePromptKey, dismissed);
  }

  Future<String?> lastKnownState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastKnownStateKey);
  }

  Future<void> setLastKnownState(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null || code.trim().isEmpty) {
      await prefs.remove(_lastKnownStateKey);
      return;
    }
    await prefs.setString(_lastKnownStateKey, code);
  }

  Future<bool> isGettingStartedPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gettingStartedPendingKey) ?? false;
  }

  Future<void> setGettingStartedPending(bool pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gettingStartedPendingKey, pending);
  }
}
