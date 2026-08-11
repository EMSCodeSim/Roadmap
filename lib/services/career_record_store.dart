import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/local_store.dart';

class CareerRecordStore {
  static const String _legacyStorageKey = 'fireops.careerRecords.v1';
  static const String _yearIndexKey = 'fireops.careerRecords.v2.years';
  static const String _yearPrefix = 'fireops.careerRecords.v2.';
  final LocalStore _store = LocalStore();

  String _yearKey(int year) => '$_yearPrefix$year';

  Future<List<int>> _loadYears() async {
    final raw = await _store.loadJsonList(_yearIndexKey);
    final years = raw
        .map((e) => (e['year'] as num?)?.toInt())
        .whereType<int>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  Future<bool> _saveYears(Iterable<int> years) async {
    final sorted = years.toSet().toList()..sort((a, b) => b.compareTo(a));
    return _store.saveJsonChecked(
      _yearIndexKey,
      sorted.map((year) => <String, dynamic>{'year': year}).toList(),
    );
  }

  Future<List<CareerRecord>> _loadYear(int year) async {
    final raw = await _store.loadJsonList(_yearKey(year));
    final records = <CareerRecord>[];
    for (final item in raw) {
      try {
        final record = CareerRecord.fromJson(item);
        if (record.id.isNotEmpty && record.title.trim().isNotEmpty) records.add(record);
      } catch (e) {
        debugPrint('Skipping invalid career record for $year: $e');
      }
    }
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<List<CareerRecord>> load() async {
    var years = await _loadYears();
    if (years.isEmpty) {
      final legacy = await _loadLegacy();
      if (legacy.isNotEmpty) {
        final migrated = await save(legacy);
        if (migrated) {
          await _store.removeKey(_legacyStorageKey);
          years = await _loadYears();
        } else {
          return legacy;
        }
      }
    }

    final records = <CareerRecord>[];
    for (final year in years) {
      records.addAll(await _loadYear(year));
    }
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<List<CareerRecord>> _loadLegacy() async {
    final raw = await _store.loadJsonList(_legacyStorageKey);
    final records = <CareerRecord>[];
    for (final item in raw) {
      try {
        final record = CareerRecord.fromJson(item);
        if (record.id.isNotEmpty && record.title.trim().isNotEmpty) records.add(record);
      } catch (e) {
        debugPrint('Skipping invalid legacy career record: $e');
      }
    }
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  /// Replaces the full career record set. This remains available for the
  /// detailed evidence editor and restore workflow. Everyday Personal Log
  /// entries use [upsert] so only one year's segment is rewritten.
  Future<bool> save(List<CareerRecord> records) async {
    final existingYears = await _loadYears();
    final grouped = <int, List<CareerRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.date.year, () => <CareerRecord>[]).add(record);
    }

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => b.date.compareTo(a.date));
      final ok = await _store.saveJsonChecked(
        _yearKey(entry.key),
        entry.value.map((e) => e.toJson()).toList(),
      );
      if (!ok) return false;
    }

    for (final oldYear in existingYears.where((year) => !grouped.containsKey(year))) {
      final ok = await _store.removeKey(_yearKey(oldYear));
      if (!ok) return false;
    }

    return _saveYears(grouped.keys);
  }

  Future<bool> upsert(CareerRecord record) async {
    final year = record.date.year;
    final records = await _loadYear(year);
    final index = records.indexWhere((e) => e.id == record.id);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    records.sort((a, b) => b.date.compareTo(a.date));

    final saved = await _store.saveJsonChecked(
      _yearKey(year),
      records.map((e) => e.toJson()).toList(),
    );
    if (!saved) return false;
    final years = await _loadYears();
    if (!years.contains(year)) years.add(year);
    return _saveYears(years);
  }

  Future<bool> delete(CareerRecord record) async {
    final year = record.date.year;
    final records = await _loadYear(year);
    records.removeWhere((e) => e.id == record.id);
    if (records.isEmpty) {
      final removed = await _store.removeKey(_yearKey(year));
      if (!removed) return false;
      final years = await _loadYears()..remove(year);
      return _saveYears(years);
    }
    return _store.saveJsonChecked(
      _yearKey(year),
      records.map((e) => e.toJson()).toList(),
    );
  }

  Future<String> exportBackup() async {
    final records = await load();
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'fireops-career-log',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'records': records.map((e) => e.toJson()).toList(),
    });
  }

  Future<CareerRestoreResult> restoreBackup(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const CareerRestoreResult(success: false, count: 0, message: 'Backup is not valid JSON.');
      final map = Map<String, dynamic>.from(decoded);
      final recordsRaw = map['records'];
      if (map['format'] != 'fireops-career-log' || recordsRaw is! List) {
        return const CareerRestoreResult(success: false, count: 0, message: 'This is not a FireOps Career Log backup.');
      }
      final restored = <CareerRecord>[];
      for (final item in recordsRaw.whereType<Map>()) {
        final record = CareerRecord.fromJson(Map<String, dynamic>.from(item));
        if (record.id.isNotEmpty && record.title.trim().isNotEmpty) restored.add(record);
      }
      final ok = await save(restored);
      if (!ok) return const CareerRestoreResult(success: false, count: 0, message: 'The backup was read, but the device could not save it.');
      return CareerRestoreResult(success: true, count: restored.length, message: 'Restored ${restored.length} career records.');
    } catch (e) {
      debugPrint('CareerRecordStore.restoreBackup failed: $e');
      return const CareerRestoreResult(success: false, count: 0, message: 'Backup could not be read. Check that the complete backup text was pasted.');
    }
  }
}

class CareerRestoreResult {
  final bool success;
  final int count;
  final String message;

  const CareerRestoreResult({required this.success, required this.count, required this.message});
}
