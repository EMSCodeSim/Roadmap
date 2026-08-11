import 'package:flutter/foundation.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/local_store.dart';

class CareerRecordStore {
  static const String _storageKey = 'fireops.careerRecords.v1';
  final LocalStore _store = LocalStore();

  Future<List<CareerRecord>> load() async {
    final raw = await _store.loadJsonList(_storageKey);
    final records = <CareerRecord>[];
    for (final item in raw) {
      try {
        final record = CareerRecord.fromJson(item);
        if (record.id.isNotEmpty && record.title.trim().isNotEmpty) records.add(record);
      } catch (e) {
        debugPrint('Skipping invalid career record: $e');
      }
    }
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<void> save(List<CareerRecord> records) async {
    await _store.saveJson(_storageKey, records.map((e) => e.toJson()).toList());
  }
}
