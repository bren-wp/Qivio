import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qr_payload.dart';

class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);
  final SharedPreferences _prefs;
  final List<ScanEntry> _entries = [];
  bool _light = false;
  bool _historyEnabled = true;

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore._(prefs);
    store._entries.addAll(decodeEntries(prefs.getString('qrex_history_v1') ?? '[]'));
    store._light = prefs.getBool('qrex_light_v1') ?? false;
    store._historyEnabled = prefs.getBool('qrex_record_v1') ?? true;
    return store;
  }

  List<ScanEntry> get entries => List.unmodifiable(_entries);
  bool get light => _light;
  bool get historyEnabled => _historyEnabled;

  Future<void> record(String raw) async {
    final data = raw.trim();
    if (!_historyEnabled || data.isEmpty) return;
    _entries.removeWhere((e) => e.raw == data && !e.saved);
    _entries.insert(0, ScanEntry(raw: data, date: DateTime.now(), saved: false));
    if (_entries.length > 250) _entries.removeRange(250, _entries.length);
    notifyListeners();
    await _persist();
  }

  Future<void> save(String raw) async {
    final data = raw.trim();
    if (data.isEmpty) return;
    _entries.removeWhere((e) => e.raw == data);
    _entries.insert(0, ScanEntry(raw: data, date: DateTime.now(), saved: true));
    notifyListeners();
    await _persist();
  }

  bool isSaved(String raw) => _entries.any((e) => e.raw == raw && e.saved);

  Future<void> remove(ScanEntry item) async {
    _entries.removeWhere((e) => e.raw == item.raw && e.date == item.date);
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

  Future<void> _persist() async => _prefs.setString('qrex_history_v1', encodeEntries(_entries));
}
