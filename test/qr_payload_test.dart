import 'package:flutter_test/flutter_test.dart';
import 'package:qrex/core/qr_payload.dart';

void main() {
  test('tipovi sadržaja', () {
    expect(detectKind('https://example.com'), QrKind.link);
    expect(detectKind('WIFI:T:WPA;S:Home;P:12345;;'), QrKind.wifi);
    expect(detectKind('BEGIN:VCARD\nFN:Test\nEND:VCARD'), QrKind.contact);
    expect(detectKind('geo:45.3,14.4'), QrKind.location);
    expect(detectKind('običan tekst'), QrKind.text);
  });
  test('samo http i https poveznice', () {
    expect(safeActionUri('javascript:alert(1)'), isNull);
    expect(safeActionUri('file:///etc/passwd'), isNull);
    expect(safeActionUri('https://example.com')?.host, 'example.com');
  });
  test('Wi-Fi znakovi moraju biti escapani', () {
    expect(qrWifi(ssid: 'Hotel;Wifi', password: r'a:b\\c'), contains(r'S:Hotel\;Wifi;'));
    expect(qrWifi(ssid: 'Guest', password: ''), contains('T:nopass;'));
  });
  test('spremanje podataka podnosi neispravan zapis', () {
    expect(decodeEntries('not json'), isEmpty);
    final items = [ScanEntry(raw: 'tekst', date: DateTime.utc(2026, 10, 9), saved: true)];
    final decoded = decodeEntries(encodeEntries(items));
    expect(decoded.single.saved, isTrue);
    expect(decoded.single.raw, 'tekst');
  });
}
