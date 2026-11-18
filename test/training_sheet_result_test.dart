import 'package:flutter_test/flutter_test.dart';
import 'package:firepath/services/training_sheet_result.dart';

void main() {
  group('Training Sheet result display', () {
    test('shows a saved failed Pass/Fail grade as FAIL even if the summary is stale', () {
      final result = displayTrainingSheetResult(
        savedResult: 'PASS',
        skillResults: const [],
        customFields: const [
          {'id': 'exam', 'type': 'PASS_FAIL', 'required': true, 'appliesTo': 'RESULT'},
        ],
        customValues: const {'exam': 'FAIL'},
        gradingConfig: const {},
      );

      expect(result, 'FAIL');
    });

    test('shows skill failures, F grades, and below-threshold scores as FAIL', () {
      expect(displayTrainingSheetResult(
        savedResult: 'PASS',
        skillResults: const [{'result': 'FAIL'}],
        customFields: const [],
        customValues: const {},
        gradingConfig: const {},
      ), 'FAIL');
      expect(displayTrainingSheetResult(
        savedResult: 'PASS',
        skillResults: const [],
        customFields: const [{'id': 'grade', 'type': 'LETTER_GRADE'}],
        customValues: const {'grade': 'F'},
        gradingConfig: const {},
      ), 'FAIL');
      expect(displayTrainingSheetResult(
        savedResult: 'PASS',
        skillResults: const [],
        customFields: const [],
        customValues: const {},
        gradingConfig: const {'writtenTestEnabled': true, 'writtenTestPassPercent': 80},
        writtenScore: 79,
      ), 'FAIL');
    });

    test('does not treat roster fields or passing grades as failures', () {
      expect(displayTrainingSheetResult(
        savedResult: 'PASS',
        skillResults: const [],
        customFields: const [
          {'id': 'training', 'type': 'PASS_FAIL', 'appliesTo': 'ROSTER'},
          {'id': 'exam', 'type': 'PASS_FAIL', 'appliesTo': 'RESULT'},
        ],
        customValues: const {'training': 'FAIL', 'exam': 'PASS'},
        gradingConfig: const {},
      ), 'PASS');
      expect(displayTrainingSheetResult(
        savedResult: 'REMEDIATION',
        skillResults: const [],
        customFields: const [],
        customValues: const {},
        gradingConfig: const {},
      ), 'REMEDIATION');
    });
  });
}
