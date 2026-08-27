import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/national_task_book_baseline.dart';
import 'package:firepath/services/task_book_checklist_hierarchy.dart';

void main() {
  test('every built-in certification has a national checklist baseline', () {
    final certifications = FireOpsCatalog.certificationDefinitions();

    expect(certifications.length, 13);

    for (final certification in certifications) {
      final standard = NationalTaskBookBaseline.standardForCertificationId(
        certification.id,
      );

      expect(
        standard,
        isNotNull,
        reason: '${certification.displayName} is missing a national baseline',
      );
      expect(
        standard!.steps,
        isNotEmpty,
        reason: '${certification.displayName} has no checklist sections',
      );
      expect(
        standard.subTasks,
        isNotEmpty,
        reason: '${certification.displayName} has no checklist objectives',
      );

      final stepIds = standard.steps.map((step) => step.id).toSet();
      expect(
        stepIds.length,
        standard.steps.length,
        reason: '${certification.displayName} has duplicate section IDs',
      );

      for (final step in standard.steps) {
        expect(
          TaskBookChecklistHierarchy.childrenFor(step.id, standard.subTasks),
          isNotEmpty,
          reason:
              '${certification.displayName} section "${step.title}" has no objectives',
        );
      }
    }
  });

  test('HazMat and EMS national sources are mapped to the intended standards', () {
    expect(
      NationalTaskBookBaseline.standardForCertificationId('hazmat_awareness')!
          .citation,
      'NFPA 470 (2022), Chapter 5',
    );
    expect(
      NationalTaskBookBaseline.standardForCertificationId('hazmat_operations')!
          .citation,
      'NFPA 470 (2022), Chapters 5 + 7',
    );
    expect(
      NationalTaskBookBaseline.standardForCertificationId('emt')!.standard,
      'National EMS Education Standards',
    );
    expect(
      NationalTaskBookBaseline.standardForCertificationId('aemt')!.standard,
      'National EMS Education Standards',
    );
    expect(
      NationalTaskBookBaseline.standardForCertificationId('paramedic')!
          .standard,
      'National EMS Education Standards',
    );
  });
}
