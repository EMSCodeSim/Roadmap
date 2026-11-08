import 'package:flutter/foundation.dart';

/// Utilities for computing elapsed training minutes and day/night splits.
///
/// Notes:
/// - All calculations operate on local [DateTime] values to respect DST.
/// - Splits are minute-precise and always sum back to the total.
class TrainingTimeCalculator {
  static const DayNightDefinition defaultDayNight = DayNightDefinition(
    dayStartMinutes: 6 * 60,
    dayEndMinutes: 18 * 60,
    label: 'Default day/night: 06:00–18:00',
  );

  static int? elapsedMinutes(DateTime startLocal, DateTime? endLocal) {
    if (endLocal == null) return null;
    final minutes = endLocal.difference(startLocal).inMinutes;
    if (minutes <= 0) return null;
    return minutes;
  }

  static DayNightSplit splitDayNight({
    required DateTime startLocal,
    required DateTime endLocal,
    required DayNightDefinition definition,
  }) {
    var total = endLocal.difference(startLocal).inMinutes;
    if (total <= 0) {
      return const DayNightSplit(totalMinutes: 0, dayMinutes: 0, nightMinutes: 0);
    }

    // Iterate window-by-window across day/night boundaries. We avoid per-minute
    // loops for performance and keep boundaries anchored to local calendar days.
    var cursor = startLocal;
    var dayMinutes = 0;
    var nightMinutes = 0;

    while (cursor.isBefore(endLocal)) {
      final boundary = _nextBoundary(cursor, definition);
      final segmentEnd = boundary.isBefore(endLocal) ? boundary : endLocal;
      final segmentMinutes = segmentEnd.difference(cursor).inMinutes;
      if (segmentMinutes <= 0) break;

      if (_isDay(cursor, definition)) {
        dayMinutes += segmentMinutes;
      } else {
        nightMinutes += segmentMinutes;
      }
      cursor = segmentEnd;
    }

    final computedTotal = dayMinutes + nightMinutes;
    if (computedTotal != total) {
      // Guard against any rounding/edge-case issues.
      debugPrint('TrainingTimeCalculator split mismatch: total=$total computed=$computedTotal');
      if (computedTotal < total) {
        // Assign remainder to the segment where the end lands.
        final remainder = total - computedTotal;
        if (_isDay(endLocal.subtract(const Duration(minutes: 1)), definition)) {
          dayMinutes += remainder;
        } else {
          nightMinutes += remainder;
        }
      } else {
        // Trim overflow conservatively from night.
        final overflow = computedTotal - total;
        nightMinutes = (nightMinutes - overflow).clamp(0, nightMinutes);
      }
    }

    return DayNightSplit(totalMinutes: total, dayMinutes: dayMinutes, nightMinutes: nightMinutes);
  }

  static bool _isDay(DateTime local, DayNightDefinition def) {
    final minutes = local.hour * 60 + local.minute;
    // Treat [dayStart, dayEnd) as day.
    return minutes >= def.dayStartMinutes && minutes < def.dayEndMinutes;
  }

  static DateTime _nextBoundary(DateTime local, DayNightDefinition def) {
    final date = DateTime(local.year, local.month, local.day);
    final dayStart = date.add(Duration(minutes: def.dayStartMinutes));
    final dayEnd = date.add(Duration(minutes: def.dayEndMinutes));

    // Next transition after `local`.
    if (local.isBefore(dayStart)) return dayStart;
    if (local.isBefore(dayEnd)) return dayEnd;
    // After today's dayEnd -> next dayStart.
    final nextDay = DateTime(local.year, local.month, local.day).add(const Duration(days: 1));
    return nextDay.add(Duration(minutes: def.dayStartMinutes));
  }
}

class DayNightDefinition {
  final int dayStartMinutes;
  final int dayEndMinutes;
  final String label;
  const DayNightDefinition({required this.dayStartMinutes, required this.dayEndMinutes, required this.label});
}

class DayNightSplit {
  final int totalMinutes;
  final int dayMinutes;
  final int nightMinutes;
  const DayNightSplit({required this.totalMinutes, required this.dayMinutes, required this.nightMinutes});
}

String formatMinutesAsHoursMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h <= 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}
