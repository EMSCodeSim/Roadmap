import 'package:flutter/foundation.dart';

/// A verified state-specific requirement mapping.
///
/// IMPORTANT: This is an internal catalog layer. It should only contain entries
/// that have been verified against an authoritative state source.
@immutable
class StateRequirementEntry {
  final String stateCode;
  final String careerGoalId;
  final String requirementId;
  final String requirementType;
  final String sourceTitle;
  final String? sourceUrl;
  final DateTime verifiedDate;
  final String? notes;

  const StateRequirementEntry({
    required this.stateCode,
    required this.careerGoalId,
    required this.requirementId,
    required this.requirementType,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.verifiedDate,
    required this.notes,
  });
}
