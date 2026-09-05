import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ResponderRoadmapApiException implements Exception {
  final String message;
  final int? statusCode;

  const ResponderRoadmapApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ResponderRoadmapSession {
  final String userId;
  final String email;
  final String name;
  final String? departmentId;
  final String? departmentName;
  final String? membershipId;
  final String? role;
  final String? rank;

  const ResponderRoadmapSession({
    required this.userId,
    required this.email,
    required this.name,
    required this.departmentId,
    required this.departmentName,
    required this.membershipId,
    required this.role,
    required this.rank,
  });

  bool get hasDepartment =>
      departmentId != null && departmentId!.isNotEmpty &&
      membershipId != null && membershipId!.isNotEmpty;

  factory ResponderRoadmapSession.fromJson(Map<String, dynamic> json) {
    return ResponderRoadmapSession(
      userId: (json['userId'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
      membershipId: json['membershipId'] as String?,
      role: json['role'] as String?,
      rank: json['rank'] as String?,
    );
  }
}

class DepartmentJoinResult {
  final String departmentName;
  final String membershipStatus;

  const DepartmentJoinResult({
    required this.departmentName,
    required this.membershipStatus,
  });

  bool get isActive => membershipStatus == 'ACTIVE';

  factory DepartmentJoinResult.fromJson(Map<String, dynamic> json) {
    final department = Map<String, dynamic>.from(
      (json['department'] as Map?) ?? const <String, dynamic>{},
    );
    final membership = Map<String, dynamic>.from(
      (json['membership'] as Map?) ?? const <String, dynamic>{},
    );
    return DepartmentJoinResult(
      departmentName: (department['name'] as String?) ?? 'Department',
      membershipStatus: (membership['status'] as String?) ?? 'PENDING',
    );
  }
}

class DepartmentRequirement {
  final String id;
  final String title;
  final String description;
  final String instructions;
  final String evidenceType;
  final bool memberNotesAllowed;
  final bool evaluatorSignOffRequired;
  final bool supervisorApprovalRequired;
  final int repetitionsRequired;
  final List<String> prerequisites;
  final bool blockedByPrerequisites;
  final List<String> prerequisiteTitles;
  final String? reviewStage;
  final String? referenceUrl;
  final String? referenceDocument;
  final String? completionStatus;
  final int repetitionCount;
  final String memberNotes;
  final String correctionNotes;
  final String? returnedByName;
  final DateTime? returnedAt;
  final List<DepartmentEvaluationStep> evaluationSteps;

  const DepartmentRequirement({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.evidenceType,
    required this.memberNotesAllowed,
    required this.evaluatorSignOffRequired,
    required this.supervisorApprovalRequired,
    required this.repetitionsRequired,
    required this.prerequisites,
    required this.blockedByPrerequisites,
    required this.prerequisiteTitles,
    required this.reviewStage,
    required this.referenceUrl,
    required this.referenceDocument,
    required this.completionStatus,
    required this.repetitionCount,
    required this.memberNotes,
    required this.correctionNotes,
    required this.returnedByName,
    required this.returnedAt,
    required this.evaluationSteps,
  });

  bool get isFullyApproved =>
      completionStatus == 'APPROVED' && repetitionCount >= repetitionsRequired;

  bool get isAwaitingReview => completionStatus == 'SUBMITTED';

  bool get canSubmit =>
      !isFullyApproved && !isAwaitingReview && !blockedByPrerequisites;

  String get reviewLabel {
    if (reviewStage == 'SUPERVISOR') return 'Waiting for supervisor approval';
    if (reviewStage == 'EVALUATOR') return 'Waiting for evaluator review';
    if (isAwaitingReview) return 'Waiting for department review';
    return '';
  }

  factory DepartmentRequirement.fromJson(Map<String, dynamic> json) {
    final completionRaw = json['completion'];
    final completion = completionRaw is Map
        ? Map<String, dynamic>.from(completionRaw)
        : null;
    final correctionRaw = completion?['correction'];
    final correction = correctionRaw is Map
        ? Map<String, dynamic>.from(correctionRaw)
        : null;
    return DepartmentRequirement(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Requirement',
      description: (json['description'] as String?) ?? '',
      instructions: (json['instructions'] as String?) ?? '',
      evidenceType: (json['evidenceType'] as String?) ?? 'NONE',
      memberNotesAllowed: json['memberNotesAllowed'] != false,
      evaluatorSignOffRequired: json['evaluatorSignOffRequired'] != false,
      supervisorApprovalRequired: json['supervisorApprovalRequired'] == true,
      repetitionsRequired: _asInt(json['repetitionsRequired'], fallback: 1)
          .clamp(1, 999)
          .toInt(),
      prerequisites: (json['prerequisites'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      blockedByPrerequisites: json['blockedByPrerequisites'] == true,
      prerequisiteTitles: (json['prerequisiteTitles'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      reviewStage: json['reviewStage'] as String?,
      referenceUrl: json['referenceUrl'] as String?,
      referenceDocument: json['referenceDocument'] as String?,
      completionStatus: completion?['status'] as String?,
      repetitionCount: _asInt(completion?['repetitionCount']),
      memberNotes: (completion?['memberNotes'] as String?) ?? '',
      correctionNotes: (correction?['notes'] as String?) ?? '',
      returnedByName: correction?['returnedByName'] as String?,
      returnedAt: DateTime.tryParse((correction?['returnedAt'] as String?) ?? ''),
      evaluationSteps: (json['evaluationSteps'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => DepartmentEvaluationStep.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id.isNotEmpty && item.text.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class DepartmentEvaluator {
  final String id;
  final String name;
  final String role;

  const DepartmentEvaluator({required this.id, required this.name, required this.role});

  factory DepartmentEvaluator.fromJson(Map<String, dynamic> json) => DepartmentEvaluator(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? 'Evaluator',
        role: (json['role'] as String?) ?? 'EVALUATOR',
      );
}

class DepartmentTaskSection {
  final String id;
  final String title;
  final String description;
  final List<DepartmentRequirement> requirements;

  const DepartmentTaskSection({
    required this.id,
    required this.title,
    required this.description,
    required this.requirements,
  });

  factory DepartmentTaskSection.fromJson(Map<String, dynamic> json) {
    return DepartmentTaskSection(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Section',
      description: (json['description'] as String?) ?? '',
      requirements: (json['requirements'] as List?)
              ?.whereType<Map>()
              .map((item) => DepartmentRequirement.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false) ??
          const <DepartmentRequirement>[],
    );
  }
}

class DepartmentTaskBookAssignment {
  final String id;
  final String taskBookTitle;
  final String description;
  final String category;
  final String assignmentKind;
  final String version;
  final String status;
  final int progress;
  final int complete;
  final int totalRequired;
  final int pendingApproval;
  final int overdue;
  final DateTime? assignedDate;
  final DateTime? dueDate;
  final String? evaluatorName;
  final String? supervisorName;
  final String notes;
  final List<DepartmentTaskSection> sections;

  const DepartmentTaskBookAssignment({
    required this.id,
    required this.taskBookTitle,
    required this.description,
    required this.category,
    required this.assignmentKind,
    required this.version,
    required this.status,
    required this.progress,
    required this.complete,
    required this.totalRequired,
    required this.pendingApproval,
    required this.overdue,
    required this.assignedDate,
    required this.dueDate,
    required this.evaluatorName,
    required this.supervisorName,
    required this.notes,
    required this.sections,
  });

  bool get isSingleTask => assignmentKind == 'TRAINING_TASK';

  factory DepartmentTaskBookAssignment.fromJson(Map<String, dynamic> json) {
    return DepartmentTaskBookAssignment(
      id: (json['id'] as String?) ?? '',
      taskBookTitle: (json['taskBookTitle'] as String?) ?? 'Task Book',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'Department',
      assignmentKind: (json['assignmentKind'] as String?) ?? 'TASK_BOOK',
      version: (json['version'] as String?) ?? '1.0',
      status: (json['status'] as String?) ?? 'NOT_STARTED',
      progress: _asInt(json['progress']),
      complete: _asInt(json['complete']),
      totalRequired: _asInt(json['totalRequired']),
      pendingApproval: _asInt(json['pendingApproval']),
      overdue: _asInt(json['overdue']),
      assignedDate: DateTime.tryParse((json['assignedDate'] as String?) ?? ''),
      dueDate: DateTime.tryParse((json['dueDate'] as String?) ?? ''),
      evaluatorName: json['evaluatorName'] as String?,
      supervisorName: json['supervisorName'] as String?,
      notes: (json['notes'] as String?) ?? '',
      sections: (json['sections'] as List?)
              ?.whereType<Map>()
              .map((item) => DepartmentTaskSection.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false) ??
          const <DepartmentTaskSection>[],
    );
  }
}

class DepartmentInboxItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? referenceId;
  final String? actionPath;
  final DateTime? createdAt;
  final DateTime? readAt;
  final String pushStatus;

  const DepartmentInboxItem({required this.id, required this.type, required this.title, required this.body, required this.referenceId, required this.actionPath, required this.createdAt, required this.readAt, required this.pushStatus});

  factory DepartmentInboxItem.fromJson(Map<String, dynamic> json) => DepartmentInboxItem(
        id: (json['id'] as String?) ?? '',
        type: (json['type'] as String?) ?? '',
        title: (json['title'] as String?) ?? 'Assignment update',
        body: (json['body'] as String?) ?? '',
        referenceId: json['referenceId'] as String?,
        actionPath: json['actionPath'] as String?,
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
        readAt: DateTime.tryParse((json['readAt'] as String?) ?? ''),
        pushStatus: (json['pushStatus'] as String?) ?? 'PENDING',
      );
}

class DepartmentActionItem {
  final String id;
  final String kind;
  final String title;
  final String subtitle;
  final DateTime? submittedAt;
  final String? actionPath;

  const DepartmentActionItem({required this.id, required this.kind, required this.title, required this.subtitle, required this.submittedAt, required this.actionPath});

  factory DepartmentActionItem.fromJson(Map<String, dynamic> json) => DepartmentActionItem(
        id: (json['id'] as String?) ?? '',
        kind: (json['kind'] as String?) ?? '',
        title: (json['title'] as String?) ?? 'Assignment action',
        subtitle: (json['subtitle'] as String?) ?? '',
        submittedAt: DateTime.tryParse((json['submittedAt'] as String?) ?? ''),
        actionPath: json['actionPath'] as String?,
      );
}

class DepartmentInbox {
  final int unreadCount;
  final DateTime? serverTime;
  final List<DepartmentInboxItem> items;
  final List<DepartmentActionItem> needsAction;

  const DepartmentInbox({required this.unreadCount, required this.serverTime, required this.items, required this.needsAction});

  factory DepartmentInbox.fromJson(Map<String, dynamic> json) => DepartmentInbox(
        unreadCount: _asInt(json['unreadCount']),
        serverTime: DateTime.tryParse((json['serverTime'] as String?) ?? ''),
        items: (json['items'] as List? ?? const []).whereType<Map>().map((item) => DepartmentInboxItem.fromJson(Map<String, dynamic>.from(item))).toList(growable: false),
        needsAction: (json['needsAction'] as List? ?? const []).whereType<Map>().map((item) => DepartmentActionItem.fromJson(Map<String, dynamic>.from(item))).toList(growable: false),
      );
}

class DepartmentCertificationSharing {
  final Set<String> sharedSourceIds;
  final DateTime? serverTime;

  const DepartmentCertificationSharing({
    required this.sharedSourceIds,
    required this.serverTime,
  });

  factory DepartmentCertificationSharing.fromJson(Map<String, dynamic> json) {
    return DepartmentCertificationSharing(
      sharedSourceIds: (json['sharedSourceIds'] as List? ?? const [])
          .whereType<String>()
          .toSet(),
      serverTime: DateTime.tryParse((json['serverTime'] as String?) ?? ''),
    );
  }
}

class DepartmentSubmissionReceipt {
  final String receiptId;
  final String? clientRequestId;
  final String status;
  final DateTime? recordedAt;
  final String recordedByName;

  const DepartmentSubmissionReceipt({required this.receiptId, required this.clientRequestId, required this.status, required this.recordedAt, required this.recordedByName});

  factory DepartmentSubmissionReceipt.fromJson(Map<String, dynamic> json) => DepartmentSubmissionReceipt(
        receiptId: (json['receiptId'] as String?) ?? '',
        clientRequestId: json['clientRequestId'] as String?,
        status: (json['status'] as String?) ?? 'SUBMITTED',
        recordedAt: DateTime.tryParse((json['recordedAt'] as String?) ?? ''),
        recordedByName: (json['recordedByName'] as String?) ?? '',
      );
}

class DepartmentSubmissionResult {
  final DepartmentTaskBookAssignment assignment;
  final DepartmentSubmissionReceipt receipt;

  const DepartmentSubmissionResult({required this.assignment, required this.receipt});
}

class DepartmentEvaluationStep {
  final String id;
  final String text;

  const DepartmentEvaluationStep({required this.id, required this.text});

  factory DepartmentEvaluationStep.fromJson(Map<String, dynamic> json) {
    return DepartmentEvaluationStep(
      id: (json['id'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
    );
  }
}

class DepartmentReviewItem {
  final String id;
  final String memberName;
  final String taskBookTitle;
  final String sectionTitle;
  final String requirementTitle;
  final String requirementDescription;
  final String instructions;
  final String memberNotes;
  final String reviewStage;
  final DateTime? submittedAt;
  final int approvedRepetitions;
  final int repetitionsRequired;
  final List<DepartmentEvaluationStep> evaluationSteps;
  final List<DepartmentEvaluationStep> criticalFailures;

  const DepartmentReviewItem({
    required this.id,
    required this.memberName,
    required this.taskBookTitle,
    required this.sectionTitle,
    required this.requirementTitle,
    required this.requirementDescription,
    required this.instructions,
    required this.memberNotes,
    required this.reviewStage,
    required this.submittedAt,
    required this.approvedRepetitions,
    required this.repetitionsRequired,
    required this.evaluationSteps,
    required this.criticalFailures,
  });

  factory DepartmentReviewItem.fromJson(Map<String, dynamic> json) {
    List<DepartmentEvaluationStep> steps(Object? raw) => raw is List
        ? raw
            .whereType<Map>()
            .map((item) => DepartmentEvaluationStep.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .where((item) => item.id.isNotEmpty && item.text.isNotEmpty)
            .toList(growable: false)
        : const <DepartmentEvaluationStep>[];

    return DepartmentReviewItem(
      id: (json['id'] as String?) ?? '',
      memberName: (json['memberName'] as String?) ?? 'Member',
      taskBookTitle: (json['taskBookTitle'] as String?) ?? 'Task Book',
      sectionTitle: (json['sectionTitle'] as String?) ?? '',
      requirementTitle: (json['requirementTitle'] as String?) ?? 'Requirement',
      requirementDescription: (json['requirementDescription'] as String?) ?? '',
      instructions: (json['instructions'] as String?) ?? '',
      memberNotes: (json['memberNotes'] as String?) ?? '',
      reviewStage: (json['reviewStage'] as String?) ?? 'EVALUATOR',
      submittedAt: DateTime.tryParse((json['submittedAt'] as String?) ?? ''),
      approvedRepetitions: _asInt(json['approvedRepetitions']),
      repetitionsRequired: _asInt(json['repetitionsRequired'], fallback: 1),
      evaluationSteps: steps(json['evaluationSteps']),
      criticalFailures: steps(json['criticalFailures']),
    );
  }
}

class DepartmentClassSummary {
  final String id;
  final String title;
  final String classType;
  final String checklistTitle;
  final String status;
  final DateTime? startsAt;
  final String location;
  final int rosterCount;
  final int completeCount;

  const DepartmentClassSummary({required this.id, required this.title, required this.classType, required this.checklistTitle, required this.status, required this.startsAt, required this.location, required this.rosterCount, required this.completeCount});

  factory DepartmentClassSummary.fromJson(Map<String, dynamic> json) => DepartmentClassSummary(
        id: (json['id'] as String?) ?? '',
        title: (json['title'] as String?) ?? 'Class',
        classType: (json['classType'] as String?) ?? 'GENERAL',
        checklistTitle: (json['checklistTitle'] as String?) ?? 'Checklist',
        status: (json['status'] as String?) ?? 'DRAFT',
        startsAt: DateTime.tryParse((json['startsAt'] as String?) ?? ''),
        location: (json['location'] as String?) ?? '',
        rosterCount: _asInt(json['rosterCount']),
        completeCount: _asInt(json['completeCount']),
      );
}

class DepartmentClassSkill {
  final String id;
  final String title;
  final String description;
  final bool required;
  const DepartmentClassSkill({required this.id, required this.title, required this.description, required this.required});
  factory DepartmentClassSkill.fromJson(Map<String, dynamic> json) => DepartmentClassSkill(id: (json['id'] as String?) ?? '', title: (json['title'] as String?) ?? 'Skill', description: (json['description'] as String?) ?? '', required: json['required'] != false);
}

class DepartmentClassSection {
  final String id;
  final String title;
  final List<DepartmentClassSkill> skills;
  const DepartmentClassSection({required this.id, required this.title, required this.skills});
  factory DepartmentClassSection.fromJson(Map<String, dynamic> json) => DepartmentClassSection(
        id: (json['id'] as String?) ?? '',
        title: (json['title'] as String?) ?? 'Skills',
        skills: (json['skills'] as List? ?? const []).whereType<Map>().map((item) => DepartmentClassSkill.fromJson(Map<String, dynamic>.from(item))).toList(growable: false),
      );
}

class DepartmentClassSkillResult {
  final String requirementId;
  final String result;
  final String notes;
  final String evaluatorName;
  final DateTime? evaluatedAt;
  const DepartmentClassSkillResult({required this.requirementId, required this.result, required this.notes, required this.evaluatorName, required this.evaluatedAt});
  factory DepartmentClassSkillResult.fromJson(Map<String, dynamic> json) => DepartmentClassSkillResult(requirementId: (json['requirementId'] as String?) ?? '', result: (json['result'] as String?) ?? 'NOT_EVALUATED', notes: (json['notes'] as String?) ?? '', evaluatorName: (json['evaluatorName'] as String?) ?? '', evaluatedAt: DateTime.tryParse((json['evaluatedAt'] as String?) ?? ''));
}

class DepartmentClassStudent {
  final String id;
  final String name;
  final String email;
  final String attendance;
  final double? writtenScore;
  final double? ccfScore;
  final String finalResult;
  final List<DepartmentClassSkillResult> results;
  const DepartmentClassStudent({required this.id, required this.name, required this.email, required this.attendance, required this.writtenScore, required this.ccfScore, required this.finalResult, required this.results});
  factory DepartmentClassStudent.fromJson(Map<String, dynamic> json) => DepartmentClassStudent(
        id: (json['id'] as String?) ?? '', name: (json['name'] as String?) ?? 'Student', email: (json['email'] as String?) ?? '', attendance: (json['attendance'] as String?) ?? 'REGISTERED',
        writtenScore: (json['writtenScore'] as num?)?.toDouble(), ccfScore: (json['ccfScore'] as num?)?.toDouble(), finalResult: (json['finalResult'] as String?) ?? 'PENDING',
        results: (json['results'] as List? ?? const []).whereType<Map>().map((item) => DepartmentClassSkillResult.fromJson(Map<String, dynamic>.from(item))).toList(growable: false),
      );
}

class DepartmentClassDetail {
  final String id;
  final String title;
  final String classType;
  final String checklistTitle;
  final String status;
  final List<DepartmentClassSection> sections;
  final List<DepartmentClassStudent> roster;
  const DepartmentClassDetail({required this.id, required this.title, required this.classType, required this.checklistTitle, required this.status, required this.sections, required this.roster});
  factory DepartmentClassDetail.fromJson(Map<String, dynamic> json) => DepartmentClassDetail(
        id: (json['id'] as String?) ?? '', title: (json['title'] as String?) ?? 'Class', classType: (json['classType'] as String?) ?? 'GENERAL', checklistTitle: (json['checklistTitle'] as String?) ?? 'Checklist', status: (json['status'] as String?) ?? 'DRAFT',
        sections: (json['sections'] as List? ?? const []).whereType<Map>().map((item) => DepartmentClassSection.fromJson(Map<String, dynamic>.from(item))).toList(growable: false),
        roster: (json['roster'] as List? ?? const []).whereType<Map>().map((item) => DepartmentClassStudent.fromJson(Map<String, dynamic>.from(item))).toList(growable: false),
      );
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

class ResponderRoadmapApi {
  ResponderRoadmapApi({
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String baseUrl = 'https://responderroadmap.com/api/v1';
  static const String dashboardUrl = 'https://responderroadmap.com/';
  static const String _tokenKey = 'fireops.responderRoadmap.token.v1';
  static const String _pendingSubmissionsKey = 'fireops.responderRoadmap.pendingSubmissions.v1';

  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  Future<bool> get hasStoredToken async =>
      ((await _secureStorage.read(key: _tokenKey)) ?? '').isNotEmpty;

  Future<ResponderRoadmapSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      'auth/app-login',
      body: <String, dynamic>{'email': email.trim(), 'password': password},
      authenticated: false,
    );
    final map = _asMap(data);
    final token = (map['token'] as String?)?.trim() ?? '';
    if (token.isEmpty) {
      throw const ResponderRoadmapApiException(
        'ResponderRoadmap did not return an app session token.',
      );
    }
    await _secureStorage.write(key: _tokenKey, value: token);
    return ResponderRoadmapSession.fromJson(_asMap(map['session']));
  }

  Future<ResponderRoadmapSession> currentSession() async {
    final data = await _request('GET', 'auth/me');
    return ResponderRoadmapSession.fromJson(_asMap(data));
  }

  Future<DepartmentJoinResult> joinDepartment(String joinCode) async {
    final data = await _request(
      'POST',
      'join',
      body: <String, dynamic>{'joinCode': joinCode.trim().toUpperCase()},
    );
    return DepartmentJoinResult.fromJson(_asMap(data));
  }

  Future<List<DepartmentTaskBookAssignment>> listAssignments() async {
    final data = await _request('GET', 'app/assignments');
    final list = data is List ? data : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => DepartmentTaskBookAssignment.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<DepartmentTaskBookAssignment> getAssignment(String assignmentId) async {
    final data = await _request(
      'GET',
      'app/assignments/${Uri.encodeComponent(assignmentId)}',
    );
    return DepartmentTaskBookAssignment.fromJson(_asMap(data));
  }

  Future<DepartmentSubmissionResult> submitRequirement({
    required String assignmentId,
    required String requirementId,
    String memberNotes = '',
    String evidenceDescription = '',
    String? evidenceType,
    String? clientRequestId,
    String? evaluatorId,
    List<String> checkedStepIds = const [],
    bool memberAttested = false,
  }) async {
    final requestId = clientRequestId ?? 'submission-${DateTime.now().microsecondsSinceEpoch}';
    final pending = <String, dynamic>{
      'clientRequestId': requestId,
      'assignmentId': assignmentId,
      'requirementId': requirementId,
      'memberNotes': memberNotes,
      'evidenceDescription': evidenceDescription,
      if (evidenceType != null) 'evidenceType': evidenceType,
      if (evaluatorId != null) 'evaluatorId': evaluatorId,
      'checkedStepIds': checkedStepIds,
      'memberAttested': memberAttested,
    };
    await _savePendingSubmission(pending);
    dynamic data;
    try {
      data = await _request(
        'POST',
        'app/assignments/${Uri.encodeComponent(assignmentId)}/requirements/${Uri.encodeComponent(requirementId)}/submit',
        body: <String, dynamic>{
          'memberNotes': memberNotes.trim(),
          'evidenceDescription': evidenceDescription.trim(),
          if (evidenceType != null) 'evidenceType': evidenceType,
          'clientRequestId': requestId,
          if (evaluatorId != null) 'evaluatorId': evaluatorId,
          'checkedStepIds': checkedStepIds,
          'memberAttested': memberAttested,
        },
      );
    } on ResponderRoadmapApiException catch (error) {
      if (error.statusCode != null && error.statusCode! >= 400 && error.statusCode! < 500 && error.statusCode != 408) {
        await _removePendingSubmission(requestId);
      }
      rethrow;
    }
    await _removePendingSubmission(requestId);
    final map = _asMap(data);
    return DepartmentSubmissionResult(
      assignment: DepartmentTaskBookAssignment.fromJson(_asMap(map['assignment'])),
      receipt: DepartmentSubmissionReceipt.fromJson(_asMap(map['receipt'])),
    );
  }

  Future<List<DepartmentSubmissionResult>> retryPendingSubmissions() async {
    final raw = await _secureStorage.read(key: _pendingSubmissionsKey);
    dynamic decoded;
    try {
      decoded = raw == null ? const <dynamic>[] : jsonDecode(raw);
    } catch (_) {
      decoded = const <dynamic>[];
    }
    final rows = decoded is List ? decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : <Map<String, dynamic>>[];
    final completed = <DepartmentSubmissionResult>[];
    for (final row in rows) {
      try {
        completed.add(await submitRequirement(
          assignmentId: (row['assignmentId'] as String?) ?? '',
          requirementId: (row['requirementId'] as String?) ?? '',
          memberNotes: (row['memberNotes'] as String?) ?? '',
          evidenceDescription: (row['evidenceDescription'] as String?) ?? '',
          evidenceType: row['evidenceType'] as String?,
          clientRequestId: row['clientRequestId'] as String?,
          evaluatorId: row['evaluatorId'] as String?,
          checkedStepIds: (row['checkedStepIds'] as List? ?? const []).whereType<String>().toList(growable: false),
          memberAttested: row['memberAttested'] == true,
        ));
      } on ResponderRoadmapApiException {
        // Leave the durable queue intact for the next automatic retry.
      }
    }
    return completed;
  }

  Future<int> pendingSubmissionCount() async {
    final raw = await _secureStorage.read(key: _pendingSubmissionsKey);
    if (raw == null) return 0;
    try { final value = jsonDecode(raw); return value is List ? value.length : 0; } catch (_) { return 0; }
  }

  Future<void> _savePendingSubmission(Map<String, dynamic> submission) async {
    final raw = await _secureStorage.read(key: _pendingSubmissionsKey);
    List<dynamic> rows;
    try { final value = raw == null ? null : jsonDecode(raw); rows = value is List ? value : <dynamic>[]; } catch (_) { rows = <dynamic>[]; }
    rows.removeWhere((item) => item is Map && item['clientRequestId'] == submission['clientRequestId']);
    rows.add(submission);
    await _secureStorage.write(key: _pendingSubmissionsKey, value: jsonEncode(rows));
  }

  Future<void> _removePendingSubmission(String requestId) async {
    final raw = await _secureStorage.read(key: _pendingSubmissionsKey);
    if (raw == null) return;
    try {
      final value = jsonDecode(raw);
      if (value is! List) return;
      value.removeWhere((item) => item is Map && item['clientRequestId'] == requestId);
      await _secureStorage.write(key: _pendingSubmissionsKey, value: jsonEncode(value));
    } catch (_) {}
  }

  Future<DepartmentInbox> getInbox() async => DepartmentInbox.fromJson(_asMap(await _request('GET', 'app/inbox')));

  Future<List<DepartmentEvaluator>> listEvaluators() async {
    final data = await _request('GET', 'app/evaluators');
    return (data is List ? data : const <dynamic>[])
        .whereType<Map>()
        .map((item) => DepartmentEvaluator.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<DepartmentCertificationSharing> getCertificationSharing() async {
    final data = await _request('GET', 'app/certifications/sharing');
    return DepartmentCertificationSharing.fromJson(_asMap(data));
  }

  Future<DepartmentCertificationSharing> syncCertificationSharing(
    List<Map<String, dynamic>> certifications,
  ) async {
    final data = await _request(
      'POST',
      'app/certifications/sharing',
      body: <String, dynamic>{'certifications': certifications},
    );
    return DepartmentCertificationSharing.fromJson(_asMap(data));
  }

  Future<void> markInboxRead(String id) async {
    await _request('POST', 'app/inbox/${Uri.encodeComponent(id)}/read');
  }

  Future<void> markAllInboxRead() async {
    await _request('POST', 'app/inbox/read-all');
  }

  Future<void> registerPushDevice({required String token, required String platform}) async {
    await _request('POST', 'app/push-devices', body: {'token': token, 'platform': platform});
  }

  Future<void> unregisterPushDevice(String token) async {
    await _request('POST', 'app/push-devices/unregister', body: {'token': token});
  }

  Future<List<DepartmentReviewItem>> listReviewQueue() async {
    final data = await _request('GET', 'sign-offs');
    final list = data is List ? data : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => DepartmentReviewItem.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<List<DepartmentClassSummary>> listClasses() async {
    final data = await _request('GET', 'classes');
    return (data is List ? data : const <dynamic>[]).whereType<Map>().map((item) => DepartmentClassSummary.fromJson(Map<String, dynamic>.from(item))).toList(growable: false);
  }

  Future<DepartmentClassDetail> getClass(String classId) async {
    final data = await _request('GET', 'classes/${Uri.encodeComponent(classId)}');
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  Future<DepartmentClassDetail> recordClassSkill({required String classId, required String enrollmentId, required String requirementId, required String result, String notes = ''}) async {
    final data = await _request('POST', 'classes/${Uri.encodeComponent(classId)}/roster/${Uri.encodeComponent(enrollmentId)}/skills/${Uri.encodeComponent(requirementId)}', body: {'result': result, 'notes': notes.trim()});
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  Future<DepartmentClassDetail> updateClassStudent({required String classId, required String enrollmentId, required String attendance}) async {
    final data = await _request('POST', 'classes/${Uri.encodeComponent(classId)}/roster/${Uri.encodeComponent(enrollmentId)}', body: {'attendance': attendance});
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  Future<void> reviewSignOff({
    required String completionId,
    required String result,
    required String notes,
    required bool attested,
    List<Map<String, String>> stepResults = const [],
    List<String> criticalFailuresTriggered = const [],
  }) async {
    await _request(
      'POST',
      'sign-offs/${Uri.encodeComponent(completionId)}',
      body: <String, dynamic>{
        'result': result,
        'notes': notes.trim(),
        'attested': attested,
        'stepResults': stepResults,
        'criticalFailuresTriggered': criticalFailuresTriggered,
      },
    );
  }

  Future<void> disconnect() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl/$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = (await _secureStorage.read(key: _tokenKey))?.trim() ?? '';
      if (token.isEmpty) {
        throw const ResponderRoadmapApiException(
          'Connect your ResponderRoadmap account first.',
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          );
          break;
        default:
          throw ResponderRoadmapApiException('Unsupported request method: $method');
      }
    } catch (error) {
      if (error is ResponderRoadmapApiException) rethrow;
      throw const ResponderRoadmapApiException(
        'Could not reach ResponderRoadmap. Check your connection and try again.',
      );
    }

    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage = decoded is Map ? (decoded['error'] as String?) : null;
      if (response.statusCode == 401) {
        await _secureStorage.delete(key: _tokenKey);
      }
      throw ResponderRoadmapApiException(
        errorMessage?.trim().isNotEmpty == true
            ? errorMessage!
            : 'ResponderRoadmap request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
