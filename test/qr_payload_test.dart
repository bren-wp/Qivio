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

  test('poveznice: zabranjene sheme i spoofing preko korisnika', () {
    expect(safeActionUri('javascript:alert(1)'), isNull);
    expect(safeActionUri('file:///etc/passwd'), isNull);
    expect(safeActionUri('https://trusted.com@evil.example/'), isNull);
    expect(safeActionUri('https://example.com')?.host, 'example.com');
    expect(actionForPayload('tel:+385 91 234 5678')?.scheme, 'tel');
    expect(actionForPayload('tel:abc'), isNull);
  });

  test('Wi-Fi znakovi i nazivi ne izlažu lozinku u naslovu', () {
    final raw = qrWifi(ssid: 'Hotel;Wifi', password: r'a:b\c');
    expect(raw, contains(r'S:Hotel\;Wifi;'));
    expect(wifiField(raw, 'S'), 'Hotel;Wifi');
    expect(wifiField(raw, 'P'), r'a:b\c');
    expect(ScanEntry(raw: raw, date: DateTime(2026), saved: true).title, 'Hotel;Wifi');
    expect(qrWifi(ssid: 'Guest', password: ''), contains('T:nopass;'));
  });

  test('koordinate su strogo provjerene', () {
    expect(validCoordinates('45.327,14.443'), isTrue);
    expect(validCoordinates('91,14'), isFalse);
    expect(validCoordinates('1,NaN'), isFalse);
    expect(actionForPayload('geo:300,14'), isNull);
  });

  test('vCard i događaj ne dopuštaju novi red u vrijednosti', () {
    expect(qrContact(name: 'Test\nTEL:123', phone: '', email: ''),
      contains('FN:Test TEL:123\n'));
    final date = DateTime.utc(2026, 10, 9, 11);
    expect(qrEvent(title: 'Sastanak; ured', start: date,
      end: date.add(const Duration(hours: 1))), contains(r'SUMMARY:Sastanak\; ured'));
  });

  test('ograničenje veličine QR sadržaja', () {
    expect(fitsQrPayload('abc'), isTrue);
    expect(fitsQrPayload(''), isFalse);
    expect(fitsQrPayload('a' * 1601), isFalse);
  });

  test('duplikati i nevaljan lokalni JSON se ignoriraju', () {
    expect(decodeEntries('not json'), isEmpty);
    final items = [
      ScanEntry(raw: 'tekst', date: DateTime.utc(2026, 10, 9), saved: true),
      ScanEntry(raw: 'tekst', date: DateTime.utc(2026, 10, 8), saved: false),
    ];
    final decoded = decodeEntries(encodeEntries(items));
    expect(decoded.length, 1);
    expect(decoded.single.saved, isTrue);
  });
}
