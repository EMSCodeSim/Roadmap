import 'package:flutter/foundation.dart';

import 'package:firepath/models/task_book.dart';
import 'package:firepath/services/local_store.dart';

/// Local persistence for task-level progress and user-created custom tasks.
///
/// This intentionally does NOT replace the existing roadmap/path overrides.
/// It layers on top of them so existing user data stays intact.
class TaskBookStore {
  final LocalStore _store = LocalStore();

  /// Loads a map of progress entries keyed by a stable string.
  Future<Map<String, TaskBookTaskProgress>> loadProgress() async {
    try {
      final raw = await _store.loadTaskBookTaskProgress();
      final out = <String, TaskBookTaskProgress>{};
      raw.forEach((k, v) {
        if (k is! String) return;
        if (v is! Map) return;
        try {
          out[k] = TaskBookTaskProgress.fromJson(Map<String, dynamic>.from(v));
        } catch (e) {
          debugPrint('TaskBookStore: skipping invalid progress $k: $e');
        }
      });
      return out;
    } catch (e) {
      debugPrint('TaskBookStore.loadProgress failed: $e');
      return <String, TaskBookTaskProgress>{};
    }
  }

  Future<void> saveProgress(Map<String, TaskBookTaskProgress> progress) async {
    try {
      final json = progress.map((k, v) => MapEntry(k, v.toJson()));
      await _store.saveTaskBookTaskProgress(json);
    } catch (e) {
      debugPrint('TaskBookStore.saveProgress failed: $e');
    }
  }

  Future<List<TaskBookTaskDefinition>> loadCustomTasks() async {
    try {
      final raw = await _store.loadTaskBookCustomTasks();
      return raw.map((e) {
        try {
          return TaskBookTaskDefinition.fromJson(e);
        } catch (err) {
          debugPrint('TaskBookStore: skipping invalid custom task: $err');
          return null;
        }
      }).whereType<TaskBookTaskDefinition>().toList();
    } catch (e) {
      debugPrint('TaskBookStore.loadCustomTasks failed: $e');
      return <TaskBookTaskDefinition>[];
    }
  }

  Future<void> saveCustomTasks(List<TaskBookTaskDefinition> tasks) async {
    try {
      await _store.saveTaskBookCustomTasks(tasks.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('TaskBookStore.saveCustomTasks failed: $e');
    }
  }

  static String progressKey(
          {required String goalId,
          required String requirementId,
          required String taskId}) =>
      '${goalId}::${requirementId}::${taskId}'.toLowerCase();
}
