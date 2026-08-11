import 'package:firepath/models/quick_log_template.dart';
import 'package:firepath/services/local_store.dart';

class QuickLogPreferencesStore {
  static const String _storageKey = 'fireops.quickLogPreferences.v1';
  final LocalStore _store = LocalStore();

  static const List<String> defaultPinnedIds = [
    'ems.iv',
    'ems.io',
    'ems.airway',
    'fire.car_fire',
    'fire.structure_fire',
    'fire.pump_ops',
  ];

  Future<QuickLogPreferences> load() async {
    final json = await _store.loadJsonMap(_storageKey);
    if (json == null) {
      return const QuickLogPreferences(
        pinnedIds: defaultPinnedIds,
        customTemplates: <QuickLogTemplate>[],
      );
    }
    final parsed = QuickLogPreferences.fromJson(json);
    if (parsed.pinnedIds.isEmpty) {
      return QuickLogPreferences(
        pinnedIds: defaultPinnedIds,
        customTemplates: parsed.customTemplates,
      );
    }
    return parsed;
  }

  Future<void> save(QuickLogPreferences preferences) => _store.saveJson(_storageKey, preferences.toJson());
}
