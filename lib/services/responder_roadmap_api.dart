Warning: truncated output (original token count: 21278)
Total output lines: 2116

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
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

class DepartmentCodeValidation {
  final String departmentName;
  final String joinCode;

  const DepartmentCodeValidation({required this.departmentName, required this.joinCode});

  factory DepartmentCodeValidation.fromJson(Map<String, dynamic> json) {
    return DepartmentCodeValidation(
      departmentName: (json['departmentName'] as String?) ?? 'Department',
      joinCode: (json['joinCode'] as String?) ?? '',
    );
  }
}

class DepartmentRegistrationResult {
  final String departmentName;
  final bool approvalPending;

  const DepartmentRegistrationResult({required this.departmentName, required this.approvalPending});

  factory DepartmentRegistrationResult.fromJson(Map<String, dynamic> json) {
    return DepartmentRegistrationResult(
      departmentName: (json['departmentName'] as String?) ?? 'Department',
      approvalPending: json['approvalPending'] == true,
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

class DepartmentWorkQueueItem {
  final String id;
  final String kind;
  final String priority;
  final String title;
  final String reason;
  final String owner;
  final String actionLabel;
  final String href;
  final String targetId;
  final DateTime? dueAt;

  const DepartmentWorkQueueItem({required this.id, required this.kind, required this.priority, required this.title, required this.reason, required this.owner, required this.actionLabel, required this.href, required this.targetId, required this.dueAt});

  factory DepartmentWorkQueueItem.fromJson(Map<String, dynamic> json) => DepartmentWorkQueueItem(
    id: (json['id'] as String?) ?? '',
    kind: (json['kind'] as String?) ?? 'ASSIGNMENT',
    priority: (json['priority'] as String?) ?? 'NORMAL',
    title: (json['title'] as String?) ?? 'Department action',
    reason: (json['reason'] as String?) ?? '',
    owner: (json['owner'] as String?) ?? 'You',
    actionLabel: (json['actionLabel'] as String?) ?? 'Open',
    href: (json['href'] as String?) ?? '',
    targetId: (json['targetId'] as String?) ?? '',
    dueAt: DateTime.tryParse((json['dueAt'] as String?) ?? ''),
  );
}

class DepartmentWorkQueue {
  final List<DepartmentWorkQueueItem> items;
  final int count;
  final DateTime? serverTime;
  const DepartmentWorkQueue({required this.items, required this.count, required this.serverTime});
  factory DepartmentWorkQueue.fromJson(Map<String, dynamic> json) => DepartmentWorkQueue(
    items: (json['items'] as List? ?? const <dynamic>[]).whereType<Map>().map((item) => DepartmentWorkQueueItem.fromJson(Map<String, dynamic>.from(item))).toList(growable: false),
    count: _asInt(json['count']),
    serverTime: DateTime.tryParse((json['serverTime'] as String?) ?? ''),
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
  final int waitingHours;
  final int escalationHours;
  final bool escalated;
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
    required this.waitingHours,
    required this.escalationHours,
    required this.escalated,
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
      waitingHours: _asInt(json['waitingHours']),
      escalationHours: _asInt(json['escalationHours'], fallback: 48),
      escalated: json['escalated'] == true,
      approvedRepetitions: _asInt(json['approvedRepetitions']),
      repetitionsRequired: _asInt(json['repetitionsRequired'], fallback: 1),
      evaluationSteps: steps(json['evaluationSteps']),
      criticalFailures: steps(json['criticalFailures']),
    );
  }
}

class DepartmentQualificationRole {
  final String id;
  final String name;
  final String category;
  final String description;
  final String status;
  final bool requirementsMet;
  final List<String> missingCredentialTypeIds;
  final List<String> missingTaskBookTemplateIds;
  final List<String> missingRequirementIds;
  final String restriction;
  final String note;
  final DateTime? approvedAt;
  final DateTime? reviewDate;

  const DepartmentQualificationRole({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.status,
    required this.requirementsMet,
    required this.missingCredentialTypeIds,
    required this.missingTaskBookTemplateIds,
    required this.missingRequirementIds,
    required this.restriction,
    required this.note,
    required this.approvedAt,
    required this.reviewDate,
  });

  factory DepartmentQualificationRole.fromJson(Map<String, dynamic> json) {
    final missing = json['missing'] is Map
        ? Map<String, dynamic>.from(json['missing'] as Map)
        : const <String, dynamic>{};
    final authorization = json['authorization'] is Map
        ? Map<String, dynamic>.from(json['authorization'] as Map)
        : const <String, dynamic>{};
    List<String> ids(Object? raw) => (raw as List? ?? const <dynamic>[])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return DepartmentQualificationRole(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Qualification',
      category: (json['category'] as String?) ?? 'OPERATIONS',
      description: (json['description'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'NOT_STARTED',
      requirementsMet: json['requirementsMet'] == true,
      missingCredentialTypeIds: ids(missing['credentialTypeIds']),
      missingTaskBookTemplateIds: ids(missing['taskBookTemplateIds']),
      missingRequirementIds: ids(missing['requirementIds']),
      restriction: (authorization['restriction'] as String?) ?? '',
      note: (authorization['note'] as String?) ?? '',
      approvedAt:
          DateTime.tryParse((authorization['approvedAt'] as String?) ?? ''),
      reviewDate:
          DateTime.tryParse((authorization['reviewDate'] as String?) ?? ''),
    );
  }

  int get missingCount =>
      missingCredentialTypeIds.length +
      missingTaskBookTemplateIds.length +
      missingRequirementIds.length;
}

class DepartmentQualificationMember {
  final String membershipId;
  final String name;
  final String rank;
  final String position;
  final List<DepartmentQualificationRole> qualifications;

  const DepartmentQualificationMember({
    required this.membershipId,
    required this.name,
    required this.rank,
    required this.position,
    required this.qualifications,
  });

  factory DepartmentQualificationMember.fromJson(Map<String, dynamic> json) =>
      DepartmentQualificationMember(
        membershipId: (json['membershipId'] as String?) ?? '',
        name: (json['name'] as String?) ?? 'Member',
        rank: (json['rank'] as String?) ?? '',
        position: (json['position'] as String?) ?? '',
        qualifications: (json['qualifications'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => DepartmentQualificationRole.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false),
      );
}

class DepartmentServerCredential {
  final String id;
  final String source;
  final String sourceExternalId;
  final String credentialName;
  final DateTime? expirationDate;
  final bool doesNotExpire;
  final String verificationStatus;
  final String health;
  final String window;

  const DepartmentServerCredential({
    required this.id,
    required this.source,
    required this.sourceExternalId,
    required this.credentialName,
    required this.expirationDate,
    required this.doesNotExpire,
    required this.verificationStatus,
    required this.health,
    required this.window,
  });

  factory DepartmentServerCredential.fromJson(Map<String, dynamic> json) =>
      DepartmentServerCredential(
        id: (json['id'] as String?) ?? '',
        source: (json['source'] as String?) ?? '',
        sourceExternalId: (json['sourceExternalId'] as String?) ?? '',
        credentialName: (json['credentialName'] as String?) ?? 'Credential',
        expirationDate:
            DateTime.tryParse((json['expirationDate'] as String?) ?? ''),
        doesNotExpire: json['doesNotExpire'] == true,
        verificationStatus:
            (json['verificationStatus'] as String?) ?? 'UNVERIFIED',
        health: (json['health'] as String?) ?? 'missing',
        window: (json['window'] as String?) ?? 'missing',
      );
}

class DepartmentTrainingSheetTemplate {
  final String topic;
  final List<Map<String, dynamic>> ceCredits;
  final Map<String, dynamic> gradingConfig;
  final List<Map<String, dynamic>> customFields;
  final String id;
  final String name;
  final String defaultTitle;
  final String classType;
  final String trainingCategory;
  final double creditHours;
  final String checklistVersionId;
  final String location;
  final String notes;
  final List<String> requiredFields;
  final bool selfRegistration;
  final List<String> proctorUserIds;
  final bool archived;

  const DepartmentTrainingSheetTemplate({
    required this.topic,
    required this.ceCredits,
    required this.gradingConfig,
    required this.customFields,
    required this.id, required this.name, required this.defaultTitle,
    required this.classType, required this.trainingCategory, required this.creditHours,
    required this.checklistVersionId, required this.location, required this.notes,
    required this.requiredFields, required this.selfRegistration,
    required this.proctorUserIds, required this.archived,
  });

  factory DepartmentTrainingSheetTemplate.fromJson(Map<String, dynamic> json) =>
      DepartmentTrainingSheetTemplate(
        topic: (json['topic'] as String?) ?? (json['trainingCategory'] as String?) ?? 'OTHER',
        ceCredits: (json['ceCredits'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false),
        gradingConfig: Map<String, dynamic>.from(json['gradingConfig'] as Map? ?? const {}),
        customFields: (json['customFields'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false),
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? 'Template',
        defaultTitle: (json['defaultTitle'] as String?) ?? '',
        classType: (json['classType'] as String?) ?? 'GENERAL',
        trainingCategory: (json['trainingCategory'] as String?) ?? 'COMPANY',
        creditHours: (json['creditHours'] as num?)?.toDouble() ?? 0,
        checklistVersionId: (json['checklistVersionId'] as String?) ?? '',
        location: (json['location'] as String?) ?? '',
        notes: (json['notes'] as String?) ?? '',
        requiredFields: (json['requiredFields'] as List? ?? const []).map((v)=>v.toString()).toList(growable:false),
        selfRegistration: json['selfRegistration'] == true,
        proctorUserIds: (json['proctorUserIds'] as List? ?? const []).map((v)=>v.toString()).toList(growable:false),
        archived: json['archived'] == true,
      );
}

class DepartmentClassMutationResult {
  final DepartmentClassDetail? detail;
  final bool queued;
  const DepartmentClassMutationResult({required this.detail, required this.queued});
}

class DepartmentConfiguration {
  final String agencyType;
  final List<String> operationalCapabilities;
  final List<String> customCapabilities;
  const DepartmentConfiguration({required this.agencyType, required this.operationalCapabilities, required this.customCapabilities});
  factory DepartmentConfiguration.fromJson(Map<String,dynamic> json)=>DepartmentConfiguration(
    agencyType:(json['agencyType'] as String?)??'FIRE_EMS',
    operationalCapabilities:_decodeStringArray(json['operationalCapabilitiesJson']),
    customCapabilities:_decodeStringArray(json['customCapabilitiesJson']),
  );
  static List<String> _decodeStringArray(Object? raw){
    if(raw is! String||raw.isEmpty)return const[];
    try{final value=jsonDecode(raw);return value is List?value.map((e)=>e.toString()).toList(growable:false):const[];}catch(_){return const[];}
  }
}

class DepartmentClassSetup {
  final List<Map<String, dynamic>> checklists;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> proctors;
  final List<String> requiredFields;

  const DepartmentClassSetup({required this.checklists, required this.members, required this.proctors, required this.requiredFields});

  factory DepartmentClassSetup.fromJson(Map<String, dynamic> json) => DepartmentClassSetup(
        checklists: (json['checklists'] as List? ?? const []).whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList(growable: false),
        members: (json['members'] as List? ?? const []).whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList(growable: false),
        proctors: (json['proctors'] as List? ?? …6278 tokens truncated…rtificationSharing.fromJson(_asMap(data));
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

  Future<Map<String, dynamic>> syncSharedActivities(
    List<Map<String, dynamic>> activities,
  ) async {
    final data = await _request(
      'POST',
      'app/activities/sharing',
      body: <String, dynamic>{'activities': activities},
    );
    return _asMap(data);
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
    // The sign-offs endpoint returns { view, items, counts }. Accept the
    // older bare-list shape too so a valid Needs Attention item is not
    // mistaken for an unassigned review.
    final data = await _request('GET', 'sign-offs?view=needs_me');
    final rawItems = data is List
        ? data
        : data is Map
            ? data['items']
            : null;
    final list = rawItems is List ? rawItems : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => DepartmentReviewItem.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<List<DepartmentTrainingSheetTemplate>> listTrainingSheetTemplates({bool includeArchived = false}) async {
    final data = await _request('GET', 'training-sheet-templates${includeArchived ? '?archived=all' : ''}');
    return (data is List ? data : const <dynamic>[]).whereType<Map>().map((item) => DepartmentTrainingSheetTemplate.fromJson(Map<String, dynamic>.from(item))).toList(growable: false);
  }

  Future<DepartmentTrainingSheetTemplate> createTrainingSheetTemplate({
    required String name, String defaultTitle = '', String classType = 'GENERAL',
    String trainingCategory = 'COMPANY', double creditHours = 0,
    String checklistVersionId = '', String location = '', String notes = '',
    List<String> requiredFields = const [], bool selfRegistration = true,
    List<String> proctorUserIds = const [],
  }) async {
    final data = await _request('POST', 'training-sheet-templates', body: {
      'name': name.trim(), 'defaultTitle': defaultTitle.trim(), 'classType': classType,
      'trainingCategory': trainingCategory, 'creditHours': creditHours,
      'checklistVersionId': checklistVersionId, 'location': location.trim(),
      'notes': notes.trim(), 'requiredFields': requiredFields,
      'selfRegistration': selfRegistration, 'proctorUserIds': proctorUserIds,
    });
    return DepartmentTrainingSheetTemplate.fromJson(_asMap(data));
  }

  Future<DepartmentTrainingSheetTemplate> archiveTrainingSheetTemplate(String id) async {
    final data = await _request('POST', 'training-sheet-templates/${Uri.encodeComponent(id)}/archive', body: const {});
    return DepartmentTrainingSheetTemplate.fromJson(_asMap(data));
  }

  Future<DepartmentConfiguration> getDepartmentConfiguration() async {
    return DepartmentConfiguration.fromJson(_asMap(await _request('GET','department')));
  }

  Future<DepartmentConfiguration> updateDepartmentConfiguration({
    required String agencyType,
    required List<String> operationalCapabilities,
    required List<String> customCapabilities,
  }) async {
    final data=await _request('PATCH','department',body:{
      'agencyType':agencyType,
      'operationalCapabilities':operationalCapabilities,
      'customCapabilities':customCapabilities,
    });
    return DepartmentConfiguration.fromJson(_asMap(data));
  }

  Future<DepartmentClassSetup> getClassSetup() async {
    final data = await _request('GET', 'classes/setup');
    return DepartmentClassSetup.fromJson(_asMap(data));
  }

  Future<DepartmentClassSummary> createTrainingSheet({
    required String title,
    required String startsAt,
    String classType = 'GENERAL',
    String trainingCategory = 'COMPANY',
    String checklistVersionId = '',
    double creditHours = 0,
    String? endsAt,
    String location = '',
    String notes = '',
    List<String> membershipIds = const [],
    List<String> proctorUserIds = const [],
    List<Map<String, String>> stations = const [],
    bool selfRegistration = true,
    String trainingSheetTemplateId = '',
  }) async {
    final data = await _request('POST', 'classes', body: {
      'title': title.trim(),
      'classType': classType,
      'trainingCategory': trainingCategory,
      'checklistVersionId': checklistVersionId,
      'creditHours': creditHours,
      'startsAt': startsAt,
      'endsAt': endsAt,
      'location': location.trim(),
      'notes': notes.trim(),
      'membershipIds': membershipIds,
      'proctorUserIds': proctorUserIds,
      'stations': stations,
      'selfRegistration': selfRegistration,
      if (trainingSheetTemplateId.isNotEmpty) 'trainingSheetTemplateId': trainingSheetTemplateId,
    });
    final map = _asMap(data);
    // Creation returns the canonical class id; fetch the scoped server summary
    // through the normal list endpoint so mobile never invents a local record.
    final rows = await listClasses();
    return rows.firstWhere((row) => row.id == (map['id'] as String? ?? ''));
  }

  Future<List<DepartmentClassSummary>> listClasses() async {
    final data = await _request('GET', 'classes?view=mine');
    return (data is List ? data : const <dynamic>[]).whereType<Map>().map((item) => DepartmentClassSummary.fromJson(Map<String, dynamic>.from(item))).toList(growable: false);
  }

  Future<List<DepartmentQualificationRole>> getMyQualifications() async {
    final data = _asMap(await _request('GET', 'app/qualifications'));
    return (data['roles'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => DepartmentQualificationRole.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<List<DepartmentQualificationMember>> getDepartmentQualifications() async {
    final data = _asMap(await _request('GET', 'app/department-qualifications'));
    return (data['members'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => DepartmentQualificationMember.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<List<DepartmentServerCredential>> getMyDepartmentCredentials() async {
    final data = _asMap(await _request('GET', 'app/certifications'));
    return (data['credentials'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => DepartmentServerCredential.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<DepartmentClassDetail> getTrainingSheet(String classId) async {
    final data = await _request(
      'GET',
      'app/training-sheets/${Uri.encodeComponent(classId)}',
    );
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  Future<DepartmentClassDetail> updateTrainingSheetDocumentation(
    String classId, {
    required DateTime startsAt,
    DateTime? endsAt,
    required String notes,
    required String location,
    String? station,
    String? shift,
    String? trainingCategory,
    required double creditHours,
    Map<String, double> ceCredits = const <String, double>{},
  }) async {
    final data = await _request(
      'PATCH',
      'app/training-sheets/${Uri.encodeComponent(classId)}/documentation',
      body: <String, dynamic>{
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt?.toUtc().toIso8601String(),
        'notes': notes.trim(),
        'location': location.trim(),
        if (station != null) 'station': station.trim(),
        if (shift != null) 'shift': shift.trim(),
        if (trainingCategory != null) 'trainingCategory': trainingCategory,
        'creditHours': creditHours,
        'ceCredits': ceCredits,
      },
    );
    final response = _asMap(data);
    final responseDetail = DepartmentClassDetail.fromJson(response);
    bool sameInstant(DateTime? actual, DateTime? expected) =>
        actual?.millisecondsSinceEpoch == expected?.millisecondsSinceEpoch;
    bool confirmsDocumentation(DepartmentClassDetail detail) =>
        detail.id == classId &&
        sameInstant(detail.startsAt, startsAt) &&
        sameInstant(detail.endsAt, endsAt) &&
        detail.notes == notes.trim() &&
        detail.location == location.trim() &&
        (station == null || detail.station == station.trim()) &&
        (shift == null || detail.shift == shift.trim()) &&
        (trainingCategory == null || detail.trainingCategory == trainingCategory);

    // Some API deployments return a partial PATCH acknowledgement. Never
    // replace the live class detail with that partial body: load the canonical
    // record and confirm the fields used for final closeout were persisted.
    if (confirmsDocumentation(responseDetail)) return responseDetail;

    final saved = await getTrainingSheet(classId);
    if (!confirmsDocumentation(saved)) {
      throw const ResponderRoadmapApiException(
        'The server did not confirm the saved end time and class description. '
        'Your Training Sheet is still open; refresh and try saving again.',
      );
    }
    return saved;
  }

  Future<DepartmentClassDetail> addTrainingSheetRosterMembers(
    String classId, List<String> membershipIds,
  ) async {
    await _request('POST',
      'classes/${Uri.encodeComponent(classId)}/roster/import',
      body: <String, dynamic>{'membershipIds': membershipIds});
    return getClass(classId);
  }

  Future<DepartmentClassDetail> addManualTrainingSheetStudent(
    String classId, {required String name, String email = '', String organization = ''}
  ) async {
    await _request('POST',
      'classes/${Uri.encodeComponent(classId)}/roster/manual',
      body: <String, dynamic>{'name': name.trim(), 'email': email.trim(), 'organization': organization.trim()});
    return getClass(classId);
  }

  Future<DepartmentClassDetail> approveTrainingSheet(String classId) async {
    final data = await _request(
      'POST',
      'app/training-sheets/${Uri.encodeComponent(classId)}/approve',
      body: const <String, dynamic>{},
    );
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  Future<List<InstructorTrainingAttention>> listInstructorTrainingAttention() async {
    final data = await _request('GET', 'app/training-sheets/my-attention');
    return (data is List ? data : const <dynamic>[])
        .whereType<Map>()
        .map((item) => InstructorTrainingAttention.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<List<DepartmentClassDetail>> listRmsActionTrainingSheets() async {
    final data = await _request('GET', 'app/training-sheets/rms-actions');
    return (data is List ? data : const <dynamic>[])
        .whereType<Map>()
        .map((item) => DepartmentClassDetail.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<DepartmentClassDetail> markTrainingSheetEnteredIntoRms(
    String classId, {
    String reference = '',
    String note = '',
  }) async {
    final data = await _request(
      'POST',
      'app/training-sheets/${Uri.encodeComponent(classId)}/rms-entered',
      body: <String, dynamic>{
        if (reference.trim().isNotEmpty) 'reference': reference.trim(),
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  /// Published department Task Books eligible for assignment from a class.
  Future<List<Map<String, dynamic>>> listPublishedClassTaskBooks() async {
    final data = await _request('GET', 'task-books');
    return (data is List ? data : const <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['status'] == 'ACTIVE' && item['templateKind'] != 'TRAINING_TASK')
        .toList(growable: false);
  }

  /// A class is a source of evidence, not a blanket competency approval.
  Future<Map<String, dynamic>> assignTaskBookToClassRoster({
    required String classId,
    required String templateId,
    required List<String> membershipIds,
  }) async {
    final data = await _request(
      'POST',
      'classes/${Uri.encodeComponent(classId)}/assign-task-book',
      body: <String, dynamic>{
        'templateId': templateId,
        'membershipIds': membershipIds,
      },
    );
    return _asMap(data);
  }

  Future<DepartmentClassDetail> getClass(String classId) async {
    final data = await _request('GET', 'classes/${Uri.encodeComponent(classId)}');
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  Future<DepartmentClassDetail> updateClassEvaluationSetup({
    required String classId,
    String trainingSheetTemplateId = '',
    String checklistVersionId = '',
  }) async {
    final data = await _request(
      'PATCH',
      'app/training-sheets/${Uri.encodeComponent(classId)}/evaluation-setup',
      body: <String, dynamic>{
        if (trainingSheetTemplateId.isNotEmpty)
          'trainingSheetTemplateId': trainingSheetTemplateId,
        if (checklistVersionId.isNotEmpty)
          'checklistVersionId': checklistVersionId,
      },
    );
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  Future<DepartmentClassMutationResult> recordClassSkillDurable({required String classId, required String enrollmentId, required String requirementId, required String result, String notes = ''}) async {
    final key='skill:$classId:$enrollmentId:$requirementId';
    try {
      final detail=await recordClassSkill(classId:classId,enrollmentId:enrollmentId,requirementId:requirementId,result:result,notes:notes);
      await _removePendingClassMutation(key);
      return DepartmentClassMutationResult(detail:detail,queued:false);
    } on ResponderRoadmapApiException {
      // Never queue an unversioned skill write for automatic replay.
      rethrow;
    }
  }

  /// Queue only versioned, atomic skill batches. Never retry a stale result as
  /// an unconditional write: the server compares expectedUpdatedAt for every
  /// enrollment and rejects the entire batch when any result has changed.
  Future<DepartmentClassMutationResult> recordClassSkillBatchDurable({
    required String classId,
    String requirementId = '',
    required List<Map<String, dynamic>> results,
  }) async {
    if (results.isEmpty) {
      throw const ResponderRoadmapApiException('Select at least one student result.');
    }
    if (results.any((result) =>
        !result.containsKey('expectedUpdatedAt') ||
        (result['expectedUpdatedAt'] != null &&
            result['expectedUpdatedAt'] is! String))) {
      throw const ResponderRoadmapApiException(
        'Refresh the Training Sheet before saving skill results without a revision.',
        statusCode: 400,
      );
    }
    final body = <String, dynamic>{
      'requirementId': requirementId,
      'results': results,
    };
    try {
      final data = await _request(
        'POST',
        'app/training-sheets/${Uri.encodeComponent(classId)}/skills/batch',
        body: body,
      );
      return DepartmentClassMutationResult(
        detail: DepartmentClassDetail.fromJson(_asMap(data)),
        queued: false,
      );
    } on ResponderRoadmapApiException catch (error) {
      if (_isNonRetryableRequestFailure(error)) rethrow;
      final nonce = Random.secure().nextInt(1 << 32);
      final key = 'skill_batch:$classId:${DateTime.now().microsecondsSinceEpoch}:$nonce';
      await _savePendingClassMutation(<String, dynamic>{
        'key': key,
        'kind': 'skill_batch',
        'classId': classId,
        'requirementId': requirementId,
        'results': results,
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
        'syncStatus': 'PENDING',
      });
      return const DepartmentClassMutationResult(detail: null, queued: true);
    }
  }

  Future<int> pendingSkillMutationCountForClass(String classId) async {
    final rows = await _pendingClassMutations();
    return rows.where((row) =>
        row['classId'] == classId &&
        (row['kind'] == 'skill_batch' || row['kind'] == 'skill')).length;
  }

  Future<int> pendingSkillConflictCountForClass(String classId) async {
    final rows = await _pendingClassMutations();
    return rows.where((row) =>
        row['classId'] == classId && row['syncStatus'] == 'CONFLICT').length;
  }

  Future<List<Map<String,dynamic>>> pendingSkillMutationsForClass(String classId) async {
    final rows = await _pendingClassMutations();
    return rows.where((row) =>
        row['classId'] == classId &&
        (row['kind'] == 'skill_batch' || row['kind'] == 'skill'))
        .map((row)=>Map<String,dynamic>.from(row)).toList(growable:false);
  }

  /// Only call after an instructor has compared the queued observations with
  /// the official server record and explicitly chooses to discard this copy.
  Future<void> discardReviewedSkillMutation(String classId, String key) async {
    final rows = await pendingSkillMutationsForClass(classId);
    if(!rows.any((row)=>row['key']==key)) {
      throw const ResponderRoadmapApiException('The selected pending batch is unavailable.');
    }
    await _removePendingClassMutation(key);
  }

  Future<DepartmentClassMutationResult> updateClassStudentDurable({required String classId, required String enrollmentId, required String attendance}) async {
    final key='attendance:$classId:$enrollmentId';
    final row={'key':key,'kind':'attendance','classId':classId,'enrollmentId':enrollmentId,'attendance':attendance,'queuedAt':DateTime.now().toUtc().toIso8601String()};
    try {
      final detail=await updateClassStudent(classId:classId,enrollmentId:enrollmentId,attendance:attendance);
      await _removePendingClassMutation(key);
      return DepartmentClassMutationResult(detail:detail,queued:false);
    } on ResponderRoadmapApiException catch (error) {
      if (_isNonRetryableRequestFailure(error)) rethrow;
      await _savePendingClassMutation(row);
      return const DepartmentClassMutationResult(detail:null,queued:true);
    }
  }

  Future<int> pendingClassMutationCount() async {
    final rows=await _pendingClassMutations();
    return rows.length;
  }

  Future<int> retryPendingClassMutations() async {
    final rows=await _pendingClassMutations();
    var completed=0;
    for(final row in rows){
      final key=(row['key'] as String?)??'';
      try{
        if(row['kind']=='attendance'){
          await updateClassStudent(classId:(row['classId'] as String?)??'',enrollmentId:(row['enrollmentId'] as String?)??'',attendance:(row['attendance'] as String?)??'REGISTERED');
        }else if(row['kind']=='skill_batch'){
          // Conflicted revisions require instructor review. Do not auto-overwrite.
          if(row['syncStatus']=='CONFLICT') continue;
          final classId=(row['classId'] as String?)??'';
          final requirementId=(row['requirementId'] as String?)??'';
          final rawResults=row['results'];
          if(classId.isEmpty || rawResults is! List) continue;
          final results=rawResults.whereType<Map>()
              .map((item)=>Map<String,dynamic>.from(item)).toList(growable:false);
          if(results.isEmpty || results.any((item)=>!item.containsKey('expectedUpdatedAt'))) {
            continue;
          }
          await _request(
            'POST',
            'app/training-sheets/${Uri.encodeComponent(classId)}/skills/batch',
            body:<String,dynamic>{'requirementId':requirementId,'results':results},
          );
        }else if(row['kind']=='skill'){
          // Historical unversioned skill records are never automatically replayed.
          continue;
        }else{continue;}
        await _removePendingClassMutation(key); completed++;
      }on ResponderRoadmapApiException catch(error){
        if(error.statusCode==409 && row['kind']=='skill_batch'){
          // Preserve the original evaluation and make the conflict visible.
          await _savePendingClassMutation(<String,dynamic>{
            ...row,'syncStatus':'CONFLICT',
          });
        }
        // Offline or denied requests stay durable until manually resolved.
      }
    }
    return completed;
  }

  Future<List<Map<String,dynamic>>> _pendingClassMutations() async {
    final raw=await _secureStorage.read(key:_pendingClassMutationsKey);
    try{final value=raw==null?null:jsonDecode(raw);return value is List?value.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList():<Map<String,dynamic>>[];}catch(_){return <Map<String,dynamic>>[];}
  }
  Future<void> _savePendingClassMutation(Map<String,dynamic> row) async {
    final rows=await _pendingClassMutations();
    rows.removeWhere((item)=>item['key']==row['key']);
    rows.add(row);
    await _secureStorage.write(key:_pendingClassMutationsKey,value:jsonEncode(rows));
  }
  Future<void> _removePendingClassMutation(String key) async {
    final rows=await _pendingClassMutations();
    rows.removeWhere((item)=>item['key']==key);
    await _secureStorage.write(key:_pendingClassMutationsKey,value:jsonEncode(rows));
  }

  bool _isNonRetryableRequestFailure(ResponderRoadmapApiException error) =>
      error.statusCode != null &&
      error.statusCode! >= 400 &&
      error.statusCode! < 500 &&
      error.statusCode != 408;

  Future<DepartmentClassDetail> recordClassSkill({required String classId, required String enrollmentId, required String requirementId, required String result, String notes = ''}) async {
    final data = await _request('POST', 'classes/${Uri.encodeComponent(classId)}/roster/${Uri.encodeComponent(enrollmentId)}/skills/${Uri.encodeComponent(requirementId)}', body: {'result': result, 'notes': notes.trim()});
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  Future<DepartmentClassDetail> updateClassStudent({required String classId, required String enrollmentId, required String attendance, Map<String, dynamic>? customValues, double? writtenScore, double? ccfScore}) async {
    final data = await _request('POST', 'classes/${Uri.encodeComponent(classId)}/roster/${Uri.encodeComponent(enrollmentId)}', body: {'attendance': attendance, if (customValues != null) 'customValues': customValues, if (writtenScore != null) 'writtenScore': writtenScore, if (ccfScore != null) 'ccfScore': ccfScore});
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  Future<DepartmentClassDetail> manageClassRegistration({required String classId, required String action}) async {
    final data = await _request('POST', 'classes/${Uri.encodeComponent(classId)}/registration', body: {'action': action});
    return DepartmentClassDetail.fromJson(_asMap(data));
  }

  Future<DepartmentCloseValidation> validateClassClosure(String classId) async {
    final data=await _request('GET','classes/${Uri.encodeComponent(classId)}/close-validation');
    return DepartmentCloseValidation.fromJson(_asMap(data));
  }

  Future<DepartmentClassDetail> updateClassStatus({required String classId, required String status}) async {
    final data = await _request('POST', 'classes/${Uri.encodeComponent(classId)}/status', body: {'status': status});
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

  Future<List<int>> downloadClosedTrainingCsv(String classId) async {
    final token=(await _secureStorage.read(key:_tokenKey))?.trim()??'';
    if(token.isEmpty)throw const ResponderRoadmapApiException('Connect your ResponderRoadmap account first.',statusCode:401);
    final response=await _client.get(Uri.parse('$baseUrl/classes/${Uri.encodeComponent(classId)}/export.csv'),headers:{'Accept':'text/csv','Authorization':'Bearer $token'});
    if(response.statusCode<200||response.statusCode>=300)throw ResponderRoadmapApiException('Could not export this training record (${response.statusCode}).',statusCode:response.statusCode);
    return response.bodyBytes;
  }

  Future<Map<String,dynamic>> getClosedTrainingExportRecord(String classId) async =>
      _asMap(await _request('GET','classes/${Uri.encodeComponent(classId)}/export'));

  Future<void> disconnect() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final timer = Stopwatch()..start();
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
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          );
          break;
        default:
          throw ResponderRoadmapApiException('Unsupported request method: $method');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Roadmap API] $method $path network failure after ${timer.elapsedMilliseconds}ms');
      }
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

    if (kDebugMode) {
      debugPrint('[Roadmap API] $method $path ${response.statusCode} ${timer.elapsedMilliseconds}ms');
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


class DepartmentClassRegistrationPreview {
  final String title;
  final DateTime? startsAt;
  final String location;
  final bool open;

  const DepartmentClassRegistrationPreview({
    required this.title,
    required this.startsAt,
    required this.location,
    required this.open,
  });

  factory DepartmentClassRegistrationPreview.fromJson(Map<String, dynamic> json) =>
      DepartmentClassRegistrationPreview(
        title: (json['title'] as String?) ?? 'Department class',
        startsAt: DateTime.tryParse((json['startsAt'] as String?) ?? ''),
        location: (json['location'] as String?) ?? '',
        open: json['open'] == true,
      );
}

class DepartmentClassRegistrationResult {
  final bool registered;
  final bool alreadyRegistered;
  final String classId;
  final String title;
  final DateTime? startsAt;
  final String location;

  const DepartmentClassRegistrationResult({
    required this.registered,
    required this.alreadyRegistered,
    required this.classId,
    required this.title,
    required this.startsAt,
    required this.location,
  });

  factory DepartmentClassRegistrationResult.fromJson(Map<String, dynamic> json) =>
      DepartmentClassRegistrationResult(
        registered: json['registered'] == true,
        alreadyRegistered: json['alreadyRegistered'] == true,
        classId: (json['classId'] as String?) ?? '',
        title: (json['title'] as String?) ?? 'Department class',
        startsAt: DateTime.tryParse((json['startsAt'] as String?) ?? ''),
        location: (json['location'] as String?) ?? '',
      );
}
