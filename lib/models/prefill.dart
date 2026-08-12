/// Cross-feature prefill payloads used for deep links and flow integration.

import 'package:firepath/models/career_record.dart';

class LogPrefill {
  final String title;
  final String? category;
  final String? relatedGoalId;
  final String? relatedRequirementId;
  final String? relatedTaskId;
  final List<String> tags;

  const LogPrefill(
      {required this.title,
      required this.category,
      required this.relatedGoalId,
      required this.relatedRequirementId,
      required this.relatedTaskId,
      required this.tags});

  factory LogPrefill.fromRecord(CareerRecord record) => LogPrefill(
        title: record.title,
        category: record.category,
        relatedGoalId: record.relatedGoalId,
        relatedRequirementId: record.relatedRequirementId,
        relatedTaskId: record.relatedTaskId,
        tags: record.tags,
      );
}

class EvidencePrefill {
  final String title;
  final String? category;
  final String? relatedGoalId;
  final String? relatedRequirementId;
  final List<String> tags;

  const EvidencePrefill(
      {required this.title,
      required this.category,
      required this.relatedGoalId,
      required this.relatedRequirementId,
      required this.tags});
}
