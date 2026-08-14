import 'package:firepath/models/apparatus_profile.dart';
import 'package:firepath/services/local_store.dart';

class ApparatusProfileStore {
  static const _key = 'fireops.apparatusProfiles.v1';
  final LocalStore _store = LocalStore();

  Future<List<ApparatusProfile>> load() async {
    final raw = await _store.loadJsonList(_key);
    return raw
        .map(ApparatusProfile.fromJson)
        .where((profile) => profile.id.isNotEmpty && profile.name.trim().isNotEmpty)
        .toList();
  }

  Future<bool> save(List<ApparatusProfile> profiles) =>
      _store.saveJsonChecked(_key, profiles.map((e) => e.toJson()).toList());
}
