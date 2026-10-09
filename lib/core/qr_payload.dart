import 'dart:convert';

enum QrKind { link, wifi, contact, email, phone, text, location, event }

extension QrKindLabel on QrKind {
  String get label => switch (this) {
    QrKind.link => 'Poveznica',
    QrKind.wifi => 'Wi-Fi',
    QrKind.contact => 'Kontakt',
    QrKind.email => 'E-mail',
    QrKind.phone => 'Telefon',
    QrKind.text => 'Tekst',
    QrKind.location => 'Lokacija',
    QrKind.event => 'Događaj',
  };
}

QrKind detectKind(String raw) {
  final s = raw.trim();
  final lower = s.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return QrKind.link;
  if (s.toUpperCase().startsWith('WIFI:')) return QrKind.wifi;
  if (s.toUpperCase().startsWith('BEGIN:VCARD') ||
      s.toUpperCase().startsWith('MECARD:')) {
    return QrKind.contact;
  }
  if (lower.startsWith('mailto:') || RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s)) {
    return QrKind.email;
  }
  if (lower.startsWith('tel:')) return QrKind.phone;
  if (lower.startsWith('geo:')) return QrKind.location;
  if (s.toUpperCase().contains('BEGIN:VEVENT')) return QrKind.event;
  return QrKind.text;
}

Uri? safeActionUri(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme == 'https' || uri.scheme == 'http') return uri;
  return null;
}

Uri? actionForPayload(String raw) {
  final type = detectKind(raw);
  if (type == QrKind.link) return safeActionUri(raw);
  if (type == QrKind.email) {
    final value = raw.trim();
    return Uri.tryParse(value.startsWith('mailto:') ? value : 'mailto:$value');
  }
  if (type == QrKind.phone) return Uri.tryParse(raw.trim());
  if (type == QrKind.location) {
    final coordinates = raw.trim().substring(4).split(';').first;
    return Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': coordinates});
  }
  return null;
}

String qrWifi({required String ssid, required String password, bool hidden = false, String security = 'WPA'}) {
  String escape(String input) => input.replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;').replaceAll(':', '\\:')
      .replaceAll(',', '\\,').replaceAll('"', '\\"');
  return 'WIFI:T:${password.isEmpty ? 'nopass' : security};S:${escape(ssid)};'
      'P:${escape(password)};H:${hidden ? 'true' : 'false'};;';
}

String qrContact({required String name, required String phone, required String email}) {
  String cleaned(String text) => text.replaceAll(RegExp(r'[\r\n]'), ' ').trim();
  return 'BEGIN:VCARD\nVERSION:3.0\nFN:${cleaned(name)}\n'
      'TEL:${cleaned(phone)}\nEMAIL:${cleaned(email)}\nEND:VCARD';
}

String qrEmail(String address) => 'mailto:${address.trim()}';
String qrPhone(String number) => 'tel:${number.trim()}';
String qrLocation(String coordinates) => 'geo:${coordinates.trim()}';

String qrEvent({required String title, required DateTime start, required DateTime end}) {
  String stamp(DateTime dt) =>
      '${dt.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z';
  final safeTitle = title.replaceAll(RegExp(r'[\r\n]'), ' ').trim();
  return 'BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\n'
      'SUMMARY:$safeTitle\nDTSTART:${stamp(start)}\nDTEND:${stamp(end)}\n'
      'END:VEVENT\nEND:VCALENDAR';
}

class ScanEntry {
  const ScanEntry({required this.raw, required this.date, required this.saved});
  final String raw;
  final DateTime date;
  final bool saved;

  QrKind get kind => detectKind(raw);
  String get title {
    if (kind == QrKind.link) return Uri.tryParse(raw)?.host ?? raw;
    if (kind == QrKind.wifi) {
      final match = RegExp(r'(?:^|;)S:((?:\\.|[^;])*)').firstMatch(raw);
      return match?.group(1)?.replaceAll(r'\;', ';') ?? 'Wi-Fi mreža';
    }
    return raw.replaceAll('\n', ' ').length > 45
        ? '${raw.replaceAll('\n', ' ').substring(0, 45)}…'
        : raw.replaceAll('\n', ' ');
  }

  Map<String, dynamic> toJson() => {'raw': raw, 'date': date.toIso8601String(), 'saved': saved};
  static ScanEntry? fromJson(dynamic data) {
    if (data is! Map) return null;
    final raw = data['raw'];
    final date = DateTime.tryParse(data['date']?.toString() ?? '');
    if (raw is! String || raw.isEmpty || date == null) return null;
    return ScanEntry(raw: raw, date: date, saved: data['saved'] == true);
  }
}

List<ScanEntry> decodeEntries(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! List) return [];
    return decoded.map(ScanEntry.fromJson).whereType<ScanEntry>().take(250).toList();
  } catch (_) {
    return [];
  }
}

String encodeEntries(List<ScanEntry> entries) => jsonEncode(entries.map((e) => e.toJson()).toList());
