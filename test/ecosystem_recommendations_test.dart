import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/services/ecosystem_recommendations.dart';

void main() {
  group('FireOpsSim Daily Focus handoff', () {
    test('Firefighter II opens the Firefighter II focus library', () {
      final recommendation = EcosystemRecommendations.forTopic(
        'Coordinated ventilation Firefighter II',
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.product, 'FireOpsSim');
      expect(recommendation.title, 'Firefighter II Focus Drills');

      final uri = Uri.parse(recommendation.url);
      expect(uri.host, 'fireopssim.com');
      expect(uri.path, '/focus-drills.html');
      expect(uri.queryParameters['source'], 'roadmap');
      expect(uri.queryParameters['level'], 'firefighter_2');
      expect(
        uri.queryParameters['topic'],
        'Coordinated ventilation Firefighter II',
      );
    });

    test('HazMat Operations opens the HazMat wheel and drill library', () {
      final recommendation = EcosystemRecommendations.forTopic(
        'Decon corridor HazMat Operations',
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.title, 'HazMat Operations Focus Drills');
      expect(
        Uri.parse(recommendation.url).queryParameters['level'],
        'hazmat_ops',
      );
    });

    test('Driver Operator certification takes priority over pump tool fallback', () {
      final recommendation = EcosystemRecommendations.forTopic(
        'Pump discharge pressure Driver Operator Pumper',
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.product, 'FireOpsSim');
      expect(recommendation.title, 'Driver / Operator Focus Drills');
      expect(
        Uri.parse(recommendation.url).queryParameters['level'],
        'driver_operator',
      );
    });

    test('standalone hydraulics still recommends FireOps Calc', () {
      final recommendation = EcosystemRecommendations.forTopic(
        'friction loss and pump discharge pressure',
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.product, 'FireOps Calc');
    });

    test('EMS topics still route to EMSCodeSim', () {
      final recommendation = EcosystemRecommendations.forTopic(
        'paramedic patient assessment',
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.product, 'EMSCodeSim');
    });

    test('explicit Daily Focus builder includes complete Roadmap context', () {
      final recommendation = EcosystemRecommendations.forDailyFocus(
        topic: 'Initial radio report',
        qualification: 'Fire Officer I',
        goal: 'Lieutenant',
        taskId: 'officer-radio-report',
        requirementId: 'fire_officer_1',
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.actionLabel, 'Practice in FireOpsSim');
      final uri = Uri.parse(recommendation.url);
      expect(uri.queryParameters['level'], 'officer_1');
      expect(uri.queryParameters['topic'], 'Initial radio report');
      expect(uri.queryParameters['qualification'], 'Fire Officer I');
      expect(uri.queryParameters['goal'], 'Lieutenant');
      expect(uri.queryParameters['task_id'], 'officer-radio-report');
      expect(uri.queryParameters['requirement_id'], 'fire_officer_1');
    });
  });
}
