import 'package:shared_preferences/shared_preferences.dart';

enum TaskBookFocus { personal, department }

class TaskBookFocusStore {
  static const _key = 'task_book_focus_v1';

  Future<TaskBookFocus> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return raw == TaskBookFocus.department.name
        ? TaskBookFocus.department
        : TaskBookFocus.personal;
  }

  Future<void> save(TaskBookFocus focus) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, focus.name);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
