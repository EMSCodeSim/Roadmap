import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const String _kOnboardingComplete = 'fireops.onboardingComplete';
  static const String _kProfile = 'fireops.profile';
  static const String _kCertifications = 'fireops.certifications';
  static const String _kCustomRequirements = 'fireops.customRequirements';
  static const String _kPathOverrides = 'fireops.pathOverrides';
  static const String _kCertMatchConfirmations = 'fireops.certMatchConfirmations';

  // Task Book (new in Career Task Book system). Kept separate so existing
  // roadmap/path data remains intact.
  static const String _kTaskBookTaskProgress = 'fireops.taskBook.taskProgress';
  static const String _kTaskBookCustomTasks = 'fireops.taskBook.customTasks';

  Future<bool> getOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kOnboardingComplete) ?? false;
    } catch (e) {
      debugPrint('LocalStore.getOnboardingComplete failed: $e');
      return false;
    }
  }

  Future<void> setOnboardingComplete(bool v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingComplete, v);
    } catch (e) {
      debugPrint('LocalStore.setOnboardingComplete failed: $e');
    }
  }

  Future<Map<String, dynamic>?> loadJsonMap(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (e) {
      debugPrint('LocalStore.loadJsonMap($key) failed: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadJsonList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('LocalStore.loadJsonList($key) failed: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveJson(String key, Object value) async {
    await saveJsonChecked(key, value);
  }

  /// Saves JSON and reports whether the write actually succeeded.
  ///
  /// Use this for user-generated career history where the UI must not report a
  /// successful save if SharedPreferences rejected the write.
  Future<bool> saveJsonChecked(String key, Object value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, jsonEncode(value));
    } catch (e) {
      debugPrint('LocalStore.saveJsonChecked($key) failed: $e');
      return false;
    }
  }

  Future<bool> removeKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      debugPrint('LocalStore.removeKey($key) failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> loadProfile() => loadJsonMap(_kProfile);
  Future<void> saveProfile(Map<String, dynamic> json) => saveJson(_kProfile, json);

  Future<List<Map<String, dynamic>>> loadCertifications() => loadJsonList(_kCertifications);
  Future<void> saveCertifications(List<Map<String, dynamic>> json) => saveJson(_kCertifications, json);

  Future<List<Map<String, dynamic>>> loadCustomRequirements() => loadJsonList(_kCustomRequirements);
  Future<void> saveCustomRequirements(List<Map<String, dynamic>> json) => saveJson(_kCustomRequirements, json);

  Future<List<Map<String, dynamic>>> loadPathOverrides() => loadJsonList(_kPathOverrides);
  Future<void> savePathOverrides(List<Map<String, dynamic>> json) => saveJson(_kPathOverrides, json);

  /// Stores user-confirmed mappings for uncertain certification matches.
  ///
  /// Map key: normalized user-entered certification text
  /// Map value: certificationDefinitionId OR empty string meaning "no match"
  Future<Map<String, dynamic>> loadCertificationMatchConfirmations() async =>
      (await loadJsonMap(_kCertMatchConfirmations)) ?? <String, dynamic>{};
  Future<void> saveCertificationMatchConfirmations(Map<String, dynamic> json) =>
      saveJson(_kCertMatchConfirmations, json);

  // --- Task Book ---

  /// Map storage (key -> json) for per-task progress.
  Future<Map<String, dynamic>> loadTaskBookTaskProgress() async =>
      (await loadJsonMap(_kTaskBookTaskProgress)) ?? <String, dynamic>{};
  Future<void> saveTaskBookTaskProgress(Map<String, dynamic> json) =>
      saveJson(_kTaskBookTaskProgress, json);

  /// List storage for user-created custom tasks.
  Future<List<Map<String, dynamic>>> loadTaskBookCustomTasks() =>
      loadJsonList(_kTaskBookCustomTasks);
  Future<void> saveTaskBookCustomTasks(List<Map<String, dynamic>> json) =>
      saveJson(_kTaskBookCustomTasks, json);
}
