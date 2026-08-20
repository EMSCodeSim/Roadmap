import 'package:flutter/foundation.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/state_requirement_entry.dart';

/// A small, expandable catalog of VERIFIED state-specific requirements.
///
/// DO NOT add entries here unless you have an authoritative state source.
/// For states/goal pairs without verified data, this returns an empty list so
/// the rest of the Task Book relies on common/department recommendations.
class StateRequirementCatalog {
  static const List<StateRequirementEntry> _verified = <StateRequirementEntry>[
    // Intentionally empty: architecture-only. Add verified entries over time.
    // Example structure (do not enable without verification):
    // StateRequirementEntry(
    //   stateCode: 'CO',
    //   careerGoalId: 'ops_engineer',
    //   requirementId: 'driver_operator_pumper',
    //   requirementType: 'certification',
    //   sourceTitle: 'Colorado Division of Fire Prevention and Control',
    //   sourceUrl: 'https://example.gov/...',
    //   verifiedDate: DateTime(2026, 1, 1),
    //   notes: 'Applies to ...',
    // ),
  ];

  static bool hasVerifiedDataForState(String stateCode) {
    final s = stateCode.trim().toUpperCase();
    return _verified.any((e) => e.stateCode == s);
  }

  static bool hasVerifiedDataForGoal({required String stateCode, required String careerGoalId}) {
    final s = stateCode.trim().toUpperCase();
    return _verified.any((e) => e.stateCode == s && e.careerGoalId == careerGoalId);
  }

  static List<StateRequirementEntry> entriesForGoal({
    required String stateCode,
    required String careerGoalId,
  }) {
    final s = stateCode.trim().toUpperCase();
    return _verified
        .where((e) => e.stateCode == s && e.careerGoalId == careerGoalId)
        .toList(growable: false);
  }

  /// Build concrete [Requirement] instances for the verified entries.
  ///
  /// The returned requirements are marked as [RequirementSource.stateRequirement]
  /// and include optional metadata fields used by the UI.
  static List<Requirement> buildVerifiedRequirements({
    required String stateCode,
    required String careerGoalId,
    required Map<String, Requirement> baseRequirementById,
  }) {
    final entries = entriesForGoal(stateCode: stateCode, careerGoalId: careerGoalId);
    if (entries.isEmpty) return const <Requirement>[];

    final out = <Requirement>[];
    for (final e in entries) {
      final base = baseRequirementById[e.requirementId];
      if (base == null) {
        debugPrint('StateRequirementCatalog: missing base requirementId=${e.requirementId}');
        continue;
      }
      out.add(
        base.copyWith(
          requirementSource: RequirementSource.stateRequirement,
          stateDependent: true,
          sourceStateCode: e.stateCode,
          sourceTitle: e.sourceTitle,
          sourceUrl: e.sourceUrl,
          sourceVerifiedDate: e.verifiedDate,
          sourceNotes: e.notes,
          updatedAt: DateTime.now(),
        ),
      );
    }
    return out;
  }
}
