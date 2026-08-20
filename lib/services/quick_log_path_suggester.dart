import 'package:flutter/material.dart';

import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/models/custom_task_book.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/state/app_state.dart';

/// Small, heuristic suggester that makes Quick Log feel "path-aware".
///
/// It intentionally avoids any backend dependency and uses the currently
/// selected Roadmap + Task Book progress to surface the *fastest* log actions
/// that advance the user's next level.
class QuickLogPathSuggester {
  static List<QuickLogPathSuggestion> suggestionsFor(AppState state) {
    // Respect the active Task Book.
    // - If a custom/department Task Book is active, suggest from that.
    // - Otherwise, use the generated Career Road roadmap + nextStep.
    final activeCustom = state.activeCustomTaskBook;
    final roadmap = state.roadmap;

    Requirement? next;
    String? goalId;

    if (activeCustom != null) {
      goalId = activeCustom.pseudoGoalId;
      next = _nextIncompleteCustomRequirement(state, goalId: goalId, book: activeCustom);
    } else {
      if (roadmap == null) return const [];
      goalId = roadmap.goal.id;
      next = roadmap.nextStep?.requirement;
    }

    if (next == null || goalId == null || goalId.trim().isEmpty) return const [];
    final suggestions = <QuickLogPathSuggestion>[];

    final nextTask = _nextIncompleteTask(
      state,
      goalId: goalId,
      requirement: next,
    );

    // 1) Always provide a "log next step" action.
    suggestions.add(
      QuickLogPathSuggestion(
        title: nextTask?.title ?? 'Log progress',
        subtitle: next.name,
        icon: Icons.bolt_outlined,
        prefill: LogPrefill(
          title: nextTask?.title ?? next.name,
          category: next.name,
          relatedGoalId: goalId,
          relatedRequirementId: next.id,
          relatedTaskId: nextTask?.id,
          tags: const ['task-book', 'next-step'],
        ),
      ),
    );

    // 2) Add a couple of targeted, template-like suggestions based on keywords.
    final text = '${next.name} ${next.description}'.toLowerCase();

    if (_any(text, const ['driver', 'engineer', 'apparatus', 'evoc', 'e.v.o.c'])) {
      suggestions.add(
        QuickLogPathSuggestion(
          title: 'Log Driver Training Hours',
          subtitle: next.name,
          icon: Icons.local_shipping_outlined,
          prefill: LogPrefill(
            title: 'Emergency driving',
            category: next.name,
            relatedGoalId: goalId,
            relatedRequirementId: next.id,
            relatedTaskId: nextTask?.id,
            tags: const ['task-book', 'driver-training'],
            trackerKey: 'fire.driver',
          ),
        ),
      );
    }

    if (_any(text, const ['live fire', 'burn', 'structure fire training'])) {
      suggestions.add(
        QuickLogPathSuggestion(
          title: 'Log Live Fire Evolutions',
          subtitle: next.name,
          icon: Icons.local_fire_department_outlined,
          prefill: LogPrefill(
            title: 'Live fire training',
            category: next.name,
            relatedGoalId: goalId,
            relatedRequirementId: next.id,
            relatedTaskId: nextTask?.id,
            tags: const ['task-book', 'live-fire'],
          ),
        ),
      );
    }

    if (_any(text, const ['emt', 'paramedic', 'aemt']) &&
        _any(text, const ['renew', 'renewal', 'ce', 'con ed', 'continuing'])) {
      suggestions.add(
        QuickLogPathSuggestion(
          title: 'Log CE for Renewal',
          subtitle: next.name,
          icon: Icons.menu_book_outlined,
          prefill: LogPrefill(
            title: 'CE for renewal',
            category: next.name,
            relatedGoalId: goalId,
            relatedRequirementId: next.id,
            relatedTaskId: nextTask?.id,
            tags: const ['task-book', 'renewal', 'ce'],
          ),
        ),
      );
    }

    if (_any(text, const ['promotion', 'promotional', 'oral board', 'interview', 'test'])) {
      suggestions.add(
        QuickLogPathSuggestion(
          title: 'Log Promotional Prep Study Time',
          subtitle: next.name,
          icon: Icons.school_outlined,
          prefill: LogPrefill(
            title: 'Promotional prep',
            category: next.name,
            relatedGoalId: goalId,
            relatedRequirementId: next.id,
            relatedTaskId: nextTask?.id,
            tags: const ['task-book', 'promotion', 'study'],
          ),
        ),
      );
    }

    // Keep it tight: the first 3 usually feels best in a bottom sheet.
    return suggestions.take(3).toList(growable: false);
  }

  static Requirement? _nextIncompleteCustomRequirement(
    AppState state, {
    required String goalId,
    required CustomTaskBook book,
  }) {
    for (final r in book.requirements) {
      final o = state.taskBookController.getOverride(goalId, r.id);
      final complete = (o?.completed ?? r.completed) == true;
      if (!complete) return r;
    }
    return null;
  }

  static TaskBookTaskDefinition? _nextIncompleteTask(
    AppState state, {
    required String goalId,
    required Requirement requirement,
  }) {
    final tasks = <TaskBookTaskDefinition>[
      ...TaskBookLibrary.tasksForRequirement(requirement),
      ...state.customTasksFor(goalId: goalId, requirementId: requirement.id),
    ];
    for (final task in tasks) {
      final status = state.taskStatusFor(
        goalId: goalId,
        requirementId: requirement.id,
        taskId: task.id,
      );
      if (status != TaskBookTaskStatus.complete) return task;
    }
    return null;
  }

  static bool _any(String text, List<String> tokens) {
    for (final t in tokens) {
      if (text.contains(t)) return true;
    }
    return false;
  }
}

class QuickLogPathSuggestion {
  final String title;
  final String subtitle;
  final IconData icon;
  final LogPrefill prefill;

  const QuickLogPathSuggestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.prefill,
  });
}
