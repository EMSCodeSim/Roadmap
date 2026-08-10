import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const String _kOnboardingComplete = 'fireops.onboardingComplete';
  static const String _kProfile = 'fireops.profile';
  static const String _kCertifications = 'fireops.certifications';
  static const String _kCustomRequirements = 'fireops.customRequirements';
  static const String _kPathOverrides = 'fireops.pathOverrides';

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
        final list = decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        return list;
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('LocalStore.loadJsonList($key) failed: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveJson(String key, Object value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(value));
    } catch (e) {
      debugPrint('LocalStore.saveJson($key) failed: $e');
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
}
