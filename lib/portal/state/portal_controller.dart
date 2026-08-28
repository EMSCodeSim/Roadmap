import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:firepath/portal/models/assignment_models.dart';
import 'package:firepath/portal/models/department.dart';
import 'package:firepath/portal/models/department_membership.dart';
import 'package:firepath/portal/models/portal_user.dart';
import 'package:firepath/portal/models/task_book_template.dart';
import 'package:firepath/portal/services/portal_db.dart';
import 'package:firepath/portal/services/portal_store.dart';

class PortalController extends ChangeNotifier {
  final PortalStore _store;
  PortalController({PortalStore? store}) : _store = store ?? PortalStore();

  bool _bootstrapped = false;
  bool get bootstrapped => _bootstrapped;

  PortalDb _db = PortalDb.empty();
  PortalDb get db => _db;

  String? _activeDepartmentId;
  String? get activeDepartmentId => _activeDepartmentId;

  String? _sessionUserId;
  String? get sessionUserId => _sessionUserId;

  PortalRole? _sessionRole;
  PortalRole? get sessionRole => _sessionRole;

  Department? get activeDepartment => _db.departments.where((d) => d.id == _activeDepartmentId).cast<Department?>().firstWhere((e) => true, orElse: () => null);

  PortalUser? get sessionUser => _db.users.where((u) => u.id == _sessionUserId).cast<PortalUser?>().firstWhere((e) => true, orElse: () => null);

  Future<void> bootstrap() async {
    try {
      _db = await _store.ensureSeeded();
      final session = await _store.loadSession();
      if (session != null) {
        _activeDepartmentId = (session['departmentId'] as String?) ?? _db.departments.firstOrNull?.id;
        _sessionUserId = session['userId'] as String?;
        final roleName = session['role'] as String?;
        _sessionRole = PortalRole.values.firstWhere((e) => e.name == roleName, orElse: () => PortalRole.trainingOfficer);
      } else {
        _activeDepartmentId = _db.departments.firstOrNull?.id;
      }
    } catch (e) {
      debugPrint('PortalController.bootstrap failed: $e');
    } finally {
      _bootstrapped = true;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    _db = await _store.loadDb();
    notifyListeners();
  }

  Future<void> signInAs({required String userId, required PortalRole role}) async {
    _sessionUserId = userId;
    _sessionRole = role;
    final deptId = _activeDepartmentId ?? _db.departments.firstOrNull?.id;
    _activeDepartmentId = deptId;
    await _store.saveSession({'departmentId': deptId, 'userId': userId, 'role': role.name});
    notifyListeners();
  }

  Future<void> signOut() async {
    _sessionUserId = null;
    _sessionRole = null;
    await _store.clearSession();
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    await signOut();
    await _store.clearDb();
    _bootstrapped = false;
    notifyListeners();
    await bootstrap();
  }

  bool hasRole(PortalRole requiredRole) {
    final role = _sessionRole;
    if (role == null) return false;
    int rank(PortalRole r) => switch (r) {
          PortalRole.member => 0,
          PortalRole.evaluator => 1,
          PortalRole.trainingOfficer => 2,
          PortalRole.departmentAdmin => 3,
        };
    return rank(role) >= rank(requiredRole);
  }

  DepartmentMembership? membershipFor(String userId) {
    final deptId = _activeDepartmentId;
    if (deptId == null) return null;
    return _db.memberships
        .where((m) => m.departmentId == deptId && m.userId == userId)
        .cast<DepartmentMembership?>()
        .firstWhere((e) => true, orElse: () => null);
  }

  // ---------------------------------------------------------------------------
  // Query helpers (UI-friendly)
  // ---------------------------------------------------------------------------

  List<PortalUser> get departmentMembers {
    final deptId = _activeDepartmentId;
    if (deptId == null) return const [];
    final memberIds = _db.memberships
        .where((m) => m.departmentId == deptId && m.status == MembershipStatus.active)
        .map((m) => m.userId)
        .toSet();
    final users = _db.users.where((u) => memberIds.contains(u.id)).toList();
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }

  List<TaskBookTemplate> get templatesForDept {
    final deptId = _activeDepartmentId;
    if (deptId == null) return const [];
    final items = _db.taskBookTemplates.where((t) => t.departmentId == deptId).toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  TaskBookVersion? publishedVersionForTemplate(String templateId) {
    final versions = _db.taskBookVersions
        .where((v) => v.templateId == templateId && v.isPublished)
        .toList();
    if (versions.isEmpty) return null;
    versions.sort((a, b) => _compareSemver(b.version, a.version));
    return versions.first;
  }

  List<TaskBookSection> sectionsForVersion(String versionId) {
    final items = _db.taskBookSections.where((s) => s.versionId == versionId).toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  List<TaskBookRequirement> requirementsForSection(String sectionId) {
    final items = _db.taskBookRequirements.where((r) => r.sectionId == sectionId).toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  List<TaskBookAssignment> assignmentsForMember(String memberId) {
    final deptId = _activeDepartmentId;
    if (deptId == null) return const [];
    final items = _db.assignments.where((a) => a.departmentId == deptId && a.memberId == memberId).toList();
    items.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));
    return items;
  }

  List<RequirementCompletion> completionsForAssignment(String assignmentId) {
    final items = _db.completions.where((c) => c.assignmentId == assignmentId).toList();
    items.sort((a, b) => a.requirementId.compareTo(b.requirementId));
    return items;
  }

  double progressForAssignment(TaskBookAssignment assignment) {
    final versionId = assignment.taskBookVersionId;
    final sectionIds = _db.taskBookSections.where((s) => s.versionId == versionId).map((s) => s.id).toSet();
    final reqIds = _db.taskBookRequirements.where((r) => sectionIds.contains(r.sectionId)).map((r) => r.id).toList();
    if (reqIds.isEmpty) return 0;
    final completionByReq = {
      for (final c in _db.completions.where((c) => c.assignmentId == assignment.id)) c.requirementId: c,
    };
    int done = 0;
    for (final reqId in reqIds) {
      final c = completionByReq[reqId];
      if (c == null) continue;
      if (c.status == CompletionStatus.approved) done++;
    }
    return done / reqIds.length;
  }

  int pendingSignOffCount() {
    final deptId = _activeDepartmentId;
    if (deptId == null) return 0;
    final assignmentIds = _db.assignments.where((a) => a.departmentId == deptId).map((a) => a.id).toSet();
    return _db.completions
        .where((c) => assignmentIds.contains(c.assignmentId) && c.status == CompletionStatus.submitted)
        .length;
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<String> createBlankTaskBook({
    required String title,
    required String category,
    required String description,
  }) async {
    final deptId = _activeDepartmentId;
    final ownerId = _sessionUserId;
    if (deptId == null || ownerId == null) throw StateError('No active department/session');
    final now = DateTime.now();
    final templateId = _id('tbt');
    final template = TaskBookTemplate(
      id: templateId,
      departmentId: deptId,
      title: title,
      description: description,
      category: category,
      ownerUserId: ownerId,
      status: TaskBookTemplateStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
    final draftVersion = TaskBookVersion(
      id: _id('tbv'),
      templateId: templateId,
      version: '1.0',
      isPublished: false,
      publishedAt: DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: now,
      updatedAt: now,
    );
    _db = _db.copyWith(
      taskBookTemplates: [..._db.taskBookTemplates, template],
      taskBookVersions: [..._db.taskBookVersions, draftVersion],
      updatedAt: now,
    );
    await _store.saveDb(_db);
    notifyListeners();
    return templateId;
  }

  Future<String> addSection({required String versionId, required String title, String description = ''}) async {
    final now = DateTime.now();
    final existing = _db.taskBookSections.where((s) => s.versionId == versionId).toList();
    final nextOrder = existing.isEmpty ? 0 : (existing.map((e) => e.sortOrder).reduce(max) + 1);
    final section = TaskBookSection(
      id: _id('sec'),
      versionId: versionId,
      title: title,
      description: description,
      sortOrder: nextOrder,
      createdAt: now,
      updatedAt: now,
    );
    _db = _db.copyWith(taskBookSections: [..._db.taskBookSections, section], updatedAt: now);
    await _store.saveDb(_db);
    notifyListeners();
    return section.id;
  }

  Future<void> reorderSections({required String versionId, required int oldIndex, required int newIndex}) async {
    final now = DateTime.now();
    final list = sectionsForVersion(versionId);
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex > list.length) return;
    final item = list.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    list.insert(insertAt, item);
    final updated = <String, TaskBookSection>{};
    for (var i = 0; i < list.length; i++) {
      updated[list[i].id] = list[i].copyWith(sortOrder: i, updatedAt: now);
    }
    _db = _db.copyWith(
      taskBookSections: _db.taskBookSections.map((s) => updated[s.id] ?? s).toList(),
      updatedAt: now,
    );
    await _store.saveDb(_db);
    notifyListeners();
  }

  Future<void> reorderRequirements({required String sectionId, required int oldIndex, required int newIndex}) async {
    final now = DateTime.now();
    final list = requirementsForSection(sectionId);
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex > list.length) return;
    final item = list.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    list.insert(insertAt, item);
    final updated = <String, TaskBookRequirement>{};
    for (var i = 0; i < list.length; i++) {
      updated[list[i].id] = list[i].copyWith(sortOrder: i, updatedAt: now);
    }
    _db = _db.copyWith(
      taskBookRequirements: _db.taskBookRequirements.map((r) => updated[r.id] ?? r).toList(),
      updatedAt: now,
    );
    await _store.saveDb(_db);
    notifyListeners();
  }

  Future<String> addRequirement({
    required String sectionId,
    required String title,
    String description = '',
    String instructions = 'Demonstrate competency to evaluator. Follow department SOPs.',
  }) async {
    final now = DateTime.now();
    final existing = _db.taskBookRequirements.where((r) => r.sectionId == sectionId).toList();
    final nextOrder = existing.isEmpty ? 0 : (existing.map((e) => e.sortOrder).reduce(max) + 1);
    final req = TaskBookRequirement(
      id: _id('req'),
      sectionId: sectionId,
      title: title,
      description: description,
      instructions: instructions,
      sortOrder: nextOrder,
      isRequired: true,
      evaluatorSignOffRequired: true,
      supervisorApprovalRequired: false,
      evidenceType: EvidenceType.skillEvaluation,
      repetitionsRequired: 1,
      dueOffsetDays: null,
      prerequisiteRequirementIds: const [],
      tags: const [],
      estimatedMinutes: 15,
      createdAt: now,
      updatedAt: now,
    );
    _db = _db.copyWith(taskBookRequirements: [..._db.taskBookRequirements, req], updatedAt: now);
    await _store.saveDb(_db);
    notifyListeners();
    return req.id;
  }

  Future<void> publishTemplate(String templateId) async {
    final now = DateTime.now();
    final template = _db.taskBookTemplates.firstWhere((t) => t.id == templateId);
    final versions = _db.taskBookVersions.where((v) => v.templateId == templateId).toList();
    if (versions.isEmpty) throw StateError('No versions for template');
    final latest = versions..sort((a, b) => _compareSemver(b.version, a.version));
    final draft = latest.firstWhere((v) => !v.isPublished, orElse: () => latest.first);
    final published = draft.copyWith(isPublished: true, publishedAt: now, updatedAt: now);

    _db = _db.copyWith(
      taskBookTemplates: _db.taskBookTemplates
          .map((t) => t.id == templateId ? t.copyWith(status: TaskBookTemplateStatus.active, updatedAt: now) : t)
          .toList(),
      taskBookVersions: _db.taskBookVersions.map((v) => v.id == published.id ? published : v).toList(),
      updatedAt: now,
    );
    await _store.saveDb(_db);
    notifyListeners();
  }

  Future<String> createDraftFromPublished(String templateId, {String? nextVersion}) async {
    final published = publishedVersionForTemplate(templateId);
    if (published == null) throw StateError('No published version');
    final now = DateTime.now();
    final all = _db.taskBookVersions.where((v) => v.templateId == templateId).toList();
    all.sort((a, b) => _compareSemver(b.version, a.version));
    final latest = all.first;
    final proposed = nextVersion ?? _bumpMinor(latest.version);
    final newVersion = TaskBookVersion(
      id: _id('tbv'),
      templateId: templateId,
      version: proposed,
      isPublished: false,
      publishedAt: DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: now,
      updatedAt: now,
    );

    final oldSections = sectionsForVersion(published.id);
    final sectionIdMap = <String, String>{};
    final newSections = <TaskBookSection>[];
    for (final s in oldSections) {
      final id = _id('sec');
      sectionIdMap[s.id] = id;
      newSections.add(s.copyWith(id: id, versionId: newVersion.id, createdAt: now, updatedAt: now));
    }

    final newRequirements = <TaskBookRequirement>[];
    for (final s in oldSections) {
      final newSecId = sectionIdMap[s.id]!;
      final reqs = requirementsForSection(s.id);
      for (final r in reqs) {
        newRequirements.add(r.copyWith(id: _id('req'), sectionId: newSecId, createdAt: now, updatedAt: now));
      }
    }

    _db = _db.copyWith(
      taskBookVersions: [..._db.taskBookVersions, newVersion],
      taskBookSections: [..._db.taskBookSections, ...newSections],
      taskBookRequirements: [..._db.taskBookRequirements, ...newRequirements],
      updatedAt: now,
    );
    await _store.saveDb(_db);
    notifyListeners();
    return newVersion.id;
  }

  Future<String> assignTaskBook({
    required String templateId,
    required String memberId,
    DateTime? dueDate,
    String? evaluatorId,
    String? supervisorId,
    String? notes,
  }) async {
    final deptId = _activeDepartmentId;
    final assignedBy = _sessionUserId;
    if (deptId == null || assignedBy == null) throw StateError('No active department/session');
    final version = publishedVersionForTemplate(templateId);
    if (version == null) throw StateError('No published version for template');
    final now = DateTime.now();
    final assignment = TaskBookAssignment(
      id: _id('as'),
      departmentId: deptId,
      taskBookVersionId: version.id,
      memberId: memberId,
      assignedBy: assignedBy,
      evaluatorId: evaluatorId ?? assignedBy,
      supervisorId: supervisorId,
      assignedDate: now,
      dueDate: dueDate,
      status: AssignmentStatus.notStarted,
      createdAt: now,
      updatedAt: now,
    );

    // Initialize completions for each requirement in the assigned version.
    final sectionIds = _db.taskBookSections.where((s) => s.versionId == version.id).map((s) => s.id).toSet();
    final reqs = _db.taskBookRequirements.where((r) => sectionIds.contains(r.sectionId)).toList();
    final completions = reqs
        .map(
          (r) => RequirementCompletion(
            id: _id('c'),
            assignmentId: assignment.id,
            requirementId: r.id,
            memberId: memberId,
            status: CompletionStatus.notStarted,
            memberNotes: '',
            submittedAt: null,
            completedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();

    _db = _db.copyWith(
      assignments: [..._db.assignments, assignment],
      completions: [..._db.completions, ...completions],
      updatedAt: now,
    );
    await _store.saveDb(_db);
    notifyListeners();
    return assignment.id;
  }

  Future<void> approveCompletion(String completionId, {required String evaluatorId, String notes = ''}) async {
    final now = DateTime.now();
    final completion = _db.completions.firstWhere((c) => c.id == completionId);
    final updatedCompletion = completion.copyWith(
      status: CompletionStatus.approved,
      completedAt: now,
      updatedAt: now,
    );
    final signOff = SignOff(
      id: _id('so'),
      completionId: completionId,
      evaluatorId: evaluatorId,
      result: SignOffResult.approved,
      notes: notes,
      signedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    _db = _db.copyWith(
      completions: _db.completions.map((c) => c.id == completionId ? updatedCompletion : c).toList(),
      signOffs: [..._db.signOffs, signOff],
      updatedAt: now,
    );
    await _store.saveDb(_db);
    notifyListeners();
  }

  Future<void> returnCompletion(String completionId, {required String evaluatorId, String notes = ''}) async {
    final now = DateTime.now();
    final completion = _db.completions.firstWhere((c) => c.id == completionId);
    final updatedCompletion = completion.copyWith(
      status: CompletionStatus.returned,
      updatedAt: now,
    );
    final signOff = SignOff(
      id: _id('so'),
      completionId: completionId,
      evaluatorId: evaluatorId,
      result: SignOffResult.returned,
      notes: notes,
      signedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    _db = _db.copyWith(
      completions: _db.completions.map((c) => c.id == completionId ? updatedCompletion : c).toList(),
      signOffs: [..._db.signOffs, signOff],
      updatedAt: now,
    );
    await _store.saveDb(_db);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  String _id(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  int _compareSemver(String a, String b) {
    List<int> parse(String v) => v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pa = parse(a);
    final pb = parse(b);
    for (var i = 0; i < max(pa.length, pb.length); i++) {
      final ai = i < pa.length ? pa[i] : 0;
      final bi = i < pb.length ? pb[i] : 0;
      if (ai != bi) return ai.compareTo(bi);
    }
    return 0;
  }

  String _bumpMinor(String v) {
    final parts = v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final major = parts.isNotEmpty ? parts[0] : 1;
    final minor = parts.length > 1 ? parts[1] : 0;
    return '$major.${minor + 1}';
  }
}

extension ListFirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
