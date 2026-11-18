import 'package:firepath/pages/certifications/certification_detail_page.dart';
import 'package:firepath/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('new certification requires expiration or does-not-expire choice',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => AppState(),
        child: const MaterialApp(
          home: CertificationDetailPage(certId: 'new', extra: null),
        ),
      ),
    );

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isFalse,
    );

    await tester.enterText(find.byType(TextFormField).first, 'CPR');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(
      find.text('Add an expiration date or select Does Not Expire.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Does Not Expire'));
    await tester.pump();

    expect(
      find.text('Add an expiration date or select Does Not Expire.'),
      findsNothing,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isTrue,
    );
  });
}
