import 'package:flutter/foundation.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/models/custom_task_book.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/services/local_store.dart';
import 'package:firepath/services/task_book_store.dart';

/// Owns roadmap overrides, custom requirements, and task book progress.
class TaskBookController extends ChangeNotifier {
  TaskBookController({LocalStore? store, TaskBookStore? taskBookStore})
      : _store = store ?? LocalStore(),
        _taskBookStore = taskBookStore ?? TaskBookStore();

  final LocalStore _store;
  final TaskBookStore _taskBookStore;

  final List<Requirement> _customRequirements = <Requirement>[];
  final List<PathRequirementOverride> _overrides = <PathRequirementOverride>[];

  final List<CustomTaskBook> _customTaskBooks = <CustomTaskBook>[];
  String? _activeTaskBookId; // null => Career Road Task Book

  final Map<String, TaskBookTaskProgress> _taskProgressByKey = <String, TaskBookTaskProgress>{};
  final List<TaskBookTaskDefinition> _customTasks = <TaskBookTaskDefinition>[];

  List<Requirement> get customRequirements => List.unmodifiable(_customRequirements);
  List<PathRequirementOverride> get pathOverrides => List.unmodifiable(_overrides);
  Map<String, TaskBookTaskProgress> get taskBookProgressByKey => Map.unmodifiable(_taskProgressByKey);
  List<TaskBookTaskDefinition> get taskBookCustomTasks => List.unmodifiable(_customTasks);

  List<CustomTaskBook> get customTaskBooks => List.unmodifiable(_customTaskBooks);
  String? get activeTaskBookId => _activeTaskBookId;
  CustomTaskBook? get activeCustomTaskBook => _activeTaskBookId == null
      ? null
      : _customTaskBooks.where((b) => b.id == _activeTaskBookId).firstOrNull;

  Future<void> bootstrap() async {
    final reqJsonList = await _store.loadCustomRequirements();
    _customRequirements
      ..clear()
      ..addAll(reqJsonList.map((e) {
        try {
          return Requirement.fromJson(e);
        } catch (_) {
          return null;
        }
      }).whereType<Requirement>());

    final overridesJson = await _store.loadPathOverrides();
    _overrides
      ..clear()
      ..addAll(overridesJson
          .map((e) {
            try {
              return PathRequirementOverride.fromJson(e);
            } catch (_) {
              return null;
            }
          })
          .whereType<PathRequirementOverride>()
          .where((o) => o.goalId.isNotEmpty && o.requirementId.isNotEmpty));

    _taskProgressByKey
      ..clear()
      ..addAll(await _taskBookStore.loadProgress());
    _customTasks
      ..clear()
      ..addAll(await _taskBookStore.loadCustomTasks());

    await _loadCustomTaskBooks();

    await _persist();
  }

  Future<void> _loadCustomTaskBooks() async {
    try {
      final raw = await _store.loadTaskBookCustomBooks();
      final books = raw.map((e) {
        try {
          return CustomTaskBook.fromJson(e);
        } catch (_) {
          return null;
        }
      }).whereType<CustomTaskBook>().where((b) => b.id.trim().isNotEmpty).toList();

      _customTaskBooks
        ..clear()
        ..addAll(books);

      final active = await _store.loadTaskBookActiveBook();
      final id = active?['activeTaskBookId'] as String?;
      if (id != null && id.trim().isNotEmpty && _customTaskBooks.any((b) => b.id == id)) {
        _activeTaskBookId = id;
      } else {
        _activeTaskBookId = null;
      }
    } catch (e) {
      debugPrint('TaskBookController._loadCustomTaskBooks failed: $e');
      _customTaskBooks.clear();
      _activeTaskBookId = null;
    }
  }

  Future<void> setActiveTaskBook(String? taskBookId) async {
    if (taskBookId != null && !_customTaskBooks.any((b) => b.id == taskBookId)) return;
    _activeTaskBookId = taskBookId;
    await _persist();
    notifyListeners();
  }

  /// Removes stale per-requirement overrides for a goal when the underlying
  /// requirement set changes (e.g., after a state change rebuild).
  ///
  /// This does NOT delete custom/department requirements themselves; it only
  /// prunes overrides that point at requirements that no longer exist.
  Future<void> pruneOverridesForGoal({required String goalId, required Set<String> keepRequirementIds}) async {
    final before = _overrides.length;
    _overrides.removeWhere((o) => o.goalId == goalId && !keepRequirementIds.contains(o.requirementId));
    if (_overrides.length == before) return;
    await _persist();
    notifyListeners();
  }

  Future<CustomTaskBook> createCustomTaskBook({
    required String name,
    required bool departmentSpecific,
    required String? linkedGoalId,
    required List<Requirement> requirements,
  }) async {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final book = CustomTaskBook(
      id: id,
      name: name.trim().isEmpty ? 'Custom Task Book' : name.trim(),
      departmentSpecific: departmentSpecific,
      linkedGoalId: linkedGoalId,
      archived: false,
      requirements: requirements,
      createdAt: now,
      updatedAt: now,
    );
    _customTaskBooks.add(book);
    _activeTaskBookId = book.id;
    await _persist();
    notifyListeners();
    return book;
  }

  Future<void> updateCustomTaskBook(CustomTaskBook book) async {
    final idx = _customTaskBooks.indexWhere((b) => b.id == book.id);
    if (idx < 0) return;
    _customTaskBooks[idx] = book.copyWith(updatedAt: DateTime.now());
    await _persist();
    notifyListeners();
  }

  Future<void> renameCustomTaskBook({required String taskBookId, required String name}) async {
    final idx = _customTaskBooks.indexWhere((b) => b.id == taskBookId);
    if (idx < 0) return;
    _customTaskBooks[idx] = _customTaskBooks[idx].copyWith(name: name.trim(), updatedAt: DateTime.now());
    await _persist();
    notifyListeners();
  }

  Future<void> archiveCustomTaskBook({required String taskBookId, required bool archived}) async {
    final idx = _customTaskBooks.indexWhere((b) => b.id == taskBookId);
    if (idx < 0) return;
    _customTaskBooks[idx] = _customTaskBooks[idx].copyWith(archived: archived, updatedAt: DateTime.now());
    if (archived && _activeTaskBookId == taskBookId) {
      _activeTaskBookId = null;
    }
    await _persist();
    notifyListeners();
  }

  Future<CustomTaskBook?> duplicateCustomTaskBook(String taskBookId) async {
    final src = _customTaskBooks.where((b) => b.id == taskBookId).firstOrNull;
    if (src == null) return null;
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final copy = CustomTaskBook(
      id: id,
      name: '${src.name} (Copy)',
      departmentSpecific: src.departmentSpecific,
      linkedGoalId: src.linkedGoalId,
      archived: false,
      requirements: [...src.requirements],
      createdAt: now,
      updatedAt: now,
    );
    _customTaskBooks.add(copy);
    _activeTaskBookId = copy.id;
    await _persist();
    notifyListeners();
    return copy;
  }

  PathRequirementOverride? getOverride(String goalId, String requirementId) =>
      _overrides.where((o) => o.goalId == goalId && o.requirementId == requirementId).firstOrNull;

  RequirementActivityStatus activityStatusFor({required String goalId, required String requirementId}) =>
      getOverride(goalId, requirementId)?.activityStatus ?? RequirementActivityStatus.notStarted;

  TrainingSchedule? scheduleFor({required String goalId, required String requirementId}) =>
      getOverride(goalId, requirementId)?.schedule;

  (int completed, int total)? taskBookProgressFor({required String goalId, required String requirementId}) {
    final o = getOverride(goalId, requirementId);
    final c = o?.taskBookCompletedItems;
    final t = o?.taskBookTotalItems;
    if (c == null || t == null || t <= 0) return null;
    return (c, t);
  }

  List<ResourceLink> userResourceLinksFor({required String goalId, required String requirementId}) =>
      getOverride(goalId, requirementId)?.userResourceLinks ?? const <ResourceLink>[];

  List<RequirementPlanStep> planStepsFor({required String goalId, required String requirementId}) =>
      getOverride(goalId, requirementId)?.planSteps ?? const <RequirementPlanStep>[];

  List<RequirementSubTask> subTasksFor({required String goalId, required String requirementId}) =>
      getOverride(goalId, requirementId)?.subTasks ?? const <RequirementSubTask>[];

  PathRequirementOverride _ensureOverride(String goalId, String requirementId) {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) return _overrides[idx];
    final created = PathRequirementOverride(
      goalId: goalId,
      requirementId: requirementId,
      excluded: false,
      completed: null,
      overrideExperienceValue: null,
      overrideProgressCurrent: null,
      overrideProgressRequired: null,
      overrideProgressUnit: null,
      activityStatus: null,
      schedule: null,
      taskBookCompletedItems: null,
      taskBookTotalItems: null,
      suggestedStartDate: null,
      suggestedCompletionDate: null,
      removedFromTimeline: false,
      userResourceLinks: const [],
      planSteps: const [],
      subTasks: const [],
    );
    _overrides.add(created);
    return created;
  }

  Future<void> addUserResourceLink({required String goalId, required String requirementId, required ResourceLink link}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      final next = [..._overrides[idx].userResourceLinks, link];
      _overrides[idx] = _overrides[idx].copyWith(userResourceLinks: next);
    } else {
      _overrides.add(PathRequirementOverride(
        goalId: goalId,
        requirementId: requirementId,
        excluded: false,
        completed: null,
        overrideExperienceValue: null,
        overrideProgressCurrent: null,
        overrideProgressRequired: null,
        overrideProgressUnit: null,
        activityStatus: null,
        schedule: null,
        taskBookCompletedItems: null,
        taskBookTotalItems: null,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        removedFromTimeline: false,
        userResourceLinks: [link],
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> upsertPlanStep({
    required String goalId,
    required String requirementId,
    required RequirementPlanStep step,
  }) async {
    final o = _ensureOverride(goalId, requirementId);
    final idx = o.planSteps.indexWhere((e) => e.id == step.id);
    final next = [...o.planSteps];
    if (idx >= 0) {
      next[idx] = step;
    } else {
      next.add(step);
    }
    _setOverride(goalId, requirementId, o.copyWith(planSteps: next));
    await _persist();
    notifyListeners();
  }

  Future<void> setPlanStepDone({
    required String goalId,
    required String requirementId,
    required String stepId,
    required bool done,
  }) async {
    final o = _ensureOverride(goalId, requirementId);
    final idx = o.planSteps.indexWhere((e) => e.id == stepId);
    if (idx < 0) return;
    final next = [...o.planSteps];
    next[idx] = next[idx].copyWith(isDone: done);
    _setOverride(goalId, requirementId, o.copyWith(planSteps: next));
    await _persist();
    notifyListeners();
  }

  Future<void> deletePlanStep({
    required String goalId,
    required String requirementId,
    required String stepId,
  }) async {
    final o = _ensureOverride(goalId, requirementId);
    final next = o.planSteps.where((e) => e.id != stepId).toList();
    _setOverride(goalId, requirementId, o.copyWith(planSteps: next));
    await _persist();
    notifyListeners();
  }

  Future<void> reorderPlanSteps({
    required String goalId,
    required String requirementId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final o = _ensureOverride(goalId, requirementId);
    final list = [...o.planSteps];
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _setOverride(goalId, requirementId, o.copyWith(planSteps: list));
    await _persist();
    notifyListeners();
  }

  Future<void> upsertSubTask({
    required String goalId,
    required String requirementId,
    required RequirementSubTask subTask,
  }) async {
    final o = _ensureOverride(goalId, requirementId);
    final idx = o.subTasks.indexWhere((e) => e.id == subTask.id);
    final next = [...o.subTasks];
    if (idx >= 0) {
      next[idx] = subTask;
    } else {
      next.add(subTask);
    }
    _setOverride(goalId, requirementId, o.copyWith(subTasks: next));
    await _persist();
    notifyListeners();
  }

  Future<void> setSubTaskDone({
    required String goalId,
    required String requirementId,
    required String subTaskId,
    required bool done,
  }) async {
    final o = _ensureOverride(goalId, requirementId);
    final idx = o.subTasks.indexWhere((e) => e.id == subTaskId);
    if (idx < 0) return;
    final next = [...o.subTasks];
    next[idx] = next[idx].copyWith(isDone: done);
    _setOverride(goalId, requirementId, o.copyWith(subTasks: next));
    await _persist();
    notifyListeners();
  }

  Future<void> deleteSubTask({
    required String goalId,
    required String requirementId,
    required String subTaskId,
  }) async {
    final o = _ensureOverride(goalId, requirementId);
    final next = o.subTasks.where((e) => e.id != subTaskId).toList();
    _setOverride(goalId, requirementId, o.copyWith(subTasks: next));
    await _persist();
    notifyListeners();
  }

  void _setOverride(String goalId, String requirementId, PathRequirementOverride next) {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = next;
    } else {
      _overrides.add(next);
    }
  }

  Future<void> setRequirementActivityStatus({required String goalId, required String requirementId, required RequirementActivityStatus status}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(activityStatus: status);
    } else {
      _overrides.add(PathRequirementOverride(
        goalId: goalId,
        requirementId: requirementId,
        excluded: false,
        completed: null,
        overrideExperienceValue: null,
        overrideProgressCurrent: null,
        overrideProgressRequired: null,
        overrideProgressUnit: null,
        activityStatus: status,
        schedule: null,
        taskBookCompletedItems: null,
        taskBookTotalItems: null,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        removedFromTimeline: false,
        userResourceLinks: const [],
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setRequirementSchedule({required String goalId, required String requirementId, required TrainingSchedule? schedule}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(schedule: schedule, clearSchedule: schedule == null);
    } else {
      _overrides.add(PathRequirementOverride(
        goalId: goalId,
        requirementId: requirementId,
        excluded: false,
        completed: null,
        overrideExperienceValue: null,
        overrideProgressCurrent: null,
        overrideProgressRequired: null,
        overrideProgressUnit: null,
        activityStatus: null,
        schedule: schedule,
        taskBookCompletedItems: null,
        taskBookTotalItems: null,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        removedFromTimeline: false,
        userResourceLinks: const [],
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setTaskBookProgress({required String goalId, required String requirementId, required int completedItems, required int totalItems}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(taskBookCompletedItems: completedItems, taskBookTotalItems: totalItems);
    } else {
      _overrides.add(PathRequirementOverride(
        goalId: goalId,
        requirementId: requirementId,
        excluded: false,
        completed: null,
        overrideExperienceValue: null,
        overrideProgressCurrent: null,
        overrideProgressRequired: null,
        overrideProgressUnit: null,
        activityStatus: null,
        schedule: null,
        taskBookCompletedItems: completedItems,
        taskBookTotalItems: totalItems,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        removedFromTimeline: false,
        userResourceLinks: const [],
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setRequirementExcluded({required String goalId, required String requirementId, required bool excluded}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(excluded: excluded);
    } else {
      _overrides.add(PathRequirementOverride(
        goalId: goalId,
        requirementId: requirementId,
        excluded: excluded,
        completed: null,
        overrideExperienceValue: null,
        overrideProgressCurrent: null,
        overrideProgressRequired: null,
        overrideProgressUnit: null,
        activityStatus: null,
        schedule: null,
        taskBookCompletedItems: null,
        taskBookTotalItems: null,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        removedFromTimeline: false,
        userResourceLinks: const [],
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setExperienceMinimum({required String goalId, required String requirementId, required double years}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(overrideExperienceValue: years);
    } else {
      _overrides.add(PathRequirementOverride(
        goalId: goalId,
        requirementId: requirementId,
        excluded: false,
        completed: null,
        overrideExperienceValue: years,
        overrideProgressCurrent: null,
        overrideProgressRequired: null,
        overrideProgressUnit: null,
        activityStatus: null,
        schedule: null,
        taskBookCompletedItems: null,
        taskBookTotalItems: null,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        removedFromTimeline: false,
        userResourceLinks: const [],
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setNumericRequired({required String goalId, required String requirementId, required double requiredValue}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(overrideProgressRequired: requiredValue);
    } else {
      _overrides.add(PathRequirementOverride(
        goalId: goalId,
        requirementId: requirementId,
        excluded: false,
        completed: null,
        overrideExperienceValue: null,
        overrideProgressCurrent: null,
        overrideProgressRequired: requiredValue,
        overrideProgressUnit: null,
        activityStatus: null,
        schedule: null,
        taskBookCompletedItems: null,
        taskBookTotalItems: null,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        removedFromTimeline: false,
        userResourceLinks: const [],
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setRequirementCompleted({required String goalId, required String requirementId, required bool completed}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(completed: completed);
    } else {
      _overrides.add(PathRequirementOverride(
        goalId: goalId,
        requirementId: requirementId,
        excluded: false,
        completed: completed,
        overrideExperienceValue: null,
        overrideProgressCurrent: null,
        overrideProgressRequired: null,
        overrideProgressUnit: null,
        activityStatus: null,
        schedule: null,
        taskBookCompletedItems: null,
        taskBookTotalItems: null,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        removedFromTimeline: false,
        userResourceLinks: const [],
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setNumericProgress({required String goalId, required String requirementId, required double current, required double required, String? unit}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(
        overrideProgressCurrent: current,
        overrideProgressRequired: required,
        overrideProgressUnit: unit,
      );
    } else {
      _overrides.add(PathRequirementOverride(
        goalId: goalId,
        requirementId: requirementId,
        excluded: false,
        completed: null,
        overrideExperienceValue: null,
        overrideProgressCurrent: current,
        overrideProgressRequired: required,
        overrideProgressUnit: unit,
        activityStatus: null,
        schedule: null,
        taskBookCompletedItems: null,
        taskBookTotalItems: null,
        suggestedStartDate: null,
        suggestedCompletionDate: null,
        removedFromTimeline: false,
        userResourceLinks: const [],
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> moveTimelineEarlier({required String goalId, required String requirementId}) async {
    final now = DateTime.now();
    final existing = getOverride(goalId, requirementId);
    final base = existing?.suggestedStartDate ?? existing?.schedule?.startDate ?? now;
    final shifted = base.subtract(const Duration(days: 90));
    await _setTimelineOverride(goalId: goalId, requirementId: requirementId, suggestedStartDate: DateTime(shifted.year, shifted.month, 1), removed: false);
  }

  Future<void> moveTimelineLater({required String goalId, required String requirementId}) async {
    final now = DateTime.now();
    final existing = getOverride(goalId, requirementId);
    final base = existing?.suggestedStartDate ?? existing?.schedule?.startDate ?? now;
    final shifted = base.add(const Duration(days: 90));
    await _setTimelineOverride(goalId: goalId, requirementId: requirementId, suggestedStartDate: DateTime(shifted.year, shifted.month, 1), removed: false);
  }

  Future<void> removeFromTimeline({required String goalId, required String requirementId}) async {
    await _setTimelineOverride(goalId: goalId, requirementId: requirementId, suggestedStartDate: null, removed: true, clearSuggestedDates: true);
  }

  Future<void> clearTimelineOverride({required String goalId, required String requirementId}) async {
    await _setTimelineOverride(goalId: goalId, requirementId: requirementId, suggestedStartDate: null, removed: false, clearSuggestedDates: true);
  }

  Future<void> _setTimelineOverride({required String goalId, required String requirementId, required DateTime? suggestedStartDate, required bool removed, bool clearSuggestedDates = false}) async {
    final idx = _overrides.indexWhere((o) => o.goalId == goalId && o.requirementId == requirementId);
    if (idx >= 0) {
      _overrides[idx] = _overrides[idx].copyWith(
        suggestedStartDate: suggestedStartDate,
        removedFromTimeline: removed,
        clearSuggestedDates: clearSuggestedDates,
      );
    } else {
      _overrides.add(PathRequirementOverride(
        goalId: goalId,
        requirementId: requirementId,
        excluded: false,
        completed: null,
        overrideExperienceValue: null,
        overrideProgressCurrent: null,
        overrideProgressRequired: null,
        overrideProgressUnit: null,
        activityStatus: null,
        schedule: null,
        taskBookCompletedItems: null,
        taskBookTotalItems: null,
        suggestedStartDate: suggestedStartDate,
        suggestedCompletionDate: null,
        removedFromTimeline: removed,
        userResourceLinks: const [],
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> addDepartmentRequirement({required String goalId, required Requirement requirement}) async {
    final now = DateTime.now();
    final saved = requirement.copyWith(updatedAt: now);
    _customRequirements.add(saved);
    await _persist();
    notifyListeners();
  }

  Future<void> updateCustomRequirement(Requirement requirement) async {
    final idx = _customRequirements.indexWhere((e) => e.id == requirement.id);
    if (idx < 0) return;
    _customRequirements[idx] = requirement.copyWith(updatedAt: DateTime.now());
    await _persist();
    notifyListeners();
  }

  Future<void> deleteCustomRequirement(String requirementId) async {
    _customRequirements.removeWhere((e) => e.id == requirementId);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleCustomRequirementComplete(String requirementId, bool complete) async {
    final idx = _customRequirements.indexWhere((e) => e.id == requirementId);
    if (idx < 0) return;
    _customRequirements[idx] = _customRequirements[idx].copyWith(completed: complete, updatedAt: DateTime.now());
    await _persist();
    notifyListeners();
  }

  Future<void> updateNumericProgress(String requirementId, {required double current, required double required}) async {
    final idx = _customRequirements.indexWhere((e) => e.id == requirementId);
    if (idx < 0) return;
    _customRequirements[idx] = _customRequirements[idx].copyWith(
      progressCurrent: current,
      progressRequired: required,
      updatedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  TaskBookTaskProgress? taskProgressFor({required String goalId, required String requirementId, required String taskId}) =>
      _taskProgressByKey[TaskBookStore.progressKey(goalId: goalId, requirementId: requirementId, taskId: taskId)];

  TaskBookTaskStatus taskStatusFor({required String goalId, required String requirementId, required String taskId}) =>
      taskProgressFor(goalId: goalId, requirementId: requirementId, taskId: taskId)?.status ?? TaskBookTaskStatus.notStarted;

  Future<void> setTaskStatus({required String goalId, required String requirementId, required String taskId, required TaskBookTaskStatus status, TaskBookCompletionSource? completionSource}) async {
    final now = DateTime.now();
    final key = TaskBookStore.progressKey(goalId: goalId, requirementId: requirementId, taskId: taskId);
    final existing = _taskProgressByKey[key];
    final completedAt = status == TaskBookTaskStatus.complete ? now : null;
    if (existing == null) {
      _taskProgressByKey[key] = TaskBookTaskProgress(
        goalId: goalId,
        requirementId: requirementId,
        taskId: taskId,
        status: status,
        completionSource: completionSource,
        completedAt: completedAt,
        createdAt: now,
        updatedAt: now,
      );
    } else {
      _taskProgressByKey[key] = existing.copyWith(
        status: status,
        completionSource: completionSource,
        completedAt: completedAt,
        updatedAt: now,
      );
    }
    await _persist();
    notifyListeners();
  }

  List<TaskBookTaskDefinition> customTasksFor({required String goalId, required String requirementId}) =>
      _customTasks.where((t) => (t.goalId ?? '').trim() == goalId && (t.requirementId ?? '').trim() == requirementId).toList();

  Future<void> addCustomTask(TaskBookTaskDefinition task) async {
    if (!task.isCustom) {
      debugPrint('TaskBookController.addCustomTask called with non-custom task id=${task.id}');
      return;
    }
    if ((task.goalId ?? '').trim().isEmpty || (task.requirementId ?? '').trim().isEmpty || task.id.trim().isEmpty) {
      debugPrint('TaskBookController.addCustomTask invalid scope/id');
      return;
    }
    _customTasks.add(task);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteCustomTask({required String goalId, required String requirementId, required String taskId}) async {
    _customTasks.removeWhere((t) => t.isCustom && t.goalId == goalId && t.requirementId == requirementId && t.id == taskId);

    final key = TaskBookStore.progressKey(goalId: goalId, requirementId: requirementId, taskId: taskId);
    _taskProgressByKey.remove(key);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.saveCustomRequirements(_customRequirements.map((e) => e.toJson()).toList());
    await _store.savePathOverrides(_overrides.map((e) => e.toJson()).toList());
    await _taskBookStore.saveProgress(_taskProgressByKey);
    await _taskBookStore.saveCustomTasks(_customTasks);

    final okBooks = await _store.saveTaskBookCustomBooks(
      _customTaskBooks.map((e) => e.toJson()).toList(),
    );
    if (!okBooks) {
      debugPrint('TaskBookController: failed to persist custom task books');
    }

    final okActive = await _store.saveTaskBookActiveBook({
      'activeTaskBookId': _activeTaskBookId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    if (!okActive) {
      debugPrint('TaskBookController: failed to persist active task book');
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
