/// Cross-feature prefill payloads used for deep links and flow integration.

class LogPrefill {
  final String title;
  final String? category;
  final String? relatedGoalId;
  final String? relatedRequirementId;
  final List<String> tags;

  const LogPrefill(
      {required this.title,
      required this.category,
      required this.relatedGoalId,
      required this.relatedRequirementId,
      required this.tags});
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
