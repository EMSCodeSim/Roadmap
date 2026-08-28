import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/services/task_book_focus_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('personal Task Books are the safe default', () async {
    final store = TaskBookFocusStore();

    expect(await store.load(), TaskBookFocus.personal);
  });

  test('department focus persists and can switch back to personal', () async {
    final store = TaskBookFocusStore();

    await store.save(TaskBookFocus.department);
    expect(await store.load(), TaskBookFocus.department);

    await store.save(TaskBookFocus.personal);
    expect(await store.load(), TaskBookFocus.personal);
  });

  test('reset returns the Task Book focus to personal', () async {
    final store = TaskBookFocusStore();

    await store.save(TaskBookFocus.department);
    await store.reset();

    expect(await store.load(), TaskBookFocus.personal);
  });
}
