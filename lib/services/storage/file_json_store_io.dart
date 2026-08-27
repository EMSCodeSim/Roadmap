import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:firepath/services/storage/file_json_store.dart';

class PlatformFileJsonStore implements FileJsonStore {
  PlatformFileJsonStore({this.rootPath});

  /// Optional override used by tests. When null, the app documents directory
  /// is resolved on first use.
  final String? rootPath;

  Directory? _cachedRoot;

  static final _safeKey = RegExp(r'^fireops\.[A-Za-z0-9._-]+$');

  Future<Directory?> _root() async {
    if (_cachedRoot != null) return _cachedRoot;
    try {
      if (rootPath != null) {
        final dir = Directory(rootPath!);
        if (!await dir.exists()) await dir.create(recursive: true);
        _cachedRoot = dir;
        return dir;
      }
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/fireops_data');
      if (!await dir.exists()) await dir.create(recursive: true);
      _cachedRoot = dir;
      return dir;
    } catch (e) {
      debugPrint('PlatformFileJsonStore._root failed: $e');
      return null;
    }
  }

  File? _fileFor(Directory root, String key) {
    if (!_safeKey.hasMatch(key)) return null;
    return File('${root.path}/$key.json');
  }

  @override
  Future<String?> read(String key) async {
    try {
      final root = await _root();
      if (root == null) return null;
      final file = _fileFor(root, key);
      if (file == null || !await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      debugPrint('PlatformFileJsonStore.read($key) failed: $e');
      return null;
    }
  }

  @override
  Future<bool> write(String key, String value) async {
    try {
      final root = await _root();
      if (root == null) return false;
      final file = _fileFor(root, key);
      if (file == null) return false;
      await file.writeAsString(value, flush: true);
      return true;
    } catch (e) {
      debugPrint('PlatformFileJsonStore.write($key) failed: $e');
      return false;
    }
  }

  @override
  Future<bool> remove(String key) async {
    try {
      final root = await _root();
      if (root == null) return true;
      final file = _fileFor(root, key);
      if (file == null) return true;
      if (await file.exists()) await file.delete();
      return true;
    } catch (e) {
      debugPrint('PlatformFileJsonStore.remove($key) failed: $e');
      return false;
    }
  }

  @override
  Future<Set<String>> listFireopsKeys() async {
    try {
      final root = await _root();
      if (root == null || !await root.exists()) return <String>{};
      final keys = <String>{};
      await for (final entity in root.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.isEmpty
            ? entity.path
            : entity.uri.pathSegments.last;
        if (!name.endsWith('.json')) continue;
        final key = name.substring(0, name.length - '.json'.length);
        if (_safeKey.hasMatch(key)) keys.add(key);
      }
      return keys;
    } catch (e) {
      debugPrint('PlatformFileJsonStore.listFireopsKeys failed: $e');
      return <String>{};
    }
  }

  @override
  Future<bool> clearFireops() async {
    try {
      final keys = await listFireopsKeys();
      var success = true;
      for (final key in keys) {
        if (!await remove(key)) success = false;
      }
      return success;
    } catch (e) {
      debugPrint('PlatformFileJsonStore.clearFireops failed: $e');
      return false;
    }
  }
}
