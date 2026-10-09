import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qr_payload.dart';

class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);
  final SharedPreferences _prefs;
  final List<ScanEntry> _entries = [];
  bool _light = false;
  bool _historyEnabled = true;

  static const maxHistory = 250;
  static const _historyKey = 'qrex_history_v1';

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore._(prefs);
    store._entries.addAll(decodeEntries(prefs.getString(_historyKey) ?? '[]'));
    store._light = prefs.getBool('qrex_light_v1') ?? false;
    store._historyEnabled = prefs.getBool('qrex_record_v1') ?? true;
    return store;
  }

  List<ScanEntry> get entries => List.unmodifiable(_entries);
  bool get light => _light;
  bool get historyEnabled => _historyEnabled;
  bool isSaved(String raw) => _entries.any((e) => e.raw == raw && e.saved);

  /// Scanning never silently saves Wi-Fi credentials to ordinary preferences.
  /// The user may explicitly save a Wi-Fi QR code using [save].
  Future<void> record(String raw) async {
    final data = raw.trim();
    if (!_historyEnabled || data.isEmpty || detectKind(data) == QrKind.wifi) return;
    final saved = isSaved(data);
    _entries.removeWhere((e) => e.raw == data);
    _entries.insert(0, ScanEntry(raw: data, date: DateTime.now(), saved: saved));
    _trim();
    notifyListeners();
    await _persist();
  }

  Future<void> save(String raw) async {
    final data = raw.trim();
    if (data.isEmpty) return;
    _entries.removeWhere((e) => e.raw == data);
    _entries.insert(0, ScanEntry(raw: data, date: DateTime.now(), saved: true));
    _trim();
    notifyListeners();
    await _persist();
  }

  void _trim() {
    while (_entries.length > maxHistory) {
      final i = _entries.lastIndexWhere((e) => !e.saved);
      _entries.removeAt(i >= 0 ? i : _entries.length - 1);
    }
  }

  Future<void> remove(ScanEntry item) async {
    final oldLength = _entries.length;
    _entries.removeWhere((e) => e.raw == item.raw && e.date == item.date);
    if (oldLength == _entries.length) return;
    notifyListeners();
    await _persist();
  }

  Future<void> clearHistory() async {
    _entries.removeWhere((item) => !item.saved);
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    _entries.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> setLight(bool value) async {
    _light = value;
    notifyListeners();
    await _prefs.setBool('qrex_light_v1', value);
  }

  Future<void> setHistoryEnabled(bool value) async {
    _historyEnabled = value;
    notifyListeners();
    await _prefs.setBool('qrex_record_v1', value);
  }

  Future<void> _persist() async =>
      _prefs.setString(_historyKey, encodeEntries(_entries));
}
