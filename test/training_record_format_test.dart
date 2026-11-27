import 'package:flutter_test/flutter_test.dart';
import 'package:firepath/utils/training_record_format.dart';

void main() {
  test('preserves actual overall outcomes and does not turn pending into pass', () {
    expect(formatTrainingOverallResult('PASS'), 'Overall: PASS');
    expect(formatTrainingOverallResult('FAIL'), 'Overall: FAIL');
    expect(formatTrainingOverallResult('NEEDS_REMEDIATION'), 'Overall: NEEDS REMEDIATION');
    expect(formatTrainingOverallResult('PENDING'), 'Overall: Not evaluated');
  });

  test('prints a selected percentage system beside the student', () {
    final parts = trainingScoreParts(
      customFields: const <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'grade-percent',
          'label': 'Score (%)',
          'type': 'PERCENT',
          'required': true,
          'appliesTo': 'RESULT',
        },
      ],
      customValues: const <String, dynamic>{'grade-percent': 88},
      gradingConfig: const <String, dynamic>{},
      finalResult: 'PASS',
    );

    expect('Alex Ebaugh — ${parts.join(' · ')}', 'Alex Ebaugh — Score (%): 88%');
  });

  test('prints written and CCF systems and ignores roster-only fields', () {
    final parts = trainingScoreParts(
      customFields: const <Map<String, dynamic>>[
        <String, dynamic>{'id': 'email', 'label': 'Email', 'type': 'TEXT', 'appliesTo': 'ROSTER'},
      ],
      customValues: const <String, dynamic>{'email': 'student@example.com'},
      gradingConfig: const <String, dynamic>{'writtenTestEnabled': true, 'ccfEnabled': true},
      finalResult: 'PASS',
      writtenScore: 92,
      ccfScore: 85,
    );

    expect(parts, <String>['Written: 92.0%', 'CCF: 85.0']);
  });
}
