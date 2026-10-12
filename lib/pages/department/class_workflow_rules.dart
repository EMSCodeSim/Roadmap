import 'package:firepath/services/responder_roadmap_api.dart';

/// Only active department-linked roster members may receive Task Books.
List<String> eligibleClassMembershipIds(
  Iterable<DepartmentClassStudent> roster, {
  bool presentOnly = false,
}) {
  return roster
      .where((member) => !presentOnly || member.attendance == 'PRESENT')
      .map((member) => member.membershipId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

/// A failed or missing class skill must never become a passing result.
bool hasApprovedPassingClassEvidence({
  required String classStatus,
  required bool instructorApproved,
  required String attendance,
  required String skillResult,
}) =>
    classStatus == 'COMPLETE' &&
    instructorApproved &&
    attendance == 'PRESENT' &&
    skillResult == 'PASS';

List<Map<String, dynamic>> classMemberAssignments(
  List<Map<String, dynamic>> assignments,
  String membershipId,
) =>
    assignments
        .where((row) => row['memberId'] == membershipId && row['assignmentKind'] != 'TRAINING_TASK')
        .toList(growable: false);

/// A network timeout after POST is ambiguous: the server may have committed.
/// Refresh authoritative assignments before offering a new submission.
bool assignmentResponseMayBeAmbiguous(ResponderRoadmapApiException error) =>
    error.statusCode == null || error.statusCode! >= 500;
