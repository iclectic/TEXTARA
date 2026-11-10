import 'package:flutter_test/flutter_test.dart';
import 'package:textara/domain/entities/dictionary_entry.dart';

void main() {
  group('DictionaryEntry', () {
    test('round-trips through JSON', () {
      const original = DictionaryEntry(
        word: 'hope',
        senses: [
          DictionarySense(
            partOfSpeech: 'noun',
            definition: 'a feeling of expectation',
            example: 'Hold onto hope.',
          ),
        ],
        source: DictionarySource.offline,
      );

      final restored = DictionaryEntry.fromJson(original.toJson());
      expect(restored.word, 'hope');
      expect(restored.senses, hasLength(1));
      expect(restored.senses.first.partOfSpeech, 'noun');
      expect(restored.senses.first.example, 'Hold onto hope.');
      expect(restored.source, DictionarySource.offline);
    });

    test('fromJson tolerates missing senses', () {
      final restored = DictionaryEntry.fromJson({'word': 'void'});
      expect(restored.word, 'void');
      expect(restored.senses, isEmpty);
      expect(restored.hasSenses, isFalse);
    });
  });

  group('DictionaryLookupResult', () {
    test('factories set expected status', () {
      expect(
        DictionaryLookupResult.loading('hope').status,
        DictionaryLookupStatus.loading,
      );
      expect(
        DictionaryLookupResult.notFound('zzz').status,
        DictionaryLookupStatus.notFound,
      );
      expect(
        DictionaryLookupResult.error('hope', 'offline').errorMessage,
        'offline',
      );
    });
  });
}
