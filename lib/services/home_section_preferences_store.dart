import 'package:flutter/foundation.dart';

import 'package:firepath/models/home_section_preference.dart';
import 'package:firepath/services/local_store.dart';

class HomeSectionPreferencesStore {
  static const String _storageKey = 'fireops.homeSections.v1';
  final LocalStore _store;

  HomeSectionPreferencesStore({LocalStore? store})
      : _store = store ?? LocalStore();

  static const List<HomeSectionPreference> defaults = [
    HomeSectionPreference(type: HomeSectionType.goal, visible: true),
    HomeSectionPreference(type: HomeSectionType.nextStep, visible: true),
    HomeSectionPreference(
      type: HomeSectionType.needsAttention,
      visible: true,
    ),
    HomeSectionPreference(
      type: HomeSectionType.careerSnapshot,
      visible: true,
    ),
    HomeSectionPreference(type: HomeSectionType.jobSearch, visible: false),
    HomeSectionPreference(type: HomeSectionType.dailyQuiz, visible: false),
    HomeSectionPreference(type: HomeSectionType.trainingIdeas, visible: false),
    HomeSectionPreference(type: HomeSectionType.department, visible: true),
  ];

  Future<List<HomeSectionPreference>> load() async {
    try {
      final raw = await _store.loadJsonList(_storageKey);
      if (raw.isEmpty) return List<HomeSectionPreference>.from(defaults);

      final parsed = <HomeSectionPreference>[];
      final seen = <HomeSectionType>{};
      for (final item in raw) {
        final preference = HomeSectionPreference.fromJson(item);
        if (preference != null && seen.add(preference.type)) {
          parsed.add(preference);
        }
      }
      for (final fallback in defaults) {
        if (seen.add(fallback.type)) parsed.add(fallback);
      }
      return parsed;
    } catch (error) {
      debugPrint('HomeSectionPreferencesStore.load failed: $error');
      return List<HomeSectionPreference>.from(defaults);
    }
  }

  Future<bool> save(List<HomeSectionPreference> preferences) async {
    try {
      return await _store.saveJsonChecked(
        _storageKey,
        preferences.map((item) => item.toJson()).toList(),
      );
    } catch (error) {
      debugPrint('HomeSectionPreferencesStore.save failed: $error');
      return false;
    }
  }
}
