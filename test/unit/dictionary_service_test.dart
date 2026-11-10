import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/data/services/dictionary_cache.dart';
import 'package:textara/data/services/dictionary_service.dart';
import 'package:textara/domain/entities/dictionary_entry.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.payload);

  final String payload;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(payload));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => payload;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const offlinePayload = '''
{
  "language": "en",
  "entries": {
    "hope": [
      {"pos": "noun", "definition": "a feeling of expectation", "example": "Hold onto hope."}
    ],
    "courage": [
      {"pos": "noun", "definition": "the ability to do something that frightens"}
    ]
  }
}
''';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  DictionaryService buildService({
    http.Client? client,
    String payload = offlinePayload,
  }) {
    return DictionaryService(
      cache: DictionaryCache(),
      httpClient: client,
      assetBundle: _FakeBundle(payload),
    );
  }

  group('DictionaryService', () {
    test('returns offline definitions without network', () async {
      final service = buildService(
        client: MockClient((request) async {
          fail('Network should not be called for offline hits');
        }),
      );

      final result = await service.lookup('Hope!');
      expect(result.status, DictionaryLookupStatus.found);
      expect(result.entry?.word, 'hope');
      expect(result.entry?.source, DictionarySource.offline);
      expect(result.entry?.senses.first.definition, contains('expectation'));
      expect(result.usedNetwork, isFalse);
    });

    test('returns notFound when offline miss and online disabled', () async {
      final service = buildService(
        client: MockClient((request) async {
          fail('Network should not be called when online is disabled');
        }),
      );

      final result = await service.lookup('quokka', allowOnline: false);
      expect(result.status, DictionaryLookupStatus.notFound);
      expect(result.query, 'quokka');
    });

    test('uses online fallback when opted in and caches the result', () async {
      var networkCalls = 0;
      final client = MockClient((request) async {
        networkCalls += 1;
        expect(request.url.path, endsWith('/en/quokka'));
        return http.Response(
          jsonEncode([
            {
              'word': 'quokka',
              'meanings': [
                {
                  'partOfSpeech': 'noun',
                  'definitions': [
                    {
                      'definition': 'a small wallaby of southwestern Australia',
                      'example': 'A smiling quokka.',
                    },
                  ],
                },
              ],
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = buildService(client: client);
      final online = await service.lookup('quokka', allowOnline: true);
      expect(online.status, DictionaryLookupStatus.found);
      expect(online.usedNetwork, isTrue);
      expect(online.entry?.source, DictionarySource.online);
      expect(online.entry?.senses.first.partOfSpeech, 'noun');
      expect(networkCalls, 1);

      final cached = await service.lookup('quokka', allowOnline: false);
      expect(cached.status, DictionaryLookupStatus.found);
      expect(cached.entry?.source, DictionarySource.cache);
      expect(networkCalls, 1);
    });

    test('reports error when online lookup fails', () async {
      final client = MockClient((request) async {
        return http.Response('nope', 500);
      });
      final service = buildService(client: client);
      final result = await service.lookup('quokka', allowOnline: true);
      expect(result.status, DictionaryLookupStatus.error);
      expect(result.errorMessage, isNotNull);
    });
  });
}
