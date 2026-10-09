import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrex/ui/qrex_theme.dart';

void main() {
  testWidgets('QREX logo and primary call-to-action render', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: qrexTheme(false),
      home: Scaffold(body: Column(children: [
        const QrexWordmark(),
        QrexButton(label: 'Stvori', onPressed: () {}),
      ])),
    ));
    expect(find.text('Stvori'), findsOneWidget);
    expect(find.byType(QrexMark), findsOneWidget);
  });
}
