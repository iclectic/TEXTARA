import 'package:flutter_test/flutter_test.dart';
import 'package:textara/domain/services/dictionary_lookup.dart';

void main() {
  test('DictionaryLookup returns offline unavailable for words', () async {
    const lookup = DictionaryLookup();
    final result = await lookup.define('attention');
    expect(result.available, isFalse);
    expect(result.word, 'attention');
    expect(result.message.toLowerCase(), contains('offline'));
  });
}
