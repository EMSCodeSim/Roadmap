import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/home_section_preference.dart';
import 'package:firepath/services/home_section_preferences_store.dart';
import 'package:firepath/widgets/home_screen_customization_sheet.dart';

void main() {
  testWidgets('users can choose and save visual Home sections', (tester) async {
    final store = _FakeHomeSectionStore();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreenCustomizationSheet(store: store),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customize Home Screen'), findsOneWidget);
    expect(find.text('Career goal'), findsOneWidget);
    expect(find.text('Next best step'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('home_section_toggle_jobSearch')),
      250,
      scrollable: find.byType(ReorderableListView),
    );
    expect(find.text('Job search findings'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('home_section_toggle_jobSearch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Home Screen'));
    await tester.pumpAndSettle();

    expect(store.saved, isNotNull);
    expect(
      store.saved!
          .firstWhere((item) => item.type == HomeSectionType.jobSearch)
          .visible,
      isTrue,
    );
  });
}

class _FakeHomeSectionStore extends HomeSectionPreferencesStore {
  List<HomeSectionPreference>? saved;

  @override
  Future<List<HomeSectionPreference>> load() async =>
      List<HomeSectionPreference>.from(HomeSectionPreferencesStore.defaults);

  @override
  Future<bool> save(List<HomeSectionPreference> preferences) async {
    saved = List<HomeSectionPreference>.from(preferences);
    return true;
  }
}
