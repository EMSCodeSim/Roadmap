import 'package:flutter_test/flutter_test.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/pages/department/class_workflow_rules.dart';

DepartmentClassStudent student(String id, String? membershipId, String attendance) =>
    DepartmentClassStudent(
      id: id, membershipId: membershipId, name: id, email: '',
      attendance: attendance, writtenScore: null, ccfScore: null,
      finalResult: 'PENDING', results: const [],
    );

void main() {
  group('Class to Task Book end-to-end safety contract', () {
    final roster = [
      student('recruit-a', 'member-a', 'PRESENT'),
      student('recruit-b', 'member-b', 'PRESENT'),
      student('absent', 'member-c', 'ABSENT'),
      student('guest', null, 'PRESENT'),
      student('duplicate', 'member-a', 'PRESENT'),
    ];

    test('class roster assignment excludes guests and duplicate membership IDs', () {
      expect(eligibleClassMembershipIds(roster), ['member-a', 'member-b', 'member-c']);
      expect(eligibleClassMembershipIds(roster, presentOnly: true), ['member-a', 'member-b']);
    });

    test('a failed, unapproved or absent skill cannot count as approved evidence', () {
      bool valid(String status, bool approved, String attendance, String result) =>
          hasApprovedPassingClassEvidence(
            classStatus: status, instructorApproved: approved,
            attendance: attendance, skillResult: result,
          );
      expect(valid('COMPLETE', true, 'PRESENT', 'PASS'), isTrue);
      expect(valid('ACTIVE', true, 'PRESENT', 'PASS'), isFalse);
      expect(valid('COMPLETE', false, 'PRESENT', 'PASS'), isFalse);
      expect(valid('COMPLETE', true, 'ABSENT', 'PASS'), isFalse);
      expect(valid('COMPLETE', true, 'PRESENT', 'FAIL'), isFalse);
      expect(valid('COMPLETE', true, 'PRESENT', 'NEEDS_REMEDIATION'), isFalse);
    });

    test('progress is member-scoped and excludes standalone training tasks', () {
      final assignments = [
        {'memberId': 'member-a', 'assignmentKind': 'TASK_BOOK', 'progress': 60, 'pendingApproval': 2},
        {'memberId': 'member-b', 'assignmentKind': 'TASK_BOOK', 'progress': 100, 'pendingApproval': 0},
        {'memberId': 'member-a', 'assignmentKind': 'TRAINING_TASK', 'progress': 100},
      ];
      final a = classMemberAssignments(assignments, 'member-a');
      expect(a, hasLength(1));
      expect(a.single['progress'], 60);
      expect(a.single['pendingApproval'], 2);
      expect(classMemberAssignments(assignments, 'guest'), isEmpty);
    });

    test('network ambiguity requires refreshing authoritative state before retry', () {
      expect(assignmentResponseMayBeAmbiguous(
        const ResponderRoadmapApiException('offline')), isTrue);
      expect(assignmentResponseMayBeAmbiguous(
        const ResponderRoadmapApiException('server error', statusCode: 503)), isTrue);
      expect(assignmentResponseMayBeAmbiguous(
        const ResponderRoadmapApiException('forbidden', statusCode: 403)), isFalse);
    });

    test('class API roster parsing keeps department membership identity', () {
      final detail = DepartmentClassDetail.fromJson({
        'id': 'class-1', 'title': 'Recruit skills', 'roster': [
          {'id': 'enrollment-a', 'membershipId': 'member-a', 'name': 'Recruit A', 'attendance': 'PRESENT'},
          {'id': 'enrollment-guest', 'name': 'Guest', 'attendance': 'PRESENT'},
        ],
      });
      expect(eligibleClassMembershipIds(detail.roster), ['member-a']);
    });
  });
}
