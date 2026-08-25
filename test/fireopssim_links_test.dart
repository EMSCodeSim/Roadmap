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
        qualification: 'Firefighter II',
        taskId: 'ff2-vent',
        requirementId: 'firefighter_2',
      );
      expect(focus.host, 'fireopssim.com');
      expect(focus.path, '/focus-drills.html');
      expect(focus.queryParameters['source'], 'roadmap');
      expect(focus.queryParameters['level'], 'firefighter_2');
      expect(focus.queryParameters['topic'], 'ventilation');
      expect(focus.queryParameters['qualification'], 'Firefighter II');
      expect(focus.queryParameters['task_id'], 'ff2-vent');
      expect(focus.queryParameters['requirement_id'], 'firefighter_2');

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
    test('daily focus opens focus drills with level and ids', () {
      final rec = EcosystemRecommendations.forDailyFocus(
        topic: 'Initial radio report',
        qualification: 'Fire Officer I',
        goal: 'Lieutenant',
        taskId: 'officer-radio-report',
        requirementId: 'fire_officer_1',
        certId: 'fire_officer_1',
      );
      expect(rec, isNotNull);
      expect(rec!.url, contains('focus-drills.html'));
      expect(rec.url, contains('source=roadmap'));
      expect(rec.url, contains('level=officer_1'));
      expect(rec.url, contains('task_id=officer-radio-report'));
      expect(rec.url, contains('requirement_id=fire_officer_1'));
    });
  });
}
