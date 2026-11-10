import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/data/services/dictionary_cache.dart';
import 'package:textara/data/services/dictionary_word_normalizer.dart';
import 'package:textara/domain/entities/dictionary_entry.dart';

/// Offline-first dictionary lookup with optional opt-in online fallback.
class DictionaryService {
  DictionaryService({
    DictionaryCache? cache,
    http.Client? httpClient,
    AssetBundle? assetBundle,
    this.onlineEndpoint = AppConstants.dictionaryOnlineEndpoint,
  })  : _cache = cache ?? DictionaryCache(),
        _httpClient = httpClient ?? http.Client(),
        _assetBundle = assetBundle ?? rootBundle;

  final DictionaryCache _cache;
  final http.Client _httpClient;
  final AssetBundle _assetBundle;
  final String onlineEndpoint;

  Map<String, DictionaryEntry>? _offlineLexicon;
  Future<void>? _loading;

  Future<void> ensureLoaded() async {
    if (_offlineLexicon != null) return;
    _loading ??= _loadOfflineLexicon();
    await _loading;
  }

  Future<void> _loadOfflineLexicon() async {
    try {
      final raw = await _assetBundle.loadString(
        AppConstants.dictionaryAssetPath,
      );
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _offlineLexicon = {};
        return;
      }
      final entries = decoded['entries'];
      if (entries is! Map) {
        _offlineLexicon = {};
        return;
      }

      final map = <String, DictionaryEntry>{};
      entries.forEach((key, value) {
        final word = key.toString().toLowerCase();
        if (value is! List) return;
        final senses = value
            .whereType<Map>()
            .map(
              (s) => DictionarySense.fromJson(
                s.map((k, v) => MapEntry(k.toString(), v)),
              ),
            )
            .where((s) => s.definition.trim().isNotEmpty)
            .toList();
        if (senses.isEmpty) return;
        map[word] = DictionaryEntry(
          word: word,
          senses: senses,
          source: DictionarySource.offline,
        );
      });
      _offlineLexicon = map;
    } catch (error, stackTrace) {
      debugPrint('DictionaryService offline load failed: $error\n$stackTrace');
      _offlineLexicon = {};
    }
  }

  /// Looks up [selection], normalizing to a headword first.
  ///
  /// Order: offline pack → on-device cache → optional online API (opt-in).
  Future<DictionaryLookupResult> lookup(
    String selection, {
    bool allowOnline = false,
  }) async {
    final headword = DictionaryWordNormalizer.headwordFromSelection(selection);
    if (headword == null) {
      return DictionaryLookupResult.notFound(selection.trim());
    }

    await ensureLoaded();

    final offline = _offlineLexicon?[headword];
    if (offline != null) {
      return DictionaryLookupResult.found(offline);
    }

    // Try a few common variants before leaving the device.
    for (final variant in _offlineVariants(headword)) {
      final hit = _offlineLexicon?[variant];
      if (hit != null) {
        return DictionaryLookupResult.found(hit.copyWith(word: headword));
      }
    }

    final cached = await _cache.get(headword);
    if (cached != null && cached.hasSenses) {
      return DictionaryLookupResult.found(cached);
    }

    if (!allowOnline) {
      return DictionaryLookupResult.notFound(headword);
    }

    try {
      final online = await _lookupOnline(headword);
      if (online == null || !online.hasSenses) {
        return DictionaryLookupResult.notFound(headword);
      }
      await _cache.put(online);
      return DictionaryLookupResult.found(online, usedNetwork: true);
    } catch (error) {
      return DictionaryLookupResult.error(
        headword,
        'Online lookup failed. Check your connection or try again later.',
      );
    }
  }

  Iterable<String> _offlineVariants(String word) sync* {
    if (word.endsWith('y') && word.length > 2) {
      yield '${word.substring(0, word.length - 1)}ies';
    }
    if (!word.endsWith('s')) {
      yield '${word}s';
      yield '${word}es';
    }
    if (!word.endsWith('ed')) {
      yield '${word}ed';
    }
    if (!word.endsWith('ing')) {
      yield '${word}ing';
    }
  }

  Future<DictionaryEntry?> _lookupOnline(String word) async {
    final uri = Uri.parse('$onlineEndpoint$word');
    final response = await _httpClient
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return null;

    final senses = <DictionarySense>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final meanings = item['meanings'];
      if (meanings is! List) continue;
      for (final meaning in meanings) {
        if (meaning is! Map) continue;
        final pos = (meaning['partOfSpeech'] as String?) ?? 'unknown';
        final definitions = meaning['definitions'];
        if (definitions is! List) continue;
        for (final def in definitions.take(3)) {
          if (def is! Map) continue;
          final definition = (def['definition'] as String?)?.trim() ?? '';
          if (definition.isEmpty) continue;
          senses.add(
            DictionarySense(
              partOfSpeech: pos,
              definition: definition,
              example: def['example'] as String?,
            ),
          );
        }
      }
    }

    if (senses.isEmpty) return null;
    return DictionaryEntry(
      word: word,
      senses: senses.take(6).toList(),
      source: DictionarySource.online,
    );
  }

  @visibleForTesting
  void seedOfflineLexiconForTest(Map<String, DictionaryEntry> lexicon) {
    _offlineLexicon = lexicon;
  }
}
