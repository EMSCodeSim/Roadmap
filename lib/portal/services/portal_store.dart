import 'package:flutter/foundation.dart';

import 'package:firepath/portal/models/activity_event.dart';
import 'package:firepath/portal/models/assignment_models.dart';
import 'package:firepath/portal/models/credential.dart';
import 'package:firepath/portal/models/department.dart';
import 'package:firepath/portal/models/department_membership.dart';
import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/models/task_book_template.dart';
import 'package:firepath/portal/services/portal_db.dart';
import 'package:firepath/services/local_store.dart';

class PortalStore {
  static const String _kDb = 'responderroadmap.portal.db.v1';
  static const String _kSession = 'responderroadmap.portal.session.v1';

  final LocalStore _store;
  PortalStore({LocalStore? store}) : _store = store ?? LocalStore();

  Future<PortalDb> loadDb() async {
    try {
      final json = await _store.loadJsonMap(_kDb);
      if (json == null) return PortalDb.empty();
      return PortalDb.fromJson(json);
    } catch (e) {
      debugPrint('PortalStore.loadDb failed: $e');
      return PortalDb.empty();
    }
  }

  Future<bool> saveDb(PortalDb db) async {
    try {
      return await _store.saveJsonChecked(_kDb, db.toJson());
    } catch (e) {
      debugPrint('PortalStore.saveDb failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> loadSession() => _store.loadJsonMap(_kSession);
  Future<bool> saveSession(Map<String, dynamic> json) => _store.saveJsonChecked(_kSession, json);
  Future<bool> clearSession() => _store.removeKey(_kSession);

  Future<bool> clearDb() => _store.removeKey(_kDb);

  /// Seeds a realistic demo department and workflow if the DB is empty.
  Future<PortalDb> ensureSeeded() async {
    final current = await loadDb();
    if (current.departments.isNotEmpty && current.users.isNotEmpty) return current;

    final now = DateTime.now();
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));
    DateTime daysFromNow(int days) => now.add(Duration(days: days));

    const deptId = 'dept_metro';
    const trainingOfficerId = 'u_to_samlee';
    const evaluatorId = 'u_eval_captlee';

    final dept = Department(
      id: deptId,
      name: 'Metro Fire & Rescue',
      joinCode: 'NFR-4821',
      timeZone: 'America/Denver',
      createdAt: daysAgo(200),
      updatedAt: daysAgo(2),
    );

    final users = <PortalUser>[
      PortalUser(
        id: 'u_alex',
        name: 'Alex Morgan',
        email: 'alex.morgan@metrofire.example',
        rank: 'Firefighter',
        station: 'Station 7',
        shift: 'A',
        isActive: true,
        createdAt: daysAgo(400),
        updatedAt: daysAgo(1),
      ),
      PortalUser(
        id: 'u_jordan',
        name: 'Jordan Smith',
        email: 'jordan.smith@metrofire.example',
        rank: 'Firefighter/EMT',
        station: 'Station 3',
        shift: 'B',
        isActive: true,
        createdAt: daysAgo(520),
        updatedAt: daysAgo(3),
      ),
      PortalUser(
        id: 'u_taylor',
        name: 'Taylor Brooks',
        email: 'taylor.brooks@metrofire.example',
        rank: 'Engineer',
        station: 'Station 7',
        shift: 'A',
        isActive: true,
        createdAt: daysAgo(730),
        updatedAt: daysAgo(7),
      ),
      PortalUser(
        id: 'u_chris',
        name: 'Chris Davis',
        email: 'chris.davis@metrofire.example',
        rank: 'Paramedic',
        station: 'Station 5',
        shift: 'C',
        isActive: true,
        createdAt: daysAgo(210),
        updatedAt: daysAgo(1),
      ),
      PortalUser(
        id: trainingOfficerId,
        name: 'Sam Lee',
        email: 'sam.lee@metrofire.example',
        rank: 'Lieutenant',
        station: 'Station 1',
        shift: 'Day',
        isActive: true,
        createdAt: daysAgo(1400),
        updatedAt: daysAgo(0),
      ),
      PortalUser(
        id: evaluatorId,
        name: 'Captain Lee',
        email: 'captain.lee@metrofire.example',
        rank: 'Captain',
        station: 'Station 7',
        shift: 'A',
        isActive: true,
        createdAt: daysAgo(1700),
        updatedAt: daysAgo(0),
      ),
    ];

    DepartmentMembership m(String id, String userId, PortalRole role) {
      return DepartmentMembership(
        id: id,
        departmentId: deptId,
        userId: userId,
        role: role,
        status: MembershipStatus.active,
        joinedAt: daysAgo(200),
        createdAt: daysAgo(200),
        updatedAt: daysAgo(2),
      );
    }

    final memberships = <DepartmentMembership>[
      m('m1', 'u_alex', PortalRole.member),
      m('m2', 'u_jordan', PortalRole.member),
      m('m3', 'u_taylor', PortalRole.member),
      m('m4', 'u_chris', PortalRole.member),
      m('m5', trainingOfficerId, PortalRole.trainingOfficer),
      m('m6', evaluatorId, PortalRole.evaluator),
    ];

    final templates = <TaskBookTemplate>[
      TaskBookTemplate(
        id: 'tbt_probationary',
        departmentId: deptId,
        title: 'Probationary Firefighter',
        description: 'Department probationary requirements and core skills sign-off.',
        category: 'Fire',
        ownerUserId: trainingOfficerId,
        status: TaskBookTemplateStatus.active,
        createdAt: daysAgo(160),
        updatedAt: daysAgo(2),
      ),
      TaskBookTemplate(
        id: 'tbt_driver_pumper',
        departmentId: deptId,
        title: 'Driver / Operator – Pumper',
        description: 'Department driver qualification and engine operator standards.',
        category: 'Driver',
        ownerUserId: trainingOfficerId,
        status: TaskBookTemplateStatus.active,
        createdAt: daysAgo(140),
        updatedAt: daysAgo(20),
      ),
      TaskBookTemplate(
        id: 'tbt_officer_1',
        departmentId: deptId,
        title: 'Fire Officer I',
        description: 'Company officer development requirements and evaluations.',
        category: 'Leadership',
        ownerUserId: trainingOfficerId,
        status: TaskBookTemplateStatus.active,
        createdAt: daysAgo(120),
        updatedAt: daysAgo(30),
      ),
      TaskBookTemplate(
        id: 'tbt_new_medic',
        departmentId: deptId,
        title: 'New Paramedic Orientation',
        description: 'EMS orientation and field evaluation tasks for new medics.',
        category: 'EMS',
        ownerUserId: trainingOfficerId,
        status: TaskBookTemplateStatus.active,
        createdAt: daysAgo(90),
        updatedAt: daysAgo(10),
      ),
    ];

    final versions = <TaskBookVersion>[
      TaskBookVersion(
        id: 'tbv_probationary_1_0',
        templateId: 'tbt_probationary',
        version: '1.0',
        isPublished: true,
        publishedAt: daysAgo(150),
        createdAt: daysAgo(150),
        updatedAt: daysAgo(150),
      ),
    ];

    final sections = <TaskBookSection>[
      TaskBookSection(
        id: 'sec_orient',
        versionId: 'tbv_probationary_1_0',
        title: 'Department Orientation',
        description: 'Policies, radio, accountability, reporting.',
        sortOrder: 0,
        createdAt: daysAgo(150),
        updatedAt: daysAgo(150),
      ),
      TaskBookSection(
        id: 'sec_ppe_scba',
        versionId: 'tbv_probationary_1_0',
        title: 'PPE / SCBA',
        description: 'PPE inspection, donning, SCBA checks and emergencies.',
        sortOrder: 1,
        createdAt: daysAgo(150),
        updatedAt: daysAgo(150),
      ),
      TaskBookSection(
        id: 'sec_engine_ops',
        versionId: 'tbv_probationary_1_0',
        title: 'Engine Operations',
        description: 'Hose deployment, nozzle control, hydrants, water supply.',
        sortOrder: 2,
        createdAt: daysAgo(150),
        updatedAt: daysAgo(150),
      ),
    ];

    TaskBookRequirement req(String id, String sectionId, int sortOrder, String title, EvidenceType evidenceType) {
      return TaskBookRequirement(
        id: id,
        sectionId: sectionId,
        title: title,
        description: '',
        instructions: 'Demonstrate competency to evaluator. Follow department SOPs.',
        sortOrder: sortOrder,
        isRequired: true,
        evaluatorSignOffRequired: true,
        supervisorApprovalRequired: false,
        evidenceType: evidenceType,
        repetitionsRequired: 1,
        dueOffsetDays: null,
        prerequisiteRequirementIds: const [],
        tags: const [],
        estimatedMinutes: 15,
        createdAt: daysAgo(150),
        updatedAt: daysAgo(150),
      );
    }

    final requirements = <TaskBookRequirement>[
      req('req_radio', 'sec_orient', 0, 'Radio operations and unit identifiers', EvidenceType.supervisorObservation),
      req('req_accountability', 'sec_orient', 1, 'Accountability tags and PAR', EvidenceType.supervisorObservation),
      req('req_ppe_inspect', 'sec_ppe_scba', 0, 'Inspect PPE and identify damage', EvidenceType.writtenNote),
      req('req_scba_don', 'sec_ppe_scba', 1, 'Don SCBA within time standard', EvidenceType.skillEvaluation),
      req('req_hose_deploy', 'sec_engine_ops', 0, 'Deploy 1¾-inch attack line', EvidenceType.skillEvaluation),
      req('req_hydrant', 'sec_engine_ops', 1, 'Hydrant connection and water supply', EvidenceType.supervisorObservation),
    ];

    final assignment = TaskBookAssignment(
      id: 'as_alex_probationary',
      departmentId: deptId,
      taskBookVersionId: 'tbv_probationary_1_0',
      memberId: 'u_alex',
      assignedBy: trainingOfficerId,
      evaluatorId: evaluatorId,
      supervisorId: trainingOfficerId,
      assignedDate: daysAgo(60),
      dueDate: daysFromNow(120),
      status: AssignmentStatus.inProgress,
      createdAt: daysAgo(60),
      updatedAt: daysAgo(1),
    );

    RequirementCompletion completion(
      String id,
      String reqId,
      CompletionStatus status, {
      DateTime? submittedAt,
      DateTime? completedAt,
      String notes = '',
    }) {
      return RequirementCompletion(
        id: id,
        assignmentId: assignment.id,
        requirementId: reqId,
        memberId: 'u_alex',
        status: status,
        memberNotes: notes,
        submittedAt: submittedAt,
        completedAt: completedAt,
        createdAt: daysAgo(60),
        updatedAt: daysAgo(1),
      );
    }

    final completions = <RequirementCompletion>[
      completion('c_radio', 'req_radio', CompletionStatus.approved, completedAt: daysAgo(7), notes: 'Reviewed unit identifiers and radio discipline.'),
      completion('c_account', 'req_accountability', CompletionStatus.approved, completedAt: daysAgo(10), notes: 'Completed accountability drill during training night.'),
      completion('c_ppe', 'req_ppe_inspect', CompletionStatus.submitted, submittedAt: daysAgo(1), notes: 'Inspected bunker gear, noted minor glove wear.'),
      completion('c_scba', 'req_scba_don', CompletionStatus.approved, completedAt: daysAgo(12), notes: 'Met time standard, clean emergency procedures.'),
      completion('c_hose', 'req_hose_deploy', CompletionStatus.submitted, submittedAt: daysAgo(0), notes: 'Deployed preconnect with correct nozzle pattern selection.'),
      completion('c_hydrant', 'req_hydrant', CompletionStatus.notStarted),
    ];

    final evidence = <Evidence>[
      Evidence(
        id: 'ev_ppe_note',
        completionId: 'c_ppe',
        type: 'Written note',
        description: 'PPE checklist submitted in-app.',
        fileUrl: null,
        uploadedAt: daysAgo(1),
        createdAt: daysAgo(1),
        updatedAt: daysAgo(1),
      ),
      Evidence(
        id: 'ev_hose_skill',
        completionId: 'c_hose',
        type: 'Skill evaluation',
        description: 'Evaluator observation requested. No file required.',
        fileUrl: null,
        uploadedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final signOffs = <SignOff>[
      SignOff(
        id: 'so_radio',
        completionId: 'c_radio',
        evaluatorId: evaluatorId,
        result: SignOffResult.approved,
        notes: 'Solid radio discipline; coached on brevity.',
        signedAt: daysAgo(7),
        createdAt: daysAgo(7),
        updatedAt: daysAgo(7),
      ),
      SignOff(
        id: 'so_account',
        completionId: 'c_account',
        evaluatorId: evaluatorId,
        result: SignOffResult.approved,
        notes: 'Understands PAR, tag placement, and accountability board.',
        signedAt: daysAgo(10),
        createdAt: daysAgo(10),
        updatedAt: daysAgo(10),
      ),
      SignOff(
        id: 'so_scba',
        completionId: 'c_scba',
        evaluatorId: evaluatorId,
        result: SignOffResult.approved,
        notes: 'Meets time and check sequence. Good emergency procedures.',
        signedAt: daysAgo(12),
        createdAt: daysAgo(12),
        updatedAt: daysAgo(12),
      ),
    ];

    Credential cred(String id, String memberId, String name, DateTime? exp, {String issuer = 'State'} ) {
      return Credential(
        id: id,
        departmentId: deptId,
        memberId: memberId,
        credentialType: name.toLowerCase().replaceAll(' ', '_'),
        credentialName: name,
        issuer: issuer,
        credentialNumber: null,
        issueDate: daysAgo(300),
        expirationDate: exp,
        verificationStatus: CredentialVerificationStatus.verified,
        attachmentUrl: null,
        notes: '',
        createdAt: daysAgo(300),
        updatedAt: daysAgo(3),
      );
    }

    final credentials = <Credential>[
      cred('cred_alex_emt', 'u_alex', 'EMT', daysFromNow(240), issuer: 'State EMS'),
      cred('cred_alex_cpr', 'u_alex', 'CPR', daysFromNow(48), issuer: 'AHA'),
      cred('cred_jordan_emt', 'u_jordan', 'EMT', daysFromNow(61), issuer: 'State EMS'),
      cred('cred_jordan_cpr', 'u_jordan', 'CPR', daysFromNow(300), issuer: 'AHA'),
      cred('cred_taylor_driver', 'u_taylor', 'Driver / Operator – Pumper', daysFromNow(500), issuer: 'Department'),
      cred('cred_chris_acls', 'u_chris', 'ACLS', daysFromNow(120), issuer: 'AHA'),
    ];

    final activity = <ActivityEvent>[
      ActivityEvent(
        id: 'act1',
        departmentId: deptId,
        userId: 'u_alex',
        type: 'requirement.completed',
        referenceId: 'c_radio',
        timestamp: daysAgo(7),
        metadata: const {'taskBook': 'Probationary Firefighter', 'requirement': 'Radio operations and unit identifiers'},
        createdAt: daysAgo(7),
        updatedAt: daysAgo(7),
      ),
      ActivityEvent(
        id: 'act2',
        departmentId: deptId,
        userId: 'u_jordan',
        type: 'credential.uploaded',
        referenceId: 'cred_jordan_emt',
        timestamp: daysAgo(2),
        metadata: const {'credential': 'EMT', 'action': 'Renewal uploaded'},
        createdAt: daysAgo(2),
        updatedAt: daysAgo(2),
      ),
      ActivityEvent(
        id: 'act3',
        departmentId: deptId,
        userId: evaluatorId,
        type: 'signoff.approved',
        referenceId: 'so_scba',
        timestamp: daysAgo(12),
        metadata: const {'member': 'Alex Morgan', 'requirement': 'Don SCBA within time standard'},
        createdAt: daysAgo(12),
        updatedAt: daysAgo(12),
      ),
      ActivityEvent(
        id: 'act4',
        departmentId: deptId,
        userId: trainingOfficerId,
        type: 'assignment.created',
        referenceId: assignment.id,
        timestamp: daysAgo(60),
        metadata: const {'member': 'Alex Morgan', 'taskBook': 'Probationary Firefighter v1.0'},
        createdAt: daysAgo(60),
        updatedAt: daysAgo(60),
      ),
    ];

    final seeded = PortalDb(
      departments: [dept],
      users: users,
      memberships: memberships,
      taskBookTemplates: templates,
      taskBookVersions: versions,
      taskBookSections: sections,
      taskBookRequirements: requirements,
      assignments: [assignment],
      completions: completions,
      evidence: evidence,
      signOffs: signOffs,
      credentials: credentials,
      activity: activity,
      createdAt: now,
      updatedAt: now,
    );

    await saveDb(seeded);
    return seeded;
  }
}
