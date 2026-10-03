import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/career_coach.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Career Coach suggests linking recent matching evidence', () async {
    final app = AppState();
    await app.bootstrap();

    final goal = app.availableGoals.firstWhere(
      (item) => item.requirements.isNotEmpty,
    );
    await app.setPrimaryGoal(goal.id);

    final roadmap = app.roadmap!;
    final requirement = roadmap.included.first;
    final now = DateTime(2026, 10, 3);

    final record = CareerRecord(
      id: 'r1',
      type: CareerRecordType.skill,
      title: requirement.requirement.name,
      category: requirement.requirement.category,
      date: now.subtract(const Duration(days: 2)),
      roleOrAssignment: null,
      summary: requirement.requirement.description,
      impact: null,
      evidenceReference: null,
      hours: 1,
      repetitions: 1,
      tags: [requirement.requirement.category],
      relatedGoalId: null,
      relatedRequirementId: null,
      relatedTaskId: null,
      highlight: false,
      trackingKey: null,
      outcome: CareerRecordOutcome.completed,
      details: const {},
      createdAt: now,
      updatedAt: now,
    );

    final prompts = CareerCoachEngine.build(
      app: app,
      records: [record],
      now: now,
    );

    expect(
      prompts.any(
        (prompt) =>
            prompt.kind == CareerCoachKind.evidenceSuggestion &&
            prompt.requirement?.requirement.id ==
                requirement.requirement.id,
      ),
      isTrue,
    );
  });
}
