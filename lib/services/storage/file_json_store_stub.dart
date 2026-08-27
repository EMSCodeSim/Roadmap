import 'package:firepath/services/storage/file_json_store.dart';

/// Web/stub: no documents directory. Callers fall back to SharedPreferences.
class PlatformFileJsonStore implements FileJsonStore {
  PlatformFileJsonStore({this.rootPath});

  /// Ignored on web. Present so tests can construct the same type.
  final String? rootPath;

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<bool> write(String key, String value) async => false;

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<Set<String>> listFireopsKeys() async => <String>{};

  @override
  Future<bool> clearFireops() async => true;
}
