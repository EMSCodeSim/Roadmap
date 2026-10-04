import 'package:firepath/services/local_store.dart';

class ScoredSkillPreference {
  final String keyName;
  final String title;

  const ScoredSkillPreference({
    required this.keyName,
    required this.title,
  });

  Map<String, dynamic> toJson() => {
        'keyName': keyName,
        'title': title,
      };

  factory ScoredSkillPreference.fromJson(Map<String, dynamic> json) =>
      ScoredSkillPreference(
        keyName: (json['keyName'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
      );
}

/// Stores which skills the responder wants displayed as success-rate metrics.
///
/// IV remains enabled by default for backwards compatibility, but every other
/// skill is opt-in. These are personal analytics preferences and do not change
/// department competency or qualification records.
class ScoredSkillStore {
  ScoredSkillStore({LocalStore? store}) : _store = store ?? LocalStore();

  static const _key = 'fireops.scoredSkills.v1';

  final LocalStore _store;

  Future<List<ScoredSkillPreference>> load() async {
    final raw = await _store.loadJsonMap(_key);
    final entries = raw?['skills'];
    if (entries is List) {
      final parsed = entries
          .whereType<Map>()
          .map((item) => ScoredSkillPreference.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((item) => item.keyName.isNotEmpty && item.title.isNotEmpty)
          .toList(growable: false);
      if (parsed.isNotEmpty || raw?['initialized'] == true) return parsed;
    }
    return const [
      ScoredSkillPreference(keyName: 'ems.iv', title: 'IV / vascular access'),
    ];
  }

  Future<void> save(List<ScoredSkillPreference> skills) async {
    await _store.saveJson(
      _key,
      <String, dynamic>{
        'initialized': true,
        'skills': skills.map((item) => item.toJson()).toList(),
      },
    );
  }

  static String keyForTitle(String title) {
    final normalized = title
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    if (normalized.contains('iv') || normalized.contains('vascular')) {
      return 'ems.iv';
    }
    return normalized.isEmpty ? 'skill.custom' : 'skill.$normalized';
  }
}
