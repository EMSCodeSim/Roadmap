import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/services/fast_quick_log_shortcuts_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('recent Quick Logs keep newest first and remove duplicates', () async {
    final store = FastQuickLogShortcutsStore();
    const engine = FastQuickLogShortcut(modeKey: 'drive', title: 'Engine');
    const medic = FastQuickLogShortcut(modeKey: 'drive', title: 'Medic');

    await store.recordRecent(engine);
    await store.recordRecent(medic);
    await store.recordRecent(engine);

    final data = await store.load();
    expect(data.recent.map((item) => item.title).toList(), ['Engine', 'Medic']);
  });

  test('recent Quick Logs are capped at four', () async {
    final store = FastQuickLogShortcutsStore();
    for (var i = 0; i < 6; i++) {
      await store.recordRecent(
        FastQuickLogShortcut(modeKey: 'training', title: 'Training $i'),
      );
    }

    final data = await store.load();
    expect(data.recent.length, FastQuickLogShortcutsStore.maxRecent);
    expect(data.recent.first.title, 'Training 5');
    expect(data.recent.last.title, 'Training 2');
  });

  test('favorite Quick Logs toggle on and off', () async {
    final store = FastQuickLogShortcutsStore();
    const favorite = FastQuickLogShortcut(
      modeKey: 'career',
      title: 'Acting officer',
    );

    expect(await store.toggleFavorite(favorite), isTrue);
    expect((await store.load()).favorites.single.id, favorite.id);

    expect(await store.toggleFavorite(favorite), isFalse);
    expect((await store.load()).favorites, isEmpty);
  });

  test('favorite Quick Logs are capped at six', () async {
    final store = FastQuickLogShortcutsStore();
    for (var i = 0; i < 8; i++) {
      await store.toggleFavorite(
        FastQuickLogShortcut(modeKey: 'skill', title: 'Skill $i'),
      );
    }

    final data = await store.load();
    expect(data.favorites.length, FastQuickLogShortcutsStore.maxFavorites);
    expect(data.favorites.first.title, 'Skill 7');
    expect(data.favorites.last.title, 'Skill 2');
  });
}
