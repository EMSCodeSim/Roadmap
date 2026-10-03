import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CareerProgressPoint {
  final DateTime capturedAt;
  final String goalId;
  final int readinessScore;
  final int completedRequirements;
  final int totalRequirements;
  final int evidenceCovered;
  final int evidenceExpected;

  const CareerProgressPoint({
    required this.capturedAt,
    required this.goalId,
    required this.readinessScore,
    required this.completedRequirements,
    required this.totalRequirements,
    required this.evidenceCovered,
    required this.evidenceExpected,
  });

  Map<String, dynamic> toJson() => {
        'capturedAt': capturedAt.toIso8601String(),
        'goalId': goalId,
        'readinessScore': readinessScore,
        'completedRequirements': completedRequirements,
        'totalRequirements': totalRequirements,
        'evidenceCovered': evidenceCovered,
        'evidenceExpected': evidenceExpected,
      };

  factory CareerProgressPoint.fromJson(Map<String, dynamic> json) {
    return CareerProgressPoint(
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      goalId: json['goalId'] as String? ?? '',
      readinessScore: (json['readinessScore'] as num?)?.toInt() ?? 0,
      completedRequirements:
          (json['completedRequirements'] as num?)?.toInt() ?? 0,
      totalRequirements: (json['totalRequirements'] as num?)?.toInt() ?? 0,
      evidenceCovered: (json['evidenceCovered'] as num?)?.toInt() ?? 0,
      evidenceExpected: (json['evidenceExpected'] as num?)?.toInt() ?? 0,
    );
  }
}

class CareerProgressTrend {
  final int? readinessDelta30Days;
  final CareerProgressPoint? baseline;
  final CareerProgressPoint current;

  const CareerProgressTrend({
    required this.readinessDelta30Days,
    required this.baseline,
    required this.current,
  });
}

class CareerProgressHistoryStore {
  static const _key = 'fireops.career_progress_history.v1';

  Future<CareerProgressTrend> record({
    required CareerProgressPoint current,
  }) async {
    final points = await _load();
    final sameGoal = points.where((item) => item.goalId == current.goalId).toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

    CareerProgressPoint? baseline;
    final target = current.capturedAt.subtract(const Duration(days: 30));
    for (final point in sameGoal) {
      if (!point.capturedAt.isAfter(target)) baseline = point;
    }

    final currentDay = DateTime(
      current.capturedAt.year,
      current.capturedAt.month,
      current.capturedAt.day,
    );
    final next = points.where((point) {
      if (point.goalId != current.goalId) return true;
      final day = DateTime(
        point.capturedAt.year,
        point.capturedAt.month,
        point.capturedAt.day,
      );
      return day != currentDay;
    }).toList()
      ..add(current)
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

    final cutoff = current.capturedAt.subtract(const Duration(days: 120));
    final retained =
        next.where((point) => !point.capturedAt.isBefore(cutoff)).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(retained.map((point) => point.toJson()).toList()),
    );

    return CareerProgressTrend(
      readinessDelta30Days: baseline == null
          ? null
          : current.readinessScore - baseline.readinessScore,
      baseline: baseline,
      current: current,
    );
  }

  Future<List<CareerProgressPoint>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <CareerProgressPoint>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <CareerProgressPoint>[];
      return decoded
          .whereType<Map>()
          .map((item) =>
              CareerProgressPoint.fromJson(Map<String, dynamic>.from(item)))
          .where((point) => point.goalId.isNotEmpty)
          .toList();
    } catch (_) {
      return <CareerProgressPoint>[];
    }
  }
}
