import 'package:flutter_test/flutter_test.dart';
import 'package:firepath/pages/department/department_training_home_page.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

DepartmentReviewItem review(String id) => DepartmentReviewItem(
      id: id,
      memberName: 'Member',
      taskBookTitle: 'Task Book',
      sectionTitle: 'Section',
      requirementTitle: 'Requirement',
      requirementDescription: '',
      instructions: '',
      memberNotes: '',
      reviewStage: 'EVALUATOR',
      submittedAt: null,
      waitingHours: 0,
      escalationHours: 48,
      escalated: false,
      approvedRepetitions: 0,
      repetitionsRequired: 1,
      evaluationSteps: const [],
      criticalFailures: const [],
    );

void main() {
  group('Needs Attention evaluation routing', () {
    test('resolves the work queue review ID, not an assignment ID', () {
      final selected = review('completion-123');
      final result = resolveDepartmentReviewTarget(
        'completion-123',
        [review('another-completion'), selected],
      );

      expect(result, same(selected));
    });

    test('does not resolve a missing evaluation to another record', () {
      final result = resolveDepartmentReviewTarget(
        'stale-completion',
        [review('different-completion')],
      );

      expect(result, isNull);
    });
  });
}
