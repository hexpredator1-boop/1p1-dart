import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';

const _keyState   = 'ms2_state';
const _keyBests   = 'ms2_bests';
const _keyPerfect = 'ms2_perfect';

class Storage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    if (_prefs == null) throw StateError('Storage.init() not called');
    return _prefs!;
  }

  // ── App State ──
  static AppState loadState() {
    try {
      final raw = _p.getString(_keyState);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        return AppState.fromJson(json);
      }
    } catch (_) {}
    return AppState.defaults();
  }

  static Future<void> saveState(AppState state) async {
    await _p.setString(_keyState, jsonEncode(state.toJson()));
  }

  // ── Bests ──
  static Map<String, int> loadBests() {
    try {
      final raw = _p.getString(_keyBests);
      if (raw != null) {
        return (jsonDecode(raw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toInt()));
      }
    } catch (_) {}
    return {};
  }

  static Future<void> saveBest(String key, int pct) async {
    final bests = loadBests();
    bests[key] = pct;
    await _p.setString(_keyBests, jsonEncode(bests));
  }

  static Future<void> clearBest(String key) async {
    final bests = loadBests();
    bests.remove(key);
    await _p.setString(_keyBests, jsonEncode(bests));
  }

  // ── Perfect scores ──
  static Map<String, Map<String, dynamic>> loadPerfect() {
    try {
      final raw = _p.getString(_keyPerfect);
      if (raw != null) {
        return (jsonDecode(raw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as Map<String, dynamic>));
      }
    } catch (_) {}
    return {};
  }

  static Future<void> savePerfect(String key, double goalSec) async {
    final perfect = loadPerfect();
    if (!perfect.containsKey(key)) {
      perfect[key] = {'ts': DateTime.now().millisecondsSinceEpoch, 'goalSec': goalSec};
      await _p.setString(_keyPerfect, jsonEncode(perfect));
    }
  }
}
