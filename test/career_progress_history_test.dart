import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/services/career_progress_history.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('career progress history creates a 30-day readiness trend', () async {
    final store = CareerProgressHistoryStore();

    await store.record(
      current: CareerProgressPoint(
        capturedAt: DateTime(2026, 8, 1),
        goalId: 'engineer',
        readinessScore: 42,
        completedRequirements: 4,
        totalRequirements: 10,
        evidenceCovered: 2,
        evidenceExpected: 6,
      ),
    );

    final trend = await store.record(
      current: CareerProgressPoint(
        capturedAt: DateTime(2026, 9, 5),
        goalId: 'engineer',
        readinessScore: 61,
        completedRequirements: 6,
        totalRequirements: 10,
        evidenceCovered: 4,
        evidenceExpected: 6,
      ),
    );

    expect(trend.readinessDelta30Days, 19);
    expect(trend.baseline?.readinessScore, 42);
    expect(trend.current.completedRequirements, 6);
  });

  test('career progress history keeps goals separate', () async {
    final store = CareerProgressHistoryStore();

    await store.record(
      current: CareerProgressPoint(
        capturedAt: DateTime(2026, 8, 1),
        goalId: 'captain',
        readinessScore: 80,
        completedRequirements: 8,
        totalRequirements: 10,
        evidenceCovered: 5,
        evidenceExpected: 5,
      ),
    );

    final trend = await store.record(
      current: CareerProgressPoint(
        capturedAt: DateTime(2026, 9, 5),
        goalId: 'engineer',
        readinessScore: 50,
        completedRequirements: 5,
        totalRequirements: 10,
        evidenceCovered: 3,
        evidenceExpected: 6,
      ),
    );

    expect(trend.readinessDelta30Days, isNull);
    expect(trend.baseline, isNull);
  });
}
