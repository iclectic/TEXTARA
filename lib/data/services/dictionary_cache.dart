import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/domain/entities/dictionary_entry.dart';

/// Small on-device cache for dictionary lookups (no book text, only headwords).
class DictionaryCache {
  DictionaryCache({
    SharedPreferences? preferences,
    this.maxEntries = AppConstants.dictionaryCacheMaxEntries,
  }) : _preferences = preferences;

  final SharedPreferences? _preferences;
  final int maxEntries;

  Future<SharedPreferences> _prefs() async {
    return _preferences ?? SharedPreferences.getInstance();
  }

  Future<DictionaryEntry?> get(String word) async {
    final prefs = await _prefs();
    final raw = prefs.getString(AppConstants.prefKeyDictionaryCache);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final entryJson = decoded[word];
      if (entryJson is! Map) return null;
      return DictionaryEntry.fromJson(
        entryJson.map((key, value) => MapEntry(key.toString(), value)),
      ).copyWith(source: DictionarySource.cache);
    } catch (_) {
      return null;
    }
  }

  Future<void> put(DictionaryEntry entry) async {
    final prefs = await _prefs();
    Map<String, dynamic> map = {};
    final raw = prefs.getString(AppConstants.prefKeyDictionaryCache);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          map = decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        map = {};
      }
    }

    map.remove(entry.word);
    map[entry.word] = entry.toJson();

    while (map.length > maxEntries) {
      map.remove(map.keys.first);
    }

    await prefs.setString(
      AppConstants.prefKeyDictionaryCache,
      jsonEncode(map),
    );
  }

  Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(AppConstants.prefKeyDictionaryCache);
  }
}
