import 'package:flutter_test/flutter_test.dart';
import 'package:qrex/core/app_store.dart';
import 'package:qrex/core/qr_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('spremanje i ponovno skeniranje ne stvaraju duplikate', () async {
    final store = await AppStore.load();
    await store.record('https://example.com');
    await store.save('https://example.com');
    await store.record('https://example.com');
    expect(store.entries.length, 1);
    expect(store.entries.single.saved, isTrue);
    final reloaded = await AppStore.load();
    expect(reloaded.entries.single.saved, isTrue);
    store.dispose();
    reloaded.dispose();
  });

  test('Wi-Fi lozinke ne ulaze automatski u povijest', () async {
    final store = await AppStore.load();
    final wifi = qrWifi(ssid: 'Dom', password: 'osjetljivo');
    await store.record(wifi);
    expect(store.entries, isEmpty);
    await store.save(wifi);
    expect(store.entries.single.saved, isTrue);
    await store.clearHistory();
    expect(store.entries.single.saved, isTrue);
    await store.clearAll();
    expect((await AppStore.load()).entries, isEmpty);
    store.dispose();
  });

  test('isključena povijest ne bilježi skeniranja', () async {
    final store = await AppStore.load();
    await store.setHistoryEnabled(false);
    await store.record('https://example.com');
    expect(store.entries, isEmpty);
    store.dispose();
  });

  test('najviše 250 zapisa, sačuvani imaju prednost', () async {
    final store = await AppStore.load();
    await store.save('https://important.example');
    for (var i = 0; i < 270; i++) {
      await store.record('tekst broj $i');
    }
    expect(store.entries.length, AppStore.maxHistory);
    expect(store.isSaved('https://important.example'), isTrue);
    store.dispose();
  });

  test('simultaneous writes and deletion never restore stale history', () async {
    final store = await AppStore.load();
    final writes = <Future<void>>[
      store.record('first'),
      store.save('second'),
      store.record('third'),
      store.clearAll(),
    ];
    await Future.wait(writes);
    final restored = await AppStore.load();
    expect(restored.entries, isEmpty);
    expect(restored.historyEnabled, isTrue);
    expect(restored.light, isFalse);
    store.dispose();
    restored.dispose();
  });

  test('potpuno brisanje vraća lokalne postavke na početne', () async {
    final store = await AppStore.load();
    await store.save('osobni podatak');
    await store.setLight(true);
    await store.setHistoryEnabled(false);
    await store.clearAll();
    final restored = await AppStore.load();
    expect(restored.entries, isEmpty);
    expect(restored.light, isFalse);
    expect(restored.historyEnabled, isTrue);
    store.dispose();
    restored.dispose();
  });

  test('brisanjem obične povijesti ostaju spremljeni kodovi', () async {
    final store = await AppStore.load();
    await store.record('tekst');
    await store.save('https://example.com');
    await store.clearHistory();
    expect(store.entries.length, 1);
    expect(store.entries.single.saved, isTrue);
    store.dispose();
  });
}
