import 'package:flutter_test/flutter_test.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

void main() {
  group('ResponderRoadmap department task flow', () {
    test('shows supervisor approval as a distinct pending stage', () {
      final requirement = DepartmentRequirement.fromJson({
        'id': 'req-1',
        'title': 'Pump Operations',
        'evaluatorSignOffRequired': true,
        'supervisorApprovalRequired': true,
        'repetitionsRequired': 1,
        'reviewStage': 'SUPERVISOR',
        'completion': {
          'status': 'SUBMITTED',
          'repetitionCount': 0,
          'memberNotes': 'Completed evolution',
        },
      });

      expect(requirement.isAwaitingReview, isTrue);
      expect(requirement.canSubmit, isFalse);
      expect(requirement.reviewLabel, 'Waiting for supervisor approval');
    });

    test('blocks submission and names unmet prerequisites', () {
      final requirement = DepartmentRequirement.fromJson({
        'id': 'req-2',
        'title': 'Emergency Driving',
        'repetitionsRequired': 1,
        'blockedByPrerequisites': true,
        'prerequisites': ['req-1'],
        'prerequisiteTitles': ['Apparatus Orientation'],
      });

      expect(requirement.blockedByPrerequisites, isTrue);
      expect(requirement.prerequisiteTitles, ['Apparatus Orientation']);
      expect(requirement.canSubmit, isFalse);
    });

    test('respects department setting that disables member notes', () {
      final requirement = DepartmentRequirement.fromJson({
        'id': 'req-3',
        'title': 'Knowledge Check',
        'memberNotesAllowed': false,
        'repetitionsRequired': 1,
      });

      expect(requirement.memberNotesAllowed, isFalse);
    });

    test('partial approved repetitions remain available for the next attempt', () {
      final requirement = DepartmentRequirement.fromJson({
        'id': 'req-4',
        'title': 'Hydrant Evolution',
        'repetitionsRequired': 5,
        'completion': {
          'status': 'APPROVED',
          'repetitionCount': 2,
          'memberNotes': '',
        },
      });

      expect(requirement.repetitionCount, 2);
      expect(requirement.isFullyApproved, isFalse);
      expect(requirement.canSubmit, isTrue);
    });

    test('final approved repetition closes the requirement', () {
      final requirement = DepartmentRequirement.fromJson({
        'id': 'req-5',
        'title': 'Hydrant Evolution',
        'repetitionsRequired': 5,
        'completion': {
          'status': 'APPROVED',
          'repetitionCount': 5,
          'memberNotes': '',
        },
      });

      expect(requirement.isFullyApproved, isTrue);
      expect(requirement.canSubmit, isFalse);
    });
  });
}
