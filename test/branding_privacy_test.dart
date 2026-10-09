import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrex/core/app_store.dart';
import 'package:qrex/screens/more_page.dart';
import 'package:qrex/ui/qrex_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('developer credit and offline privacy visible', (tester) async {
    final store = await AppStore.load();
    await tester.pumpWidget(MaterialApp(
      theme: qrexTheme(false),
      home: Scaffold(body: MorePage(
        store: store,
        navigate: (index, {bool gallery = false}) {},
      )),
    ));
    await tester.scrollUntilVisible(find.text('Razvio Brendigo'), 200,
      scrollable: find.byType(Scrollable).first);
    expect(find.text('Razvio Brendigo'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pročitaj pravila privatnosti'), -130,
      scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Pročitaj pravila privatnosti'));
    await tester.pumpAndSettle();
    expect(find.text('Pravila privatnosti'), findsOneWidget);
    expect(find.text('Javna verzija'), findsOneWidget);
    store.dispose();
  });
}
