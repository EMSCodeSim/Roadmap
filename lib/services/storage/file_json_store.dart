/// JSON document store used by [LocalStore] for durable career data.
///
/// Mobile/desktop writes into the app documents directory. Web keeps using
/// SharedPreferences/localStorage because a documents directory is not
/// available there; file backup/restore is the portable copy.
abstract class FileJsonStore {
  Future<String?> read(String key);
  Future<bool> write(String key, String value);
  Future<bool> remove(String key);
  Future<Set<String>> listFireopsKeys();
  Future<bool> clearFireops();
}
