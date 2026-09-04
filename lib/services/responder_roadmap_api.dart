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
    );
  }
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

  Future<DepartmentTaskBookAssignment> submitRequirement({
    required String assignmentId,
    required String requirementId,
    String memberNotes = '',
    String evidenceDescription = '',
    String? evidenceType,
  }) async {
    final data = await _request(
      'POST',
      'app/assignments/${Uri.encodeComponent(assignmentId)}/requirements/${Uri.encodeComponent(requirementId)}/submit',
      body: <String, dynamic>{
        'memberNotes': memberNotes.trim(),
        'evidenceDescription': evidenceDescription.trim(),
        if (evidenceType != null) 'evidenceType': evidenceType,
      },
    );
    return DepartmentTaskBookAssignment.fromJson(_asMap(data));
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
