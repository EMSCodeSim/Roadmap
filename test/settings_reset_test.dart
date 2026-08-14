import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/services/local_store.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reset removes every FireOps key and preserves unrelated preferences', () async {
    SharedPreferences.setMockInitialValues({
      'fireops.onboardingComplete': true,
      'fireops.profile': '{}',
      'fireops.careerRecords.v2.2026': '[]',
      'fireops.apparatusProfiles.v1': '[]',
      'unrelated.preference': 'keep',
    });

    expect(await LocalStore().resetAppData(), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((key) => key.startsWith('fireops.')), isEmpty);
    expect(prefs.getString('unrelated.preference'), 'keep');
  });

  test('reset returns live AppState to first-launch state', () async {
    SharedPreferences.setMockInitialValues({
      'fireops.onboardingComplete': true,
    });
    final state = AppState();
    await state.bootstrap();
    expect(state.onboardingComplete, isTrue);

    expect(await state.resetApp(), isTrue);
    expect(state.onboardingComplete, isFalse);
    expect(state.profile.currentRoles, isEmpty);
    expect(state.certifications, isEmpty);
    expect(state.roadmap, isNull);
  });
}
