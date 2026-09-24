import 'dart:convert';
import 'package:billify/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Production-grade Local Storage Service offering type-safe primitives,
/// resilient JSON serialization, and tenant/key-prefix invalidation.
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // ==================== String & Primitives ====================

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  Set<String> getKeys() {
    return _prefs.getKeys();
  }

  // ==================== Type-Safe JSON Serialization ====================

  /// Persists a Map as a JSON string
  Future<bool> setJson(String key, Map<String, dynamic> json) async {
    try {
      final jsonString = jsonEncode(json);
      return await _prefs.setString(key, jsonString);
    } catch (e) {
      AppLogger.error('Failed to encode JSON for key: $key', tag: 'LocalStorageService', error: e);
      return false;
    }
  }

  /// Retrieves and safely decodes a JSON Map
  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (e) {
      AppLogger.warning('Corrupted JSON data for key: $key. Clearing key.', tag: 'LocalStorageService');
      _prefs.remove(key);
      return null;
    }
  }

  /// Persists a List of Maps as a JSON string
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> list) async {
    try {
      final jsonString = jsonEncode(list);
      return await _prefs.setString(key, jsonString);
    } catch (e) {
      AppLogger.error('Failed to encode JSON list for key: $key', tag: 'LocalStorageService', error: e);
      return false;
    }
  }

  /// Retrieves and safely decodes a List of JSON Maps
  List<Map<String, dynamic>>? getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return null;
    } catch (e) {
      AppLogger.warning('Corrupted JSON list for key: $key. Clearing key.', tag: 'LocalStorageService');
      _prefs.remove(key);
      return null;
    }
  }

  // ==================== Deletion & Invalidation ====================

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  /// Clears all keys matching a specific prefix (e.g. for user or business tenant logout)
  Future<int> clearKeysWithPrefix(String prefix) async {
    int count = 0;
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      final success = await _prefs.remove(key);
      if (success) count++;
    }
    AppLogger.info('Cleared $count keys with prefix "$prefix"', tag: 'LocalStorageService');
    return count;
  }

  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}

