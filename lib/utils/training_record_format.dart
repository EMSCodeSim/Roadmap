String formatTrainingOverallResult(String finalResult) {
  final value = finalResult.trim().toUpperCase();
  if (value.isEmpty || value == 'PENDING' || value == 'NOT_EVALUATED') {
    return 'Overall: Not evaluated';
  }
  return 'Overall: ${value.replaceAll('_', ' ')}';
}

String formatTrainingScoreValue(Object? value, String type) {
  if (value == null || value.toString().trim().isEmpty) return 'Not recorded';
  if (type == 'CHECKBOX') return value == true || value.toString().toLowerCase() == 'true' ? 'Yes' : 'No';
  final text = value.toString().replaceAll('_', ' ');
  if (type == 'PERCENT' && !text.endsWith('%')) return '$text%';
  return text;
}

List<String> trainingScoreParts({
  required List<Map<String, dynamic>> customFields,
  required Map<String, dynamic> customValues,
  required Map<String, dynamic> gradingConfig,
  required String finalResult,
  double? writtenScore,
  double? ccfScore,
}) {
  final parts = <String>[];
  for (final field in customFields.where((item) => item['appliesTo']?.toString() != 'ROSTER')) {
    final id = field['id']?.toString() ?? '';
    if (id.isEmpty) continue;
    final label = field['label']?.toString().trim();
    final type = field['type']?.toString() ?? 'TEXT';
    parts.add('${label == null || label.isEmpty ? 'Score' : label}: ${formatTrainingScoreValue(customValues[id], type)}');
  }
  if (gradingConfig['writtenTestEnabled'] == true) {
    parts.add('Written: ${writtenScore == null ? 'Not recorded' : '${writtenScore.toStringAsFixed(1)}%'}');
  }
  if (gradingConfig['ccfEnabled'] == true) {
    parts.add('CCF: ${ccfScore == null ? 'Not recorded' : ccfScore.toStringAsFixed(1)}');
  }
  if (parts.isEmpty) {
    parts.add('Final result: ${finalResult.replaceAll('_', ' ')}');
  }
  return parts;
}
