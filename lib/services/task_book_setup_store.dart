import 'package:shared_preferences/shared_preferences.dart';

class TaskBookSetupStore {
  static const String _reviewPendingKey = 'task_book_review_pending_v1';

  Future<bool> isReviewPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reviewPendingKey) ?? false;
  }

  Future<void> setReviewPending(bool pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewPendingKey, pending);
  }
}
