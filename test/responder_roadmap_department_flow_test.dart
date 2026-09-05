import 'package:flutter_test/flutter_test.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

void main() {
  group('ResponderRoadmap department task flow', () {
    test('parses evaluator review steps and critical failures', () {
      final item = DepartmentReviewItem.fromJson({
        'id': 'completion-1',
        'memberName': 'Taylor Member',
        'taskBookTitle': 'Firefighter I',
        'requirementTitle': 'Deploy attack line',
        'reviewStage': 'EVALUATOR',
        'evaluationSteps': [
          {'id': 'step-1', 'text': 'Select the correct hose line'},
        ],
        'criticalFailures': [
          {'id': 'failure-1', 'text': 'Fails to use required PPE'},
        ],
      });

      expect(item.memberName, 'Taylor Member');
      expect(item.evaluationSteps.single.text, 'Select the correct hose line');
      expect(item.criticalFailures.single.id, 'failure-1');
    });

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

    test('returned work preserves correction instructions and reviewer identity', () {
      final requirement = DepartmentRequirement.fromJson({
        'id': 'req-6',
        'title': 'Patient Assessment',
        'repetitionsRequired': 1,
        'completion': {
          'status': 'RETURNED',
          'repetitionCount': 0,
          'correction': {
            'notes': 'Document a complete set of repeat vital signs.',
            'returnedByName': 'Jordan Evaluator',
            'returnedAt': '2026-09-04T16:30:00.000Z',
          },
        },
      });

      expect(requirement.canSubmit, isTrue);
      expect(
        requirement.correctionNotes,
        'Document a complete set of repeat vital signs.',
      );
      expect(requirement.returnedByName, 'Jordan Evaluator');
      expect(requirement.returnedAt, isNotNull);
    });

    test('identifies a standalone training assignment', () {
      final assignment = DepartmentTaskBookAssignment.fromJson({
        'id': 'assignment-1',
        'taskBookTitle': 'Review airway protocol update',
        'assignmentKind': 'TRAINING_TASK',
      });

      expect(assignment.isSingleTask, isTrue);
    });

    test('parses durable inbox, action count, and server timestamp', () {
      final inbox = DepartmentInbox.fromJson({
        'unreadCount': 2,
        'serverTime': '2026-09-04T18:30:00.000Z',
        'items': [
          {
            'id': 'notice-1',
            'type': 'SUBMISSION_RETURNED',
            'title': 'Corrections required',
            'body': 'Repeat the hose deployment.',
            'createdAt': '2026-09-04T18:29:00.000Z',
            'pushStatus': 'SENT',
          }
        ],
        'needsAction': [
          {
            'id': 'completion-1',
            'kind': 'MEMBER_CORRECTION',
            'title': 'Deploy attack line',
            'subtitle': 'Firefighter I',
          }
        ],
      });

      expect(inbox.unreadCount, 2);
      expect(inbox.items.single.pushStatus, 'SENT');
      expect(inbox.needsAction.single.kind, 'MEMBER_CORRECTION');
      expect(inbox.serverTime, isNotNull);
    });

    test('parses the server-recorded submission receipt', () {
      final receipt = DepartmentSubmissionReceipt.fromJson({
        'receiptId': 'completion-1',
        'clientRequestId': 'submission-phone-1',
        'status': 'SUBMITTED',
        'recordedAt': '2026-09-04T18:30:00.000Z',
        'recordedByName': 'Taylor Member',
      });

      expect(receipt.clientRequestId, 'submission-phone-1');
      expect(receipt.recordedAt, isNotNull);
      expect(receipt.recordedByName, 'Taylor Member');
    });

    test('parses member-controlled certification sharing state', () {
      final sharing = DepartmentCertificationSharing.fromJson({
        'sharedSourceIds': ['cert-1', 'cert-2'],
        'serverTime': '2026-09-05T12:00:00.000Z',
      });

      expect(sharing.sharedSourceIds, {'cert-1', 'cert-2'});
      expect(sharing.serverTime, isNotNull);
    });

    test('parses a proctor class roster and recorded skill result', () {
      final detail = DepartmentClassDetail.fromJson({
        'id': 'class-1', 'title': 'CPR Skills Day', 'classType': 'CPR', 'checklistTitle': 'BLS Provider', 'status': 'ACTIVE',
        'sections': [{'id': 'adult', 'title': 'Adult CPR', 'skills': [{'id': 'compressions', 'title': 'Adult compressions', 'required': true}]}],
        'roster': [{'id': 'enrollment-1', 'name': 'Taylor Member', 'email': 'taylor@example.com', 'attendance': 'PRESENT', 'finalResult': 'PENDING', 'results': [{'requirementId': 'compressions', 'result': 'PASS', 'evaluatorName': 'Jordan Proctor', 'evaluatedAt': '2026-09-05T18:00:00.000Z'}]}],
      });

      expect(detail.sections.single.skills.single.required, isTrue);
      expect(detail.roster.single.attendance, 'PRESENT');
      expect(detail.roster.single.results.single.evaluatorName, 'Jordan Proctor');
    });
  });
}
