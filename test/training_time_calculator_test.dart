import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/services/training_time_calculator.dart';

void main() {
  group('TrainingTimeCalculator', () {
    test('09:00–12:30 = 3h 30m', () {
      final start = DateTime(2026, 1, 1, 9, 0);
      final end = DateTime(2026, 1, 1, 12, 30);
      final minutes = TrainingTimeCalculator.elapsedMinutes(start, end);
      expect(minutes, 210);
      expect(formatMinutesAsHoursMinutes(minutes!), '3h 30m');
    });

    test('17:00–20:00 splits into 1h day and 2h night (06–18 day)', () {
      final start = DateTime(2026, 1, 1, 17, 0);
      final end = DateTime(2026, 1, 1, 20, 0);
      final split = TrainingTimeCalculator.splitDayNight(
        startLocal: start,
        endLocal: end,
        definition: TrainingTimeCalculator.defaultDayNight,
      );
      expect(split.totalMinutes, 180);
      expect(split.dayMinutes, 60);
      expect(split.nightMinutes, 120);
    });

    test('22:00–02:00 next day = 4h', () {
      final start = DateTime(2026, 1, 1, 22, 0);
      final end = DateTime(2026, 1, 2, 2, 0);
      final minutes = TrainingTimeCalculator.elapsedMinutes(start, end);
      expect(minutes, 240);
    });

    test('rounds training time to the nearest quarter hour', () {
      expect(TrainingTimeCalculator.roundMinutesToQuarterHour(67), 60);
      expect(TrainingTimeCalculator.roundMinutesToQuarterHour(68), 75);
      expect(TrainingTimeCalculator.quarterHoursFromMinutes(82), 1.25);
      expect(formatQuarterHoursFromMinutes(98), '1.75 hr');
    });

    test('rounded day and night values still equal rounded total', () {
      const split = DayNightSplit(
        totalMinutes: 70,
        dayMinutes: 35,
        nightMinutes: 35,
      );
      final rounded =
          TrainingTimeCalculator.roundDayNightSplitToQuarterHour(split);
      expect(rounded.totalMinutes, 75);
      expect(rounded.dayMinutes + rounded.nightMinutes, 75);
      expect(rounded.dayMinutes % 15, 0);
      expect(rounded.nightMinutes % 15, 0);
    });

    test('Negative or zero duration returns null elapsed', () {
      final start = DateTime(2026, 1, 1, 10, 0);
      expect(TrainingTimeCalculator.elapsedMinutes(start, start), isNull);
      expect(TrainingTimeCalculator.elapsedMinutes(start, start.subtract(const Duration(minutes: 1))), isNull);
    });
  });
}
