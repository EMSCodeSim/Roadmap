import 'package:firepath/models/requirement.dart';
import 'package:firepath/state/app_state.dart';

/// A compact, UI-friendly summary of a user's current career readiness.
///
/// This intentionally derives from [Roadmap] rather than duplicating roadmap
/// matching logic. It gives Home/My Path a stable way to explain the user's
/// remaining gaps without adding another source of truth.
class CareerReadinessSnapshot {
  final int completedCount;
  final int totalCount;
  final double percentComplete;
  final RoadmapRequirement? nextStep;
  final List<RoadmapRequirement> prerequisiteGaps;
  final List<RoadmapRequirement> coreGaps;
  final List<RoadmapRequirement> departmentGaps;
  final List<RoadmapRequirement> experienceGaps;
  final List<RoadmapRequirement> taskBookGaps;
  final List<RoadmapRequirement> recommendedGaps;
  final List<RoadmapRequirement> developmentGaps;

  const CareerReadinessSnapshot({
    required this.completedCount,
    required this.totalCount,
    required this.percentComplete,
    required this.nextStep,
    required this.prerequisiteGaps,
    required this.coreGaps,
    required this.departmentGaps,
    required this.experienceGaps,
    required this.taskBookGaps,
    required this.recommendedGaps,
    required this.developmentGaps,
  });

  int get remainingCount => totalCount - completedCount;
  bool get isReady => totalCount > 0 && remainingCount == 0;

  /// Major gaps are the items most likely to affect readiness first.
  ///
  /// The same requirement can appear in more than one bucket (for example a
  /// department task book), so this getter de-duplicates by requirement ID and
  /// keeps the most useful presentation order: prerequisite, core, department,
  /// experience, then task book.
  List<RoadmapRequirement> get majorGaps {
    final seen = <String>{};
    final ordered = <RoadmapRequirement>[];
    for (final item in <RoadmapRequirement>[
      ...prerequisiteGaps,
      ...coreGaps,
      ...departmentGaps,
      ...experienceGaps,
      ...taskBookGaps,
    ]) {
      if (seen.add(item.requirement.id)) ordered.add(item);
    }
    return List.unmodifiable(ordered);
  }

  int get majorGapCount => majorGaps.length;

  factory CareerReadinessSnapshot.fromRoadmap(Roadmap roadmap) {
    final missing = roadmap.missing;

    bool isDepartment(Requirement r) =>
        r.priority == RequirementPriority.department ||
        r.requirementSource == RequirementSource.departmentRequirement;

    bool isExperience(Requirement r) =>
        r.type == RequirementType.experience ||
        r.type == RequirementType.numericProgress;

    final prereqIds = <String>{};
    for (final item in missing) {
      for (final key in item.requirement.prerequisiteRequirementIds) {
        final normalized = key.trim().toLowerCase();
        for (final candidate in roadmap.included) {
          final ref = (candidate.requirement.certificationReference ??
                  candidate.requirement.name)
              .trim()
              .toLowerCase();
          if (ref == normalized && !candidate.isComplete) {
            prereqIds.add(candidate.requirement.id);
          }
        }
      }
    }

    List<RoadmapRequirement> sortedWhere(
      bool Function(RoadmapRequirement item) test,
    ) {
      final result = missing.where(test).toList();
      result.sort((a, b) =>
          a.requirement.sortOrder.compareTo(b.requirement.sortOrder));
      return result;
    }

    return CareerReadinessSnapshot(
      completedCount: roadmap.completedCount,
      totalCount: roadmap.totalCount,
      percentComplete: roadmap.percentComplete,
      nextStep: roadmap.nextStep,
      prerequisiteGaps:
          sortedWhere((item) => prereqIds.contains(item.requirement.id)),
      coreGaps: sortedWhere((item) {
        final r = item.requirement;
        return r.priority == RequirementPriority.core ||
            r.priority == RequirementPriority.state;
      }),
      departmentGaps:
          sortedWhere((item) => isDepartment(item.requirement)),
      experienceGaps:
          sortedWhere((item) => isExperience(item.requirement)),
      taskBookGaps: sortedWhere(
          (item) => item.requirement.type == RequirementType.taskBook),
      recommendedGaps: sortedWhere(
          (item) => item.requirement.priority == RequirementPriority.recommended),
      developmentGaps: sortedWhere(
          (item) => item.requirement.priority == RequirementPriority.development),
    );
  }
}
