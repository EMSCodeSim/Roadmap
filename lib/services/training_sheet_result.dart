/// Resolve a saved roster outcome without hiding an explicit failed grade.
/// The server remains authoritative for approval; this protects the instructor
/// display while older API deployments recalculate existing grade systems.
String displayTrainingSheetResult({
  required String savedResult,
  required List<Map<String, dynamic>> skillResults,
  required List<Map<String, dynamic>> customFields,
  required Map<String, dynamic> customValues,
  required Map<String, dynamic> gradingConfig,
  double? writtenScore,
  double? ccfScore,
}) {
  final failedSkill = skillResults.any(
    (item) => item['result']?.toString().toUpperCase() == 'FAIL',
  );
  final failedCustomGrade = customFields.any((field) {
    if (field['appliesTo'] == 'ROSTER') return false;
    final value = customValues[field['id']?.toString() ?? '']
        ?.toString()
        .trim()
        .toUpperCase();
    return (field['type'] == 'PASS_FAIL' && value == 'FAIL') ||
        (field['type'] == 'LETTER_GRADE' && value == 'F');
  });
  final writtenThreshold = (gradingConfig['writtenTestPassPercent'] as num?)?.toDouble();
  final ccfThreshold = (gradingConfig['ccfPassPercent'] as num?)?.toDouble();
  final failedConfiguredScore =
      (gradingConfig['writtenTestEnabled'] == true && writtenScore != null &&
          writtenThreshold != null && writtenScore < writtenThreshold) ||
      (gradingConfig['ccfEnabled'] == true && ccfScore != null &&
          ccfThreshold != null && ccfScore < ccfThreshold);
  if (failedSkill || failedCustomGrade || failedConfiguredScore) return 'FAIL';
  return savedResult.toUpperCase();
}
