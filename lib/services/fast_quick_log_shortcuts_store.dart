import 'package:firepath/services/local_store.dart';

class FastQuickLogShortcut {
  final String modeKey;
  final String title;

  const FastQuickLogShortcut({required this.modeKey, required this.title});

  String get id => '$modeKey::$title';

  Map<String, dynamic> toJson() => {
        'modeKey': modeKey,
        'title': title,
      };

  factory FastQuickLogShortcut.fromJson(Map<String, dynamic> json) =>
      FastQuickLogShortcut(
        modeKey: (json['modeKey'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
      );
}

class FastQuickLogShortcuts {
  final List<FastQuickLogShortcut> favorites;
  final List<FastQuickLogShortcut> recent;

  const FastQuickLogShortcuts({
    required this.favorites,
    required this.recent,
  });
}

class FastQuickLogShortcutsStore {
  static const String _key = 'fireops.fastQuickLogShortcuts.v1';
  static const int maxFavorites = 6;
  static const int maxRecent = 4;

  final LocalStore _store = LocalStore();

  Future<FastQuickLogShortcuts> load() async {
    final json = await _store.loadJsonMap(_key);
    if (json == null) {
      return const FastQuickLogShortcuts(favorites: [], recent: []);
    }

    List<FastQuickLogShortcut> parse(dynamic value) {
      if (value is! List) return <FastQuickLogShortcut>[];
      final seen = <String>{};
      final items = <FastQuickLogShortcut>[];
      for (final raw in value.whereType<Map>()) {
        final item = FastQuickLogShortcut.fromJson(
          Map<String, dynamic>.from(raw),
        );
        if (item.modeKey.isEmpty || item.title.trim().isEmpty) continue;
        if (seen.add(item.id)) items.add(item);
      }
      return items;
    }

    return FastQuickLogShortcuts(
      favorites: parse(json['favorites']).take(maxFavorites).toList(),
      recent: parse(json['recent']).take(maxRecent).toList(),
    );
  }

  Future<void> recordRecent(FastQuickLogShortcut shortcut) async {
    final current = await load();
    final recent = <FastQuickLogShortcut>[
      shortcut,
      ...current.recent.where((item) => item.id != shortcut.id),
    ].take(maxRecent).toList();
    await _save(favorites: current.favorites, recent: recent);
  }

  Future<bool> toggleFavorite(FastQuickLogShortcut shortcut) async {
    final current = await load();
    final isFavorite = current.favorites.any((item) => item.id == shortcut.id);
    final favorites = isFavorite
        ? current.favorites.where((item) => item.id != shortcut.id).toList()
        : <FastQuickLogShortcut>[
            shortcut,
            ...current.favorites.where((item) => item.id != shortcut.id),
          ].take(maxFavorites).toList();
    await _save(favorites: favorites, recent: current.recent);
    return !isFavorite;
  }

  Future<void> _save({
    required List<FastQuickLogShortcut> favorites,
    required List<FastQuickLogShortcut> recent,
  }) =>
      _store.saveJson(
        _key,
        {
          'favorites': favorites.map((item) => item.toJson()).toList(),
          'recent': recent.map((item) => item.toJson()).toList(),
        },
      );
}
