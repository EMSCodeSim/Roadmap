import 'package:flutter/foundation.dart';

import 'package:firepath/models/requirement.dart';

enum TaskBookStage {
  prerequisites,
  coreCertifications,
  requiredCourses,
  experienceHours,
  taskBookSignoffs,
  promotionalPreparation,
  developmentRecommended,
}

class TaskBookStageMeta {
  final TaskBookStage stage;
  final String title;
  final String subtitle;
  final int order;

  const TaskBookStageMeta({required this.stage, required this.title, required this.subtitle, required this.order});
}

class TaskBookStageItem<T> {
  final T raw;
  final Requirement requirement;
  final bool isComplete;
  final int originalIndex;
  final TaskBookStage stage;
  final List<String> unmetPrerequisiteLabels;
  final bool canStartNow;

  const TaskBookStageItem({
    required this.raw,
    required this.requirement,
    required this.isComplete,
    required this.originalIndex,
    required this.stage,
    required this.unmetPrerequisiteLabels,
    required this.canStartNow,
  });
}

class TaskBookStageSection<T> {
  final TaskBookStageMeta meta;
  final List<TaskBookStageItem<T>> items;
  final int completedCount;
  final int totalCount;

  const TaskBookStageSection({required this.meta, required this.items, required this.completedCount, required this.totalCount});
}

class TaskBookStagePlan<T> {
  final List<TaskBookStageSection<T>> sections;
  final TaskBookStageItem<T>? suggestedNext;
  final int completedTotal;
  final int total;

  const TaskBookStagePlan({required this.sections, required this.suggestedNext, required this.completedTotal, required this.total});
}

class TaskBookStagePlanner {
  static const List<TaskBookStageMeta> _meta = [
    TaskBookStageMeta(stage: TaskBookStage.prerequisites, title: 'Prerequisites', subtitle: 'Get these in place first', order: 10),
    TaskBookStageMeta(stage: TaskBookStage.coreCertifications, title: 'Core Certifications', subtitle: 'Key credentials for readiness', order: 20),
    TaskBookStageMeta(stage: TaskBookStage.requiredCourses, title: 'Required Courses / Training', subtitle: 'Classes, academies, and training blocks', order: 30),
    TaskBookStageMeta(stage: TaskBookStage.experienceHours, title: 'Experience & Hours', subtitle: 'Ongoing time-in-role and measurable reps', order: 40),
    TaskBookStageMeta(stage: TaskBookStage.taskBookSignoffs, title: 'Task Book / Practical Sign-offs', subtitle: 'Demonstrate performance under evaluation', order: 50),
    TaskBookStageMeta(stage: TaskBookStage.promotionalPreparation, title: 'Promotional Preparation', subtitle: 'Testing, interviews, and selection prep', order: 60),
    TaskBookStageMeta(stage: TaskBookStage.developmentRecommended, title: 'Development / Recommended', subtitle: 'Strongly recommended, not always required', order: 70),
  ];

  static TaskBookStageMeta metaFor(TaskBookStage stage) =>
      _meta.firstWhere((m) => m.stage == stage);

  static TaskBookStage stageForRequirement(Requirement r, {required bool isPrerequisiteForOthers}) {
    final cat = r.category.toLowerCase();
    if (cat.contains('prereq') || cat.contains('pre-req')) return TaskBookStage.prerequisites;

    if (isPrerequisiteForOthers && r.type != RequirementType.experience && r.type != RequirementType.numericProgress) {
      return TaskBookStage.prerequisites;
    }

    if (r.priority == RequirementPriority.development) return TaskBookStage.developmentRecommended;

    return switch (r.type) {
      RequirementType.certification => TaskBookStage.coreCertifications,
      RequirementType.trainingCourse || RequirementType.course || RequirementType.education => TaskBookStage.requiredCourses,
      RequirementType.experience || RequirementType.numericProgress => TaskBookStage.experienceHours,
      RequirementType.taskBook || RequirementType.practical => TaskBookStage.taskBookSignoffs,
      RequirementType.promotionalTest || RequirementType.interview => TaskBookStage.promotionalPreparation,
      RequirementType.custom => (r.priority == RequirementPriority.recommended || r.requirementSource == RequirementSource.recommended)
          ? TaskBookStage.developmentRecommended
          : TaskBookStage.requiredCourses,
    };
  }

  static TaskBookStagePlan<T> buildPlan<T>({
    required List<T> items,
    required Requirement Function(T raw) getRequirement,
    required bool Function(T raw) isComplete,
    required String? Function(T raw) getId,
  }) {
    final requirements = items.map(getRequirement).toList();

    final normalizedToIdx = <String, int>{};
    for (var i = 0; i < requirements.length; i++) {
      final r = requirements[i];
      final key1 = _norm(r.id);
      final key2 = _norm(r.name);
      if (key1.isNotEmpty) normalizedToIdx.putIfAbsent(key1, () => i);
      if (key2.isNotEmpty) normalizedToIdx.putIfAbsent(key2, () => i);
    }

    final prereqKeys = <String>{};
    for (final r in requirements) {
      for (final p in r.prerequisiteRequirementIds) {
        final k = _norm(p);
        if (k.isNotEmpty) prereqKeys.add(k);
      }
    }

    final prerequisiteRequirementIndexes = <int>{};
    for (final key in prereqKeys) {
      final idx = normalizedToIdx[key];
      if (idx != null) prerequisiteRequirementIndexes.add(idx);
    }

    final stageItems = <TaskBookStageItem<T>>[];
    for (var i = 0; i < items.length; i++) {
      final raw = items[i];
      final r = getRequirement(raw);
      final complete = isComplete(raw);
      final stage = stageForRequirement(r, isPrerequisiteForOthers: prerequisiteRequirementIndexes.contains(i));

      final unmet = <String>[];
      for (final prereq in r.prerequisiteRequirementIds) {
        final k = _norm(prereq);
        final idx = normalizedToIdx[k];
        if (idx == null) continue;
        if (idx < 0 || idx >= items.length) continue;
        final prereqRaw = items[idx];
        if (!isComplete(prereqRaw)) {
          unmet.add('Complete ${requirements[idx].name} first');
        }
      }

      stageItems.add(TaskBookStageItem<T>(
        raw: raw,
        requirement: r,
        isComplete: complete,
        originalIndex: i,
        stage: stage,
        unmetPrerequisiteLabels: unmet,
        canStartNow: unmet.isEmpty,
      ));
    }

    // Suggested next: remain in the earliest unfinished stage. Inside that
    // stage, favor work with measurable progress already underway, then normal
    // priority/sort order. Locked future work stays visible but is never Next.
    TaskBookStageItem<T>? suggestedNext;
    for (final meta in _meta) {
      final currentStage = stageItems
          .where((e) => e.stage == meta.stage && !e.isComplete && e.canStartNow)
          .toList();
      if (currentStage.isEmpty) continue;
      currentStage.sort((a, b) {
        final underway = _progressRank(a.requirement).compareTo(_progressRank(b.requirement));
        if (underway != 0) return underway;
        final pa = _priorityRank(a.requirement.priority);
        final pb = _priorityRank(b.requirement.priority);
        final pc = pa.compareTo(pb);
        if (pc != 0) return pc;
        return a.originalIndex.compareTo(b.originalIndex);
      });
      suggestedNext = currentStage.first;
      break;
    }

    final byStage = <TaskBookStage, List<TaskBookStageItem<T>>>{};
    for (final item in stageItems) {
      byStage.putIfAbsent(item.stage, () => <TaskBookStageItem<T>>[]).add(item);
    }

    final sections = <TaskBookStageSection<T>>[];
    for (final meta in _meta) {
      final list = byStage[meta.stage] ?? <TaskBookStageItem<T>>[];
      if (list.isEmpty) continue;

      final sorted = [...list];
      sorted.sort((a, b) {
        int tier(TaskBookStageItem<T> i) {
          if (i.isComplete) return 3;
          if (!i.canStartNow) return 2;
          if (_progressRank(i.requirement) == 0) return 0;
          return 1;
        }

        final c = tier(a).compareTo(tier(b));
        if (c != 0) return c;
        return a.originalIndex.compareTo(b.originalIndex);
      });

      final completedCount = sorted.where((e) => e.isComplete).length;
      sections.add(TaskBookStageSection<T>(
        meta: meta,
        items: sorted,
        completedCount: completedCount,
        totalCount: sorted.length,
      ));
    }

    final completedTotal = stageItems.where((e) => e.isComplete).length;
    return TaskBookStagePlan<T>(
      sections: sections,
      suggestedNext: suggestedNext,
      completedTotal: completedTotal,
      total: stageItems.length,
    );
  }

  static int _progressRank(Requirement r) {
    if (r.type == RequirementType.numericProgress &&
        r.progressCurrent != null &&
        r.progressRequired != null &&
        r.progressRequired! > 0 &&
        r.progressCurrent! > 0 &&
        r.progressCurrent! < r.progressRequired!) {
      return 0;
    }
    return 1;
  }

  static int _priorityRank(RequirementPriority p) {
    return switch (p) {
      RequirementPriority.state => 0,
      RequirementPriority.core => 1,
      RequirementPriority.department => 2,
      RequirementPriority.recommended => 3,
      RequirementPriority.development => 4,
    };
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
