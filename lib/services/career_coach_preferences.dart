import 'package:shared_preferences/shared_preferences.dart';

class CareerCoachPreferences {
  static const _key = 'fireops.careerCoach.dismissed.v1';

  Future<Map<String, DateTime>> loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final result = <String, DateTime>{};
    for (final item in raw) {
      final split = item.split('|');
      if (split.length != 2) continue;
      final until = DateTime.tryParse(split[1]);
      if (until != null && until.isAfter(DateTime.now())) {
        result[split[0]] = until;
      }
    }
    return result;
  }

  Future<void> dismiss(String id, {Duration forDuration = const Duration(days: 14)}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadDismissed();
    current[id] = DateTime.now().add(forDuration);
    await prefs.setStringList(
      _key,
      current.entries
          .map((entry) => entry.key + '|' + entry.value.toIso8601String())
          .toList(growable: false),
    );
  }
}
