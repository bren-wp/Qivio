import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrex/main.dart';

void main() {
  testWidgets('Storage failure displays retry rather than empty app', (tester) async {
    await tester.pumpWidget(const QrexStorageRecovery());
    expect(find.text('Podaci uređaja trenutačno nisu dostupni.'), findsOneWidget);
    expect(find.text('Pokušaj ponovno'), findsOneWidget);
    expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
  });
}
