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
  final bool evaluatorSignOffRequired;
  final bool supervisorApprovalRequired;
  final int repetitionsRequired;
  final List<String> prerequisites;
  final String? referenceUrl;
  final String? referenceDocument;
  final String? completionStatus;
  final int repetitionCount;
  final String memberNotes;

  const DepartmentRequirement({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.evidenceType,
    required this.evaluatorSignOffRequired,
    required this.supervisorApprovalRequired,
    required this.repetitionsRequired,
    required this.prerequisites,
    required this.referenceUrl,
    required this.referenceDocument,
    required this.completionStatus,
    required this.repetitionCount,
    required this.memberNotes,
  });

  bool get isFullyApproved =>
      completionStatus == 'APPROVED' && repetitionCount >= repetitionsRequired;

  bool get isAwaitingReview => completionStatus == 'SUBMITTED';

  bool get canSubmit => !isFullyApproved && !isAwaitingReview;

  factory DepartmentRequirement.fromJson(Map<String, dynamic> json) {
    final completionRaw = json['completion'];
    final completion = completionRaw is Map
        ? Map<String, dynamic>.from(completionRaw)
        : null;
    return DepartmentRequirement(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Requirement',
      description: (json['description'] as String?) ?? '',
      instructions: (json['instructions'] as String?) ?? '',
      evidenceType: (json['evidenceType'] as String?) ?? 'NONE',
      evaluatorSignOffRequired: json['evaluatorSignOffRequired'] != false,
      supervisorApprovalRequired: json['supervisorApprovalRequired'] == true,
      repetitionsRequired: _asInt(json['repetitionsRequired'], fallback: 1)
          .clamp(1, 999)
          .toInt(),
      prerequisites: (json['prerequisites'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      referenceUrl: json['referenceUrl'] as String?,
      referenceDocument: json['referenceDocument'] as String?,
      completionStatus: completion?['status'] as String?,
      repetitionCount: _asInt(completion?['repetitionCount']),
      memberNotes: (completion?['memberNotes'] as String?) ?? '',
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

  factory DepartmentTaskBookAssignment.fromJson(Map<String, dynamic> json) {
    return DepartmentTaskBookAssignment(
      id: (json['id'] as String?) ?? '',
      taskBookTitle: (json['taskBookTitle'] as String?) ?? 'Task Book',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'Department',
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
