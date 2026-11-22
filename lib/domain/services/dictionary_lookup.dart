/// Offline-first dictionary stub. Never requires an account or network.
class DictionaryLookup {
  const DictionaryLookup();

  Future<DictionaryResult> define(String word) async {
    final cleaned = word.trim();
    if (cleaned.isEmpty) {
      return const DictionaryResult(
        word: '',
        available: false,
        message: 'Select a word to look up.',
      );
    }
    return DictionaryResult(
      word: cleaned,
      available: false,
      message:
          'Definition unavailable offline. A local word list can be added later — Textara never requires an account for lookup.',
    );
  }
}

class DictionaryResult {
  final String word;
  final bool available;
  final String? definition;
  final String message;

  const DictionaryResult({
    required this.word,
    required this.available,
    required this.message,
    this.definition,
  });
}
