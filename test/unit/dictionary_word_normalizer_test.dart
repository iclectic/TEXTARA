import 'package:flutter_test/flutter_test.dart';
import 'package:textara/data/services/dictionary_word_normalizer.dart';

void main() {
  group('DictionaryWordNormalizer', () {
    test('extracts a single word selection', () {
      expect(DictionaryWordNormalizer.headwordFromSelection('hope'), 'hope');
    });

    test('uses the first alphabetic token from a phrase', () {
      expect(
        DictionaryWordNormalizer.headwordFromSelection('hope springs eternal'),
        'hope',
      );
    });

    test('strips punctuation and casing', () {
      expect(
        DictionaryWordNormalizer.headwordFromSelection('"Courage,"'),
        'courage',
      );
    });

    test('strips possessive and plural forms lightly', () {
      expect(
        DictionaryWordNormalizer.headwordFromSelection("reader's"),
        'reader',
      );
      expect(DictionaryWordNormalizer.headwordFromSelection('books'), 'book');
    });

    test('returns null for empty or non-word selections', () {
      expect(DictionaryWordNormalizer.headwordFromSelection('   '), isNull);
      expect(DictionaryWordNormalizer.headwordFromSelection('…'), isNull);
      expect(DictionaryWordNormalizer.headwordFromSelection('123'), isNull);
    });
  });
}
