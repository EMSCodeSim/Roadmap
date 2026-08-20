import 'package:flutter/foundation.dart';

import 'package:firepath/models/home_quick_action.dart';
import 'package:firepath/services/local_store.dart';

class HomeQuickActionsStore {
  static const String _storageKey = 'fireops.homeQuickActions.v1';
  final LocalStore _store;

  HomeQuickActionsStore({LocalStore? store}) : _store = store ?? LocalStore();

  static const List<HomeQuickAction> defaults = [
    HomeQuickAction(type: HomeQuickActionType.quickLog),
    HomeQuickAction(type: HomeQuickActionType.dailyFocus),
    HomeQuickAction(type: HomeQuickActionType.openTaskBook),
    HomeQuickAction(type: HomeQuickActionType.openCerts),
  ];

  Future<List<HomeQuickAction>> load() async {
    try {
      final raw = await _store.loadJsonList(_storageKey);
      if (raw.isEmpty) return defaults;

      final parsed = raw
          .map((e) => HomeQuickAction.fromJson(e))
          .where((e) => e.isValid)
          .toList(growable: false);
      return parsed.isEmpty ? defaults : parsed;
    } catch (e) {
      debugPrint('HomeQuickActionsStore.load failed: $e');
      return defaults;
    }
  }

  Future<bool> save(List<HomeQuickAction> actions) async {
    try {
      final normalized = actions.where((e) => e.isValid).map((e) => e.toJson()).toList();
      return await _store.saveJsonChecked(_storageKey, normalized);
    } catch (e) {
      debugPrint('HomeQuickActionsStore.save failed: $e');
      return false;
    }
  }

  Future<void> resetToDefaults() async {
    await save(defaults);
  }
}
