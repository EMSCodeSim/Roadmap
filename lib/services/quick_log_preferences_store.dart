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

  static const List<String> defaultQuickActionKeys = [
    'call',
    'training',
    'skill',
    'drive',
    'task_book',
    'career',
  ];

  Future<QuickLogPreferences> load() async {
    final json = await _store.loadJsonMap(_storageKey);
    if (json == null) {
      return const QuickLogPreferences(
        pinnedIds: defaultPinnedIds,
        customTemplates: <QuickLogTemplate>[],
        quickActionKeys: defaultQuickActionKeys,
      );
    }
    final parsed = QuickLogPreferences.fromJson(json);

    final pinned = parsed.pinnedIds.isEmpty ? defaultPinnedIds : parsed.pinnedIds;
    final quickKeys = parsed.quickActionKeys.isEmpty
        ? defaultQuickActionKeys
        : parsed.quickActionKeys;

    return QuickLogPreferences(
      pinnedIds: pinned,
      customTemplates: parsed.customTemplates,
      quickActionKeys: quickKeys,
    );
  }

  Future<void> save(QuickLogPreferences preferences) => _store.saveJson(_storageKey, preferences.toJson());
}
