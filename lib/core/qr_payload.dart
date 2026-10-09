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
  final upper = s.toUpperCase();
  final lower = s.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return QrKind.link;
  if (upper.startsWith('WIFI:')) return QrKind.wifi;
  if (upper.startsWith('BEGIN:VCARD') || upper.startsWith('MECARD:')) return QrKind.contact;
  if (lower.startsWith('mailto:') || RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s)) {
    return QrKind.email;
  }
  if (lower.startsWith('tel:')) return QrKind.phone;
  if (lower.startsWith('geo:')) return QrKind.location;
  if (upper.contains('BEGIN:VEVENT')) return QrKind.event;
  return QrKind.text;
}

/// Permit only explicit http/https addresses, never userinfo, scripts or file URIs.
Uri? safeActionUri(String raw) {
  final source = raw.trim();
  if (RegExp(r'[\s\\\x00-\x1F\x7F]').hasMatch(source)) return null;
  final uri = Uri.tryParse(source);
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    return null;
  }
  if (uri.scheme.toLowerCase() == 'https' || uri.scheme.toLowerCase() == 'http') return uri;
  return null;
}

Uri? actionForPayload(String raw) {
  final type = detectKind(raw);
  if (type == QrKind.link) return safeActionUri(raw);
  if (type == QrKind.email) {
    final value = raw.trim();
    final target = value.toLowerCase().startsWith('mailto:') ? value : 'mailto:$value';
    final uri = Uri.tryParse(target);
    if (uri == null || uri.scheme != 'mailto' || uri.hasAuthority) return null;
    final address = uri.path;
    final parts = address.split('@');
    if (parts.length != 2 || parts.first.isEmpty ||
        !parts.last.contains('.') || parts.last.startsWith('.') ||
        parts.last.endsWith('.') || RegExp(r'[\s\r\n]').hasMatch(address)) {
      return null;
    }
    try {
      if (uri.queryParameters.values.any(
          (part) => RegExp(r'[\r\n]').hasMatch(part))) return null;
    } on FormatException {
      return null;
    }
    return uri;
  }
  if (type == QrKind.phone) {
    final number = raw.trim().substring(4);
    if (!RegExp(r'^\+?[0-9 ()\-.#*]{1,40}$').hasMatch(number)) return null;
    return Uri(scheme: 'tel', path: number);
  }
  if (type == QrKind.location) {
    final coordinates = raw.trim().substring(4).split(';').first;
    if (!validCoordinates(coordinates)) return null;
    return Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': coordinates});
  }
  return null;
}

bool validCoordinates(String value) {
  final parts = value.split(',');
  if (parts.length != 2) return false;
  final latitude = double.tryParse(parts[0].trim());
  final longitude = double.tryParse(parts[1].trim());
  return latitude != null && longitude != null &&
      latitude.isFinite && longitude.isFinite &&
      latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
}

String qrWifi({required String ssid, required String password, bool hidden = false, String security = 'WPA'}) {
  String escape(String input) => input.replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;').replaceAll(':', '\\:')
      .replaceAll(',', '\\,').replaceAll('"', '\\"');
  final mode = password.isEmpty ? 'nopass' : security;
  return 'WIFI:T:$mode;S:${escape(ssid)};P:${escape(password)};H:${hidden ? 'true' : 'false'};;';
}

String _escapeVcard(String text) => text.trim()
    .replaceAll('\\', '\\\\')
    .replaceAll(RegExp(r'[\r\n]+'), ' ')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,');

String qrContact({required String name, required String phone, required String email}) {
  return 'BEGIN:VCARD\nVERSION:3.0\nFN:${_escapeVcard(name)}\n'
      'TEL:${_escapeVcard(phone)}\nEMAIL:${_escapeVcard(email)}\nEND:VCARD';
}

String qrEmail(String address) => 'mailto:${address.trim()}';
String qrPhone(String number) => 'tel:${number.trim()}';
String qrLocation(String coordinates) => 'geo:${coordinates.trim()}';

String qrEvent({required String title, required DateTime start, required DateTime end}) {
  String stamp(DateTime dt) =>
      '${dt.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z';
  final safeTitle = _escapeVcard(title);
  return 'BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\n'
      'SUMMARY:$safeTitle\nDTSTART:${stamp(start)}\nDTEND:${stamp(end)}\n'
      'END:VEVENT\nEND:VCALENDAR';
}

/// The QR spec's error correction capacity depends on version and encoding.
/// This conservative byte limit avoids large or malformed render attempts.
bool fitsQrPayload(String raw) => raw.isNotEmpty && utf8.encode(raw).length <= 1600;

/// Read Wi-Fi fields as an escape-aware stream, never splitting escaped semicolons.
String? wifiField(String raw, String field) {
  if (detectKind(raw) != QrKind.wifi ||
      !const {'T', 'S', 'P', 'H'}.contains(field)) return null;

  final fields = <String, String>{};
  final key = StringBuffer();
  final value = StringBuffer();
  var readingValue = false;
  var escaped = false;

  void finish() {
    if (readingValue && const {'T', 'S', 'P', 'H'}.contains(key.toString())) {
      fields[key.toString()] = value.toString();
    }
    key.clear();
    value.clear();
    readingValue = false;
  }

  for (final point in raw.substring(5).runes) {
    final ch = String.fromCharCode(point);
    if (escaped) {
      (readingValue ? value : key).write(ch);
      escaped = false;
    } else if (ch.codeUnitAt(0) == 92) {
      escaped = true;
    } else if (ch == ';') {
      finish();
    } else if (ch == ':' && !readingValue) {
      readingValue = true;
    } else {
      (readingValue ? value : key).write(ch);
    }
  }
  if (escaped) return null;
  finish();
  return fields[field];
}

class ScanEntry {
  const ScanEntry({required this.raw, required this.date, required this.saved});
  final String raw;
  final DateTime date;
  final bool saved;

  QrKind get kind => detectKind(raw);
  String get title {
    if (kind == QrKind.link) return Uri.tryParse(raw)?.host ?? raw;
    if (kind == QrKind.wifi) return wifiField(raw, 'S') ?? 'Wi-Fi mreža';
    if (kind == QrKind.contact) {
      final value = RegExp(r'(?:^|\n)FN:([^\n]*)').firstMatch(raw)?.group(1);
      if (value != null && value.isNotEmpty) return value;
    }
    final cleaned = raw.replaceAll(RegExp(r'[\r\n]+'), ' ');
    return cleaned.length > 45 ? '${cleaned.substring(0, 45)}…' : cleaned;
  }

  Map<String, dynamic> toJson() => {'raw': raw, 'date': date.toIso8601String(), 'saved': saved};

  static ScanEntry? fromJson(dynamic data) {
    if (data is! Map) return null;
    final raw = data['raw'];
    final date = DateTime.tryParse(data['date']?.toString() ?? '');
    if (raw is! String || raw.isEmpty || date == null || raw.length > 10000) return null;
    return ScanEntry(raw: raw, date: date, saved: data['saved'] == true);
  }
}

List<ScanEntry> decodeEntries(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! List) return [];
    final unique = <String>{};
    return decoded.map(ScanEntry.fromJson).whereType<ScanEntry>()
        .where((e) => unique.add(e.raw)).take(250).toList();
  } catch (_) {
    return [];
  }
}

String encodeEntries(List<ScanEntry> entries) =>
    jsonEncode(entries.map((e) => e.toJson()).toList());
