import 'package:flutter/foundation.dart';

import 'package:firepath/controllers/career_record_controller.dart';
import 'package:firepath/controllers/certification_controller.dart';
import 'package:firepath/controllers/profile_controller.dart';
import 'package:firepath/controllers/task_book_controller.dart';
import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/local_store.dart';
import 'package:firepath/services/timeline_planner.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/models/custom_task_book.dart';
import 'package:firepath/services/task_book_setup_store.dart';

export 'package:firepath/models/roadmap_models.dart';

class AppState extends ChangeNotifier {
  AppState()
      : profileController = ProfileController(),
        certificationController = CertificationController(),
        taskBookController = TaskBookController(),
        careerRecordController = CareerRecordController() {
    profileController.addListener(_forwardChildChange);
    certificationController.addListener(_forwardChildChange);
    taskBookController.addListener(_forwardChildChange);
    careerRecordController.addListener(_forwardChildChange);
  }

  final LocalStore _store = LocalStore();

  final ProfileController profileController;
  final CertificationController certificationController;
  final TaskBookController taskBookController;
  final CareerRecordController careerRecordController;

  bool _bootstrapped = false;
  bool _disposed = false;

  void _forwardChildChange() {
    if (_disposed) return;
    notifyListeners();
  }

  bool get bootstrapped => _bootstrapped;
  bool get onboardingComplete => profileController.onboardingComplete;
  UserProfile get profile => profileController.profile;
  List<Certification> get certifications => certificationController.certifications;
  List<PendingCertMatch> get pendingCertMatches => certificationController.pendingCertMatches;
  List<Requirement> get customRequirements => taskBookController.customRequirements;
  List<PathRequirementOverride> get pathOverrides => taskBookController.pathOverrides;
  Map<String, TaskBookTaskProgress> get taskBookProgressByKey => taskBookController.taskBookProgressByKey;
  List<TaskBookTaskDefinition> get taskBookCustomTasks => taskBookController.taskBookCustomTasks;
  List<CustomTaskBook> get customTaskBooks => taskBookController.customTaskBooks;
  String? get activeTaskBookId => taskBookController.activeTaskBookId;
  CustomTaskBook? get activeCustomTaskBook => taskBookController.activeCustomTaskBook;

  List<CareerGoal> get availableGoals => profileController.availableGoals;
  CareerGoal? get selectedGoal {
    return profileController.selectedGoalResolved();
  }

  Roadmap? get roadmap {
    final goal = selectedGoal;
    if (goal == null) return null;

    // Certification completion should consider expired credentials as NOT complete.
    final certStatusByDefId = <String, CertificationStatus>{};
    for (final c in certifications) {
      final defId = c.certificationDefinitionId;
      if (defId == null || defId.isEmpty) continue;
      final current = certStatusByDefId[defId];
      // Prefer the "best" status.
      final next = c.status;
      if (current == null) {
        certStatusByDefId[defId] = next;
        continue;
      }
      // current beats expiringSoon beats expired
      int rank(CertificationStatus s) => switch (s) {
            CertificationStatus.current => 0,
            CertificationStatus.expiringSoon => 1,
            CertificationStatus.expired => 2,
          };
      if (rank(next) < rank(current)) certStatusByDefId[defId] = next;
    }
    final goalCustom = customRequirements
        .where((r) => r.id.startsWith('${goal.id}::'))
        .toList();
    final allReqsRaw = [...goal.requirements, ...goalCustom];

    final overrideByReqId = {
      for (final o in pathOverrides
          .where((o) => o.goalId == goal.id && o.requirementId.isNotEmpty))
        o.requirementId: o,
    };

    final allReqs = allReqsRaw.map((r) {
      final o = overrideByReqId[r.id];
      if (o == null) return r;
      return r.copyWith(
        completed: o.completed ?? r.completed,
        experienceValue: o.overrideExperienceValue,
        progressCurrent: o.overrideProgressCurrent,
        progressRequired: o.overrideProgressRequired,
        progressUnit: o.overrideProgressUnit,
        updatedAt: DateTime.now(),
      );
    }).toList();

    bool completeFor(Requirement r) {
      if (r.type == RequirementType.certification) {
        final defId = r.certificationDefinitionId;
        if (defId == null || defId.isEmpty) return false;
        final status = certStatusByDefId[defId];
        if (status == null) return false;
        if (status == CertificationStatus.expired)
          return r.allowExpiredCertification;
        return true;
      }
      if (r.type == RequirementType.experience) {
        final required = r.experienceValue;
        if (required == null) return false;
        final years = profile.yearsOfService;
        if (years == null) return false;
        return years.toDouble() >= required;
      }
      if (r.type == RequirementType.numericProgress) {
        if (r.progressCurrent == null || r.progressRequired == null)
          return false;
        return r.progressCurrent! >= r.progressRequired!;
      }
      return r.completed;
    }

    bool excludedFor(Requirement r) {
      final o = overrideByReqId[r.id];
      return o?.excluded ?? false;
    }

    final items = allReqs
        .map((r) => RoadmapRequirement(
            requirement: r,
            isComplete: completeFor(r),
            isExcluded: excludedFor(r)))
        .toList();
    items.sort(
        (a, b) => a.requirement.sortOrder.compareTo(b.requirement.sortOrder));
    return Roadmap(goal: goal, all: items);
  }

  Future<void> bootstrap() async {
    try {
      await profileController.bootstrap();

      // Keep a record for state-change detection prompts.
      // (Preserved behavior; the controller also attempts this, but we keep this
      // as a belt-and-suspenders guard for legacy devices.)
      try {
        final setup = TaskBookSetupStore();
        final last = await setup.lastKnownState();
        final normalizedState =
            FireOpsCatalog.stateCodeFromLegacyValue(profile.state);
        if ((last ?? '').trim().isEmpty && (normalizedState ?? '').trim().isNotEmpty) {
          await setup.setLastKnownState(normalizedState);
        }
      } catch (e) {
        debugPrint('AppState.bootstrap lastKnownState init failed: $e');
      }

      await certificationController.bootstrap();

      assert(() {
        FireOpsCatalog.validateCatalog();
        return true;
      }());

      await taskBookController.bootstrap();

      // Sanitize writes back to prevent repeated decode problems.
      await _persistAll();
    } catch (e) {
      debugPrint('AppState.bootstrap failed: $e');
    } finally {
      _bootstrapped = true;
      notifyListeners();
    }
  }

  /// Permanently clears local app data and returns this live state object to
  /// the same condition as a first launch.
  Future<bool> resetApp() async {
    final cleared = await _store.resetAppData();
    if (!cleared) return false;

    await profileController.setOnboardingComplete(false);
    await profileController.setProfile(UserProfile.empty());
    await certificationController.replaceAll(const []);
    await taskBookController.bootstrap();
    _bootstrapped = true;
    notifyListeners();
    return true;
  }

  Future<void> confirmCertificationMatch(
          {required String userText,
          required String suggestedDefinitionId,
          required bool accepted}) =>
      certificationController.confirmMatch(
          userText: userText,
          suggestedDefinitionId: suggestedDefinitionId,
          accepted: accepted);

  String certificationDisplayName(Certification c) =>
      certificationController.displayName(c);

  /// Rebuilds/prunes Task Book bookkeeping after a state change.
  ///
  /// The requirement list itself is derived dynamically from the selected goal
  /// + current profile state + custom/department requirements. This “rebuild”
  /// cleans up stale overrides that reference requirements that no longer
  /// apply under the new state.
  Future<void> rebuildTaskBookForCurrentState() async {
    final r = roadmap;
    if (r == null) return;
    final keep = r.all.map((e) => e.requirement.id).where((e) => e.trim().isNotEmpty).toSet();
    await taskBookController.pruneOverridesForGoal(goalId: r.goal.id, keepRequirementIds: keep);
  }

  void _ensureCustomGoalStarterRequirements(String? goalId) {
    if (goalId == null || !goalId.startsWith('custom:')) return;
    if (customRequirements.any((r) => r.id.startsWith('$goalId::'))) return;

    final now = DateTime.now();
    Requirement starter({
      required String suffix,
      required String name,
      required String category,
      required String description,
      required RequirementPriority priority,
      required int sortOrder,
      TimelineCategory timelineCategory = TimelineCategory.development,
    }) {
      return Requirement(
        id: '$goalId::$suffix',
        name: name,
        category: category,
        priority: priority,
        description: description,
        type: RequirementType.custom,
        requirementSource: RequirementSource.departmentRequirement,
        defaultRequired: true,
        stateDependent: false,
        departmentDependent: true,
        completed: false,
        progressCurrent: null,
        progressRequired: null,
        progressUnit: null,
        experienceValue: null,
        experienceUnit: null,
        certificationReference: null,
        certificationDefinitionId: null,
        allowExpiredCertification: false,
        prerequisiteRequirementIds: const [],
        resourceIds: const [],
        resourceLinks: const [],
        sortOrder: sortOrder,
        estimatedDurationDays: null,
        recommendedLeadTimeDays: null,
        canRunConcurrent: true,
        timelineCategory: timelineCategory,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        createdAt: now,
        updatedAt: now,
      );
    }

    // Fire-and-forget; AppState callers already await persistence actions.
    final starters = <Requirement>[
      starter(
        suffix: 'define_eligibility',
        name: 'Define eligibility requirements',
        category: 'Eligibility',
        description:
            'Confirm the department, agency, state, education, time-in-grade, and prerequisite rules for this goal. Edit this milestone to match your organization.',
        priority: RequirementPriority.core,
        sortOrder: 10,
        timelineCategory: TimelineCategory.departmentRequirement,
      ),
      starter(
        suffix: 'build_qualifications',
        name: 'Build required qualifications',
        category: 'Qualifications',
        description:
            'Add the certifications, courses, task books, and qualifications that make you eligible and competitive for this goal.',
        priority: RequirementPriority.core,
        sortOrder: 20,
        timelineCategory: TimelineCategory.certification,
      ),
      starter(
        suffix: 'document_experience',
        name: 'Document relevant experience and evidence',
        category: 'Experience',
        description:
            'Capture assignments, leadership examples, projects, incidents, teaching, and other evidence you may need years later.',
        priority: RequirementPriority.recommended,
        sortOrder: 30,
        timelineCategory: TimelineCategory.experience,
      ),
      starter(
        suffix: 'prepare_selection',
        name: 'Prepare for the selection or promotion process',
        category: 'Promotion Prep',
        description:
            'Add the written exam, assessment center, interview, resume, portfolio, or other selection steps used for this goal.',
        priority: RequirementPriority.recommended,
        sortOrder: 40,
        timelineCategory: TimelineCategory.promotionalPreparation,
      ),
    ];

    for (final r in starters) {
      // Intentionally not awaited to avoid turning this helper into async.
      taskBookController.addDepartmentRequirement(goalId: goalId, requirement: r);
    }
  }

  Future<void> completeOnboarding(
      {required UserProfile profile,
      required List<Certification> certifications}) async {
    await profileController.setProfile(profile);
    await certificationController.replaceAll(
      certifications
          .where((c) => c.name.trim().isNotEmpty)
          .map((c) {
            final mapped = c.certificationDefinitionId == null
                ? FireOpsCatalog.matchCertificationDefinitionId(c.name)
                : c.certificationDefinitionId;
            return c.copyWith(
                certificationDefinitionId: mapped, updatedAt: DateTime.now());
          })
          .toList(),
    );
    await profileController.setOnboardingComplete(true);
    _ensureCustomGoalStarterRequirements(profileController.profile.primaryGoalId);
    await _persistAll();
  }

  Future<void> setPrimaryGoal(String goalId) async {
    await profileController.setPrimaryGoal(goalId);
    _ensureCustomGoalStarterRequirements(goalId);
    await _persistAll();
  }

  Future<void> setTargetReadyDate(DateTime? targetDate) async {
    await profileController.setTargetReadyDate(targetDate);
    await _persistAll();
  }

  Future<void> updateProfile(UserProfile profile) async {
    await profileController.updateProfile(profile);
    await _persistAll();
  }

  Future<void> setCurrentRoles(List<String> roles) async {
    await profileController.setCurrentRoles(roles);
    await _persistAll();
  }

  Certification? getCertificationById(String id) =>
      certificationController.getById(id);

  Future<void> upsertCertification(Certification cert) async {
    await certificationController.upsert(cert);
    await _persistAll();
  }

  Future<void> deleteCertification(String id) async {
    await certificationController.delete(id);
    await _persistAll();
  }

  Future<void> addDepartmentRequirement(
      {required String goalId, required Requirement requirement}) async {
    await taskBookController.addDepartmentRequirement(
        goalId: goalId, requirement: requirement);
    await _persistAll();
  }

  Future<void> updateCustomRequirement(Requirement requirement) async {
    await taskBookController.updateCustomRequirement(requirement);
    await _persistAll();
  }

  Future<void> deleteCustomRequirement(String requirementId) async {
    await taskBookController.deleteCustomRequirement(requirementId);
    await _persistAll();
  }

  PathRequirementOverride? getOverride(String goalId, String requirementId) {
    return taskBookController.getOverride(goalId, requirementId);
  }

  RequirementActivityStatus activityStatusFor(
      {required String goalId, required String requirementId}) {
    return taskBookController.activityStatusFor(
        goalId: goalId, requirementId: requirementId);
  }

  TrainingSchedule? scheduleFor(
          {required String goalId, required String requirementId}) =>
      taskBookController.scheduleFor(goalId: goalId, requirementId: requirementId);

  (int completed, int total)? taskBookProgressFor(
      {required String goalId, required String requirementId}) {
    return taskBookController.taskBookProgressFor(
        goalId: goalId, requirementId: requirementId);
  }

  List<ResourceLink> userResourceLinksFor(
          {required String goalId, required String requirementId}) =>
      taskBookController.userResourceLinksFor(
          goalId: goalId, requirementId: requirementId);

  List<RequirementPlanStep> planStepsFor(
          {required String goalId, required String requirementId}) =>
      taskBookController.planStepsFor(goalId: goalId, requirementId: requirementId);

  List<RequirementSubTask> subTasksFor(
          {required String goalId, required String requirementId}) =>
      taskBookController.subTasksFor(goalId: goalId, requirementId: requirementId);

  Future<void> addUserResourceLink(
      {required String goalId,
      required String requirementId,
      required ResourceLink link}) async {
    await taskBookController.addUserResourceLink(
        goalId: goalId, requirementId: requirementId, link: link);
    await _persistAll();
  }

  Future<void> upsertPlanStep({
    required String goalId,
    required String requirementId,
    required RequirementPlanStep step,
  }) async {
    await taskBookController.upsertPlanStep(
      goalId: goalId,
      requirementId: requirementId,
      step: step,
    );
    await _persistAll();
  }

  Future<void> setPlanStepDone({
    required String goalId,
    required String requirementId,
    required String stepId,
    required bool done,
  }) async {
    await taskBookController.setPlanStepDone(
      goalId: goalId,
      requirementId: requirementId,
      stepId: stepId,
      done: done,
    );
    await _persistAll();
  }

  Future<void> deletePlanStep({
    required String goalId,
    required String requirementId,
    required String stepId,
  }) async {
    await taskBookController.deletePlanStep(
      goalId: goalId,
      requirementId: requirementId,
      stepId: stepId,
    );
    await _persistAll();
  }

  Future<void> reorderPlanSteps({
    required String goalId,
    required String requirementId,
    required int oldIndex,
    required int newIndex,
  }) async {
    await taskBookController.reorderPlanSteps(
      goalId: goalId,
      requirementId: requirementId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    await _persistAll();
  }

  Future<void> upsertSubTask({
    required String goalId,
    required String requirementId,
    required RequirementSubTask subTask,
  }) async {
    await taskBookController.upsertSubTask(
      goalId: goalId,
      requirementId: requirementId,
      subTask: subTask,
    );
    await _persistAll();
  }

  Future<void> setSubTaskDone({
    required String goalId,
    required String requirementId,
    required String subTaskId,
    required bool done,
  }) async {
    await taskBookController.setSubTaskDone(
      goalId: goalId,
      requirementId: requirementId,
      subTaskId: subTaskId,
      done: done,
    );
    await _persistAll();
  }

  Future<void> deleteSubTask({
    required String goalId,
    required String requirementId,
    required String subTaskId,
  }) async {
    await taskBookController.deleteSubTask(
      goalId: goalId,
      requirementId: requirementId,
      subTaskId: subTaskId,
    );
    await _persistAll();
  }

  Future<void> setRequirementActivityStatus(
      {required String goalId,
      required String requirementId,
      required RequirementActivityStatus status}) async {
    await taskBookController.setRequirementActivityStatus(
        goalId: goalId, requirementId: requirementId, status: status);
    await _persistAll();
  }

  Future<void> setRequirementSchedule(
      {required String goalId,
      required String requirementId,
      required TrainingSchedule? schedule}) async {
    await taskBookController.setRequirementSchedule(
        goalId: goalId, requirementId: requirementId, schedule: schedule);
    await _persistAll();
  }

  Future<void> setTaskBookProgress(
      {required String goalId,
      required String requirementId,
      required int completedItems,
      required int totalItems}) async {
    await taskBookController.setTaskBookProgress(
        goalId: goalId,
        requirementId: requirementId,
        completedItems: completedItems,
        totalItems: totalItems);
    await _persistAll();
  }

  Future<void> setRequirementExcluded(
      {required String goalId,
      required String requirementId,
      required bool excluded}) async {
    await taskBookController.setRequirementExcluded(
        goalId: goalId, requirementId: requirementId, excluded: excluded);
    await _persistAll();
  }

  Future<void> setExperienceMinimum(
      {required String goalId,
      required String requirementId,
      required double years}) async {
    await taskBookController.setExperienceMinimum(
        goalId: goalId, requirementId: requirementId, years: years);
    await _persistAll();
  }

  Future<void> setNumericRequired(
      {required String goalId,
      required String requirementId,
      required double requiredValue}) async {
    await taskBookController.setNumericRequired(
        goalId: goalId,
        requirementId: requirementId,
        requiredValue: requiredValue);
    await _persistAll();
  }

  Future<void> setRequirementCompleted(
      {required String goalId,
      required String requirementId,
      required bool completed}) async {
    await taskBookController.setRequirementCompleted(
        goalId: goalId, requirementId: requirementId, completed: completed);
    await _persistAll();
  }

  Future<void> setNumericProgress(
      {required String goalId,
      required String requirementId,
      required double current,
      required double required,
      String? unit}) async {
    await taskBookController.setNumericProgress(
        goalId: goalId,
        requirementId: requirementId,
        current: current,
        required: required,
        unit: unit);
    await _persistAll();
  }

  Future<void> moveTimelineEarlier(
      {required String goalId, required String requirementId}) async {
    await taskBookController.moveTimelineEarlier(
        goalId: goalId, requirementId: requirementId);
    await _persistAll();
  }

  Future<void> moveTimelineLater(
      {required String goalId, required String requirementId}) async {
    await taskBookController.moveTimelineLater(
        goalId: goalId, requirementId: requirementId);
    await _persistAll();
  }

  Future<void> removeFromTimeline(
      {required String goalId, required String requirementId}) async {
    await taskBookController.removeFromTimeline(
        goalId: goalId, requirementId: requirementId);
    await _persistAll();
  }

  Future<void> clearTimelineOverride(
      {required String goalId, required String requirementId}) async {
    await taskBookController.clearTimelineOverride(
        goalId: goalId, requirementId: requirementId);
    await _persistAll();
  }

  Future<void> toggleCustomRequirementComplete(
      String requirementId, bool complete) async {
    await taskBookController.toggleCustomRequirementComplete(
        requirementId, complete);
    await _persistAll();
  }

  Future<void> updateNumericProgress(String requirementId,
      {required double current, required double required}) async {
    await taskBookController.updateNumericProgress(requirementId,
        current: current, required: required);
    await _persistAll();
  }

  Future<void> _persistAll() async {
    try {
      final estimated = CareerTimelinePlanner.estimateStatus(this);
      await profileController.setTimelineStatusIfDifferent(estimated);
    } catch (e) {
      debugPrint('Timeline status estimation failed: $e');
    }
    // Domain controllers persist their own sub-stores.
  }

  // --- Task Book API ---

  /// Applies a saved Career Record to linked roadmap progress when it's safe.
  ///
  /// This updates numeric-style requirement progress (hours / repetitions), but
  /// does **not** mark tasks "verified" or auto-complete supervisor-eval work.
  ///
  /// If the record is not linked to the currently active goal, this no-ops.
  Future<void> applyLogToRequirementProgress(CareerRecord record) async {
    final goalId = record.relatedGoalId;
    final requirementId = record.relatedRequirementId;
    if (goalId == null || requirementId == null) return;
    final activeGoal = selectedGoal;
    if (activeGoal == null || activeGoal.id != goalId) return;
    final map = roadmap;
    if (map == null) return;

    final matches = map.all.where((e) => e.requirement.id == requirementId);
    final rr = matches.isEmpty ? null : matches.first;
    if (rr == null) return;
    final req = rr.requirement;

    final delta = record.hours ?? record.repetitions.toDouble();
    if (delta <= 0) return;

    if (req.type == RequirementType.numericProgress ||
        req.type == RequirementType.experience ||
        req.type == RequirementType.taskBook) {
      final current = (req.progressCurrent ?? 0) + delta;
      final required = req.progressRequired ?? 0;
      await setNumericProgress(
        goalId: goalId,
        requirementId: requirementId,
        current: current,
        required: required,
        unit: req.progressUnit,
      );
    }
  }

  TaskBookTaskProgress? taskProgressFor(
          {required String goalId,
          required String requirementId,
          required String taskId}) =>
      taskBookController.taskProgressFor(
          goalId: goalId, requirementId: requirementId, taskId: taskId);

  TaskBookTaskStatus taskStatusFor(
          {required String goalId,
          required String requirementId,
          required String taskId}) =>
      taskBookController.taskStatusFor(
          goalId: goalId, requirementId: requirementId, taskId: taskId);

  Future<void> setTaskStatus({
    required String goalId,
    required String requirementId,
    required String taskId,
    required TaskBookTaskStatus status,
    TaskBookCompletionSource? completionSource,
  }) async {
    await taskBookController.setTaskStatus(
      goalId: goalId,
      requirementId: requirementId,
      taskId: taskId,
      status: status,
      completionSource: completionSource,
    );
    await _persistAll();
  }

  List<TaskBookTaskDefinition> customTasksFor(
          {required String goalId, required String requirementId}) =>
      taskBookController.customTasksFor(goalId: goalId, requirementId: requirementId);

  Future<void> addCustomTask(TaskBookTaskDefinition task) async {
    await taskBookController.addCustomTask(task);
    await _persistAll();
  }

  Future<void> deleteCustomTask(
      {required String goalId,
      required String requirementId,
      required String taskId}) async {
    await taskBookController.deleteCustomTask(
        goalId: goalId, requirementId: requirementId, taskId: taskId);
    await _persistAll();
  }

  @override
  void dispose() {
    _disposed = true;
    profileController.removeListener(_forwardChildChange);
    certificationController.removeListener(_forwardChildChange);
    taskBookController.removeListener(_forwardChildChange);
    careerRecordController.removeListener(_forwardChildChange);
    profileController.dispose();
    certificationController.dispose();
    taskBookController.dispose();
    careerRecordController.dispose();
    super.dispose();
  }
}
