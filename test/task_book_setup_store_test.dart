import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/services/task_book_setup_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Task Book review stays pending until explicitly completed', () async {
    final store = TaskBookSetupStore();

    expect(await store.isReviewPending(), isFalse);

    await store.setReviewPending(true);
    expect(await store.isReviewPending(), isTrue);

    await store.setReviewPending(false);
    expect(await store.isReviewPending(), isFalse);
  });
}
