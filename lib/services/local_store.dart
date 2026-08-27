import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/services/storage/file_json_store.dart';
import 'package:firepath/services/storage/file_json_store_platform.dart';

class LocalStore {
  LocalStore({FileJsonStore? fileStore})
      : _files = fileStore ?? PlatformFileJsonStore();

  static const String _kOnboardingComplete = 'fireops.onboardingComplete';
  static const String _kProfile = 'fireops.profile';
  static const String _kCertifications = 'fireops.certifications';
  static const String _kCustomRequirements = 'fireops.customRequirements';
  static const String _kPathOverrides = 'fireops.pathOverrides';
  static const String _kCertMatchConfirmations = 'fireops.certMatchConfirmations';
  static const String _kTaskBookTaskProgress = 'fireops.taskBook.taskProgress';
  static const String _kTaskBookCustomTasks = 'fireops.taskBook.customTasks';
  static const String _kTaskBookCustomBooks = 'fireops.taskBook.customBooks.v1';
  static const String _kTaskBookActiveBook = 'fireops.taskBook.activeBook.v1';

  final FileJsonStore _files;

  Future<bool> getOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kOnboardingComplete) ?? false;
    } catch (e) {
      debugPrint('LocalStore.getOnboardingComplete failed: $e');
      return false;
    }
  }

  Future<void> setOnboardingComplete(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingComplete, value);
    } catch (e) {
      debugPrint('LocalStore.setOnboardingComplete failed: $e');
    }
  }

  Future<String?> _readRaw(String key) async {
    final fromFile = await _files.read(key);
    if (fromFile != null) return fromFile;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final migrated = await _files.write(key, raw);
      if (migrated) {
        await prefs.remove(key);
      }
      return raw;
    } catch (e) {
      debugPrint('LocalStore._readRaw($key) failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> loadJsonMap(String key) async {
    try {
      final raw = await _readRaw(key);
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
      final raw = await _readRaw(key);
      if (raw == null) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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
  Future<bool> saveJsonChecked(String key, Object value) async {
    final encoded = jsonEncode(value);
    final fileOk = await _files.write(key, encoded);
    if (fileOk) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } catch (e) {
        debugPrint('LocalStore.saveJsonChecked prefs cleanup failed: $e');
      }
      return true;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, encoded);
    } catch (e) {
      debugPrint('LocalStore.saveJsonChecked($key) failed: $e');
      return false;
    }
  }

  Future<bool> removeKey(String key) async {
    final fileOk = await _files.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsOk = await prefs.remove(key);
      return fileOk && prefsOk;
    } catch (e) {
      debugPrint('LocalStore.removeKey($key) failed: $e');
      return false;
    }
  }

  /// Removes every FireOps-owned preference, including dynamically named
  /// yearly career-record segments. Other preferences on the device are left
  /// untouched.
  Future<bool> resetAppData() async {
    var success = await _files.clearFireops();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('fireops.'));
      for (final key in keys) {
        if (!await prefs.remove(key)) success = false;
      }
      return success;
    } catch (e) {
      debugPrint('LocalStore.resetAppData failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> loadProfile() => loadJsonMap(_kProfile);
  Future<void> saveProfile(Map<String, dynamic> json) => saveJson(_kProfile, json);

  Future<List<Map<String, dynamic>>> loadCertifications() =>
      loadJsonList(_kCertifications);
  Future<void> saveCertifications(List<Map<String, dynamic>> json) =>
      saveJson(_kCertifications, json);

  Future<List<Map<String, dynamic>>> loadCustomRequirements() =>
      loadJsonList(_kCustomRequirements);
  Future<void> saveCustomRequirements(List<Map<String, dynamic>> json) =>
      saveJson(_kCustomRequirements, json);

  Future<List<Map<String, dynamic>>> loadPathOverrides() =>
      loadJsonList(_kPathOverrides);
  Future<void> savePathOverrides(List<Map<String, dynamic>> json) =>
      saveJson(_kPathOverrides, json);

  Future<Map<String, dynamic>> loadCertificationMatchConfirmations() async =>
      (await loadJsonMap(_kCertMatchConfirmations)) ?? <String, dynamic>{};
  Future<void> saveCertificationMatchConfirmations(Map<String, dynamic> json) =>
      saveJson(_kCertMatchConfirmations, json);

  Future<Map<String, dynamic>> loadTaskBookTaskProgress() async =>
      (await loadJsonMap(_kTaskBookTaskProgress)) ?? <String, dynamic>{};
  Future<bool> saveTaskBookTaskProgress(Map<String, dynamic> json) =>
      saveJsonChecked(_kTaskBookTaskProgress, json);

  Future<List<Map<String, dynamic>>> loadTaskBookCustomTasks() =>
      loadJsonList(_kTaskBookCustomTasks);
  Future<bool> saveTaskBookCustomTasks(List<Map<String, dynamic>> json) =>
      saveJsonChecked(_kTaskBookCustomTasks, json);

  Future<List<Map<String, dynamic>>> loadTaskBookCustomBooks() =>
      loadJsonList(_kTaskBookCustomBooks);
  Future<bool> saveTaskBookCustomBooks(List<Map<String, dynamic>> json) =>
      saveJsonChecked(_kTaskBookCustomBooks, json);

  Future<Map<String, dynamic>?> loadTaskBookActiveBook() =>
      loadJsonMap(_kTaskBookActiveBook);
  Future<bool> saveTaskBookActiveBook(Map<String, dynamic> json) =>
      saveJsonChecked(_kTaskBookActiveBook, json);
}
