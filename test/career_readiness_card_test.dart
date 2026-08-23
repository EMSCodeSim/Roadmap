import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/services/readiness_snapshot.dart';
import 'package:firepath/widgets/career_readiness_card.dart';

void main() {
  test('readiness view model shows ready state when complete', () {
    const snapshot = CareerReadinessSnapshot(
      completedCount: 8,
      totalCount: 8,
      percentComplete: 1,
      nextStep: null,
      prerequisiteGaps: [],
      coreGaps: [],
      departmentGaps: [],
      experienceGaps: [],
      taskBookGaps: [],
      recommendedGaps: [],
      developmentGaps: [],
    );

    final vm = CareerReadinessViewModel.fromSnapshot(snapshot);
    expect(vm.isReady, isTrue);
    expect(vm.percentLabel, '100% ready');
    expect(vm.gapLabel, 'All included requirements complete');
    expect(vm.statusLabel, 'READY');
  });

  test('readiness view model falls back to remaining requirement count', () {
    const snapshot = CareerReadinessSnapshot(
      completedCount: 6,
      totalCount: 8,
      percentComplete: .75,
      nextStep: null,
      prerequisiteGaps: [],
      coreGaps: [],
      departmentGaps: [],
      experienceGaps: [],
      taskBookGaps: [],
      recommendedGaps: [],
      developmentGaps: [],
    );

    final vm = CareerReadinessViewModel.fromSnapshot(snapshot);
    expect(vm.isReady, isFalse);
    expect(vm.percentLabel, '75% ready');
    expect(vm.gapLabel, '2 requirements remaining');
    expect(vm.statusLabel, 'DEVELOPING');
  });
}
