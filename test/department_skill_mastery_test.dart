import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

void main() {
  test('Department Skill Mastery parses graded retention data', () {
    final mastery = DepartmentSkillMastery.fromJson({
      'settings': {
        'proficiencyThreshold': 80,
        'reassessmentDays': 180,
      },
      'skills': [
        {
          'skillId': 'pump-1',
          'skillName': 'Pump Operations',
          'status': 'PROFICIENT',
          'stale': false,
          'trend': 'IMPROVING',
          'latestScore': 91,
          'previousScore': 82,
          'latestResult': 'PASS',
          'lastEvaluatedAt': '2026-09-20T12:00:00.000Z',
          'observations': 3,
          'evaluatorName': 'Captain Example',
          'source': 'CLASS',
          'referenceTitle': 'Pump Skills',
        }
      ],
    });

    expect(mastery.proficiencyThreshold, 80);
    expect(mastery.reassessmentDays, 180);
    expect(mastery.skills, hasLength(1));
    expect(mastery.skills.first.skillName, 'Pump Operations');
    expect(mastery.skills.first.latestScore, 91);
    expect(mastery.skills.first.trend, 'IMPROVING');
  });
}
