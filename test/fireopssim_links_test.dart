import 'package:flutter_test/flutter_test.dart';
import 'package:firepath/services/fireopssim_links.dart';
import 'package:firepath/services/ecosystem_recommendations.dart';

void main() {
  group('FireOpsSimLinks', () {
    test('maps certification ids to focus levels', () {
      expect(FireOpsSimLinks.focusLevelFor('firefighter_1'), 'firefighter_1');
      expect(FireOpsSimLinks.focusLevelFor('firefighter_2'), 'firefighter_2');
      expect(
        FireOpsSimLinks.focusLevelFor('driver_operator_pumper'),
        'driver_operator',
      );
      expect(FireOpsSimLinks.focusLevelFor('fire_officer_1'), 'officer_1');
      expect(FireOpsSimLinks.focusLevelFor('fire_instructor_1'), 'instructor_1');
      expect(FireOpsSimLinks.focusLevelFor('hazmat_operations'), 'hazmat_ops');
    });

    test('builds contract-compliant handoff URLs', () {
      final focus = FireOpsSimLinks.focusDrills(
        cert: 'firefighter_2',
        topic: 'ventilation',
        goal: 'Firefighter II',
      );
      expect(focus.host, 'fireopssim.com');
      expect(focus.path, '/focus-drills.html');
      expect(focus.queryParameters['source'], 'roadmap');
      expect(focus.queryParameters['level'], 'firefighter_2');
      expect(focus.queryParameters['topic'], 'ventilation');

      final pathway = FireOpsSimLinks.pathwayRoadmap(
        cert: 'firefighter_1',
        state: 'co',
      );
      expect(pathway.path, '/pathway-roadmap.html');
      expect(pathway.queryParameters['pathway'], 'national.firefighter_i');
      expect(pathway.queryParameters['state'], 'CO');
      expect(pathway.queryParameters['autogen'], '1');

      final taskbook = FireOpsSimLinks.taskbookResources(
        cert: 'driver_operator_pumper',
        task: 'do_pumper_drafting',
        state: 'CO',
      );
      expect(taskbook.path, '/taskbook-resources.html');
      expect(taskbook.queryParameters['source'], 'roadmap');
      expect(taskbook.queryParameters['task'], 'do_pumper_drafting');
    });
  });

  group('EcosystemRecommendations FireOpsSim handoff', () {
    test('daily focus opens focus drills with level', () {
      final rec = EcosystemRecommendations.forDailyFocus(
        topic: 'hose stretch',
        qualification: 'Firefighter I',
        goal: 'Firefighter',
        certId: 'firefighter_1',
      );
      expect(rec, isNotNull);
      expect(rec!.url, contains('focus-drills.html'));
      expect(rec.url, contains('source=roadmap'));
      expect(rec.url, contains('level=firefighter_1'));
    });
  });
}
