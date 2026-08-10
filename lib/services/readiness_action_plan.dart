import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/readiness_snapshot.dart';
import 'package:firepath/state/app_state.dart';

/// The kind of action the UI should offer for a readiness gap.
enum ReadinessActionKind {
  getStarted,
  seePrerequisite,
  logProgress,
  updateTaskBook,
  viewTraining,
  continueWork,
}

/// A single actionable gap in the user's career-readiness plan.
class ReadinessActionItem {
  final RoadmapRequirement roadmapRequirement;
  final ReadinessActionKind actionKind;
  final String actionLabel;
  final String reason;

  const ReadinessActionItem({
    required this.roadmapRequirement,
    required this.actionKind,
    required this.actionLabel,
    required this.reason,
  });

  Requirement get requirement => roadmapRequirement.requirement;
}

typedef ReadinessActivityResolver = RequirementActivityStatus Function(
  String goalId,
  String requirementId,
);

/// Converts the existing readiness snapshot into a small, ordered action plan.
///
/// This does not recalculate roadmap priority. The snapshot/roadmap remain the
/// source of truth; this class only chooses the most useful CTA for each gap.
class CareerReadinessActionPlan {
  final List<ReadinessActionItem> items;

  const CareerReadinessActionPlan({required this.items});

  ReadinessActionItem? get primary => items.isEmpty ? null : items.first;

  factory CareerReadinessActionPlan.fromState(
    AppState state, {
    int maxItems = 5,
  }) {
    final roadmap = state.roadmap;
    if (roadmap == null) {
      return const CareerReadinessActionPlan(items: []);
    }

    return CareerReadinessActionPlan.fromRoadmap(
      roadmap,
      maxItems: maxItems,
      activityResolver: (goalId, requirementId) => state.activityStatusFor(
        goalId: goalId,
        requirementId: requirementId,
      ),
    );
  }

  /// Builds an action plan directly from a roadmap.
  ///
  /// This is useful for isolated UI/tests and keeps presentation code from
  /// depending on the entire AppState object. If no resolver is provided,
  /// requirements are treated as not started.
  factory CareerReadinessActionPlan.fromRoadmap(
    Roadmap roadmap, {
    int maxItems = 5,
    ReadinessActivityResolver? activityResolver,
  }) {
    final snapshot = CareerReadinessSnapshot.fromRoadmap(roadmap);
    final ordered = snapshot.majorGaps;
    final result = <ReadinessActionItem>[];

    for (final gap in ordered.take(maxItems)) {
      final r = gap.requirement;
      final activity = activityResolver?.call(roadmap.goal.id, r.id) ??
          RequirementActivityStatus.notStarted;

      final action = _actionFor(r, activity);
      result.add(
        ReadinessActionItem(
          roadmapRequirement: gap,
          actionKind: action.$1,
          actionLabel: action.$2,
          reason: _reasonFor(snapshot, gap),
        ),
      );
    }

    return CareerReadinessActionPlan(items: result);
  }

  static (ReadinessActionKind, String) _actionFor(
    Requirement requirement,
    RequirementActivityStatus activity,
  ) {
    if (activity == RequirementActivityStatus.scheduled) {
      return (ReadinessActionKind.viewTraining, 'VIEW TRAINING');
    }
    if (activity == RequirementActivityStatus.inProgress) {
      return (ReadinessActionKind.continueWork, 'CONTINUE');
    }

    switch (requirement.type) {
      case RequirementType.experience:
      case RequirementType.numericProgress:
        return (ReadinessActionKind.logProgress, 'LOG PROGRESS');
      case RequirementType.taskBook:
        return (ReadinessActionKind.updateTaskBook, 'UPDATE PROGRESS');
      case RequirementType.certification:
      case RequirementType.trainingCourse:
      case RequirementType.course:
      case RequirementType.promotionalTest:
      case RequirementType.practical:
      case RequirementType.interview:
      case RequirementType.education:
      case RequirementType.custom:
        return (ReadinessActionKind.getStarted, 'GET STARTED');
    }
  }

  static String _reasonFor(
    CareerReadinessSnapshot snapshot,
    RoadmapRequirement gap,
  ) {
    final id = gap.requirement.id;
    if (snapshot.prerequisiteGaps.any((e) => e.requirement.id == id)) {
      return 'Complete this prerequisite before moving farther down your path.';
    }
    if (snapshot.coreGaps.any((e) => e.requirement.id == id)) {
      return 'This is a core readiness item for your selected career goal.';
    }
    if (snapshot.experienceGaps.any((e) => e.requirement.id == id)) {
      return 'Keep building the experience or progress required for this path.';
    }
    if (snapshot.taskBookGaps.any((e) => e.requirement.id == id)) {
      return 'Continue documenting task-book progress toward readiness.';
    }
    if (snapshot.departmentGaps.any((e) => e.requirement.id == id)) {
      return 'This is a department-dependent item on your current path.';
    }
    return 'This item supports your readiness for the selected goal.';
  }
}
