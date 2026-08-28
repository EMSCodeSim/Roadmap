import 'package:flutter/foundation.dart';

enum AssignmentStatus {
  notStarted,
  inProgress,
  awaitingSignOff,
  complete,
  overdue,
}

extension AssignmentStatusLabel on AssignmentStatus {
  String get label => switch (this) {
        AssignmentStatus.notStarted => 'Not Started',
        AssignmentStatus.inProgress => 'In Progress',
        AssignmentStatus.awaitingSignOff => 'Awaiting Sign-Off',
        AssignmentStatus.complete => 'Complete',
        AssignmentStatus.overdue => 'Overdue',
      };
}

enum CompletionStatus {
  notStarted,
  submitted,
  approved,
  returned,
}

extension CompletionStatusLabel on CompletionStatus {
  String get label => switch (this) {
        CompletionStatus.notStarted => 'Not Started',
        CompletionStatus.submitted => 'Submitted',
        CompletionStatus.approved => 'Approved',
        CompletionStatus.returned => 'Returned',
      };
}

enum SignOffResult { approved, returned }

extension SignOffResultLabel on SignOffResult {
  String get label => switch (this) {
        SignOffResult.approved => 'Approved',
        SignOffResult.returned => 'Returned',
      };
}

@immutable
class TaskBookAssignment {
  final String id;
  final String departmentId;
  final String taskBookVersionId;
  final String memberId;
  final String assignedBy;
  final String evaluatorId;
  final String? supervisorId;
  final DateTime assignedDate;
  final DateTime? dueDate;
  final AssignmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskBookAssignment({
    required this.id,
    required this.departmentId,
    required this.taskBookVersionId,
    required this.memberId,
    required this.assignedBy,
    required this.evaluatorId,
    required this.supervisorId,
    required this.assignedDate,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskBookAssignment copyWith({
    String? id,
    String? departmentId,
    String? taskBookVersionId,
    String? memberId,
    String? assignedBy,
    String? evaluatorId,
    String? supervisorId,
    DateTime? assignedDate,
    DateTime? dueDate,
    AssignmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskBookAssignment(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      taskBookVersionId: taskBookVersionId ?? this.taskBookVersionId,
      memberId: memberId ?? this.memberId,
      assignedBy: assignedBy ?? this.assignedBy,
      evaluatorId: evaluatorId ?? this.evaluatorId,
      supervisorId: supervisorId ?? this.supervisorId,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskBookAssignment.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    DateTime? dtOpt(String key) => (json[key] == null) ? null : DateTime.tryParse(json[key]);
    AssignmentStatus statusFrom(String? v) => AssignmentStatus.values.firstWhere(
          (e) => e.name == v,
          orElse: () => AssignmentStatus.notStarted,
        );

    return TaskBookAssignment(
      id: (json['id'] ?? '').toString(),
      departmentId: (json['departmentId'] ?? '').toString(),
      taskBookVersionId: (json['taskBookVersionId'] ?? '').toString(),
      memberId: (json['memberId'] ?? '').toString(),
      assignedBy: (json['assignedBy'] ?? '').toString(),
      evaluatorId: (json['evaluatorId'] ?? '').toString(),
      supervisorId: json['supervisorId'] as String?,
      assignedDate: dt('assignedDate'),
      dueDate: dtOpt('dueDate'),
      status: statusFrom(json['status'] as String?),
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'departmentId': departmentId,
        'taskBookVersionId': taskBookVersionId,
        'memberId': memberId,
        'assignedBy': assignedBy,
        'evaluatorId': evaluatorId,
        'supervisorId': supervisorId,
        'assignedDate': assignedDate.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

@immutable
class RequirementCompletion {
  final String id;
  final String assignmentId;
  final String requirementId;
  final String memberId;
  final CompletionStatus status;
  final String memberNotes;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RequirementCompletion({
    required this.id,
    required this.assignmentId,
    required this.requirementId,
    required this.memberId,
    required this.status,
    required this.memberNotes,
    required this.submittedAt,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  RequirementCompletion copyWith({
    String? id,
    String? assignmentId,
    String? requirementId,
    String? memberId,
    CompletionStatus? status,
    String? memberNotes,
    DateTime? submittedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RequirementCompletion(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      requirementId: requirementId ?? this.requirementId,
      memberId: memberId ?? this.memberId,
      status: status ?? this.status,
      memberNotes: memberNotes ?? this.memberNotes,
      submittedAt: submittedAt ?? this.submittedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RequirementCompletion.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    DateTime? dtOpt(String key) => (json[key] == null) ? null : DateTime.tryParse(json[key]);
    CompletionStatus statusFrom(String? v) => CompletionStatus.values.firstWhere(
          (e) => e.name == v,
          orElse: () => CompletionStatus.notStarted,
        );

    return RequirementCompletion(
      id: (json['id'] ?? '').toString(),
      assignmentId: (json['assignmentId'] ?? '').toString(),
      requirementId: (json['requirementId'] ?? '').toString(),
      memberId: (json['memberId'] ?? '').toString(),
      status: statusFrom(json['status'] as String?),
      memberNotes: (json['memberNotes'] ?? '').toString(),
      submittedAt: dtOpt('submittedAt'),
      completedAt: dtOpt('completedAt'),
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignmentId': assignmentId,
        'requirementId': requirementId,
        'memberId': memberId,
        'status': status.name,
        'memberNotes': memberNotes,
        'submittedAt': submittedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

@immutable
class Evidence {
  final String id;
  final String completionId;
  final String type;
  final String description;
  final String? fileUrl;
  final DateTime uploadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Evidence({
    required this.id,
    required this.completionId,
    required this.type,
    required this.description,
    required this.fileUrl,
    required this.uploadedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Evidence copyWith({
    String? id,
    String? completionId,
    String? type,
    String? description,
    String? fileUrl,
    DateTime? uploadedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Evidence(
      id: id ?? this.id,
      completionId: completionId ?? this.completionId,
      type: type ?? this.type,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Evidence.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return Evidence(
      id: (json['id'] ?? '').toString(),
      completionId: (json['completionId'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      fileUrl: json['fileUrl'] as String?,
      uploadedAt: dt('uploadedAt'),
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'completionId': completionId,
        'type': type,
        'description': description,
        'fileUrl': fileUrl,
        'uploadedAt': uploadedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

@immutable
class SignOff {
  final String id;
  final String completionId;
  final String evaluatorId;
  final SignOffResult result;
  final String notes;
  final DateTime signedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SignOff({
    required this.id,
    required this.completionId,
    required this.evaluatorId,
    required this.result,
    required this.notes,
    required this.signedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SignOff.fromJson(Map<String, dynamic> json) {
    DateTime dt(String key) => DateTime.tryParse(json[key] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    SignOffResult resultFrom(String? v) => SignOffResult.values.firstWhere(
          (e) => e.name == v,
          orElse: () => SignOffResult.approved,
        );

    return SignOff(
      id: (json['id'] ?? '').toString(),
      completionId: (json['completionId'] ?? '').toString(),
      evaluatorId: (json['evaluatorId'] ?? '').toString(),
      result: resultFrom(json['result'] as String?),
      notes: (json['notes'] ?? '').toString(),
      signedAt: dt('signedAt'),
      createdAt: dt('createdAt'),
      updatedAt: dt('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'completionId': completionId,
        'evaluatorId': evaluatorId,
        'result': result.name,
        'notes': notes,
        'signedAt': signedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
