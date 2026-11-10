/// Extracts and normalizes a lookup headword from selected reader text.
class DictionaryWordNormalizer {
  DictionaryWordNormalizer._();

  static final RegExp _tokenPattern = RegExp(r"[A-Za-z][A-Za-z'-]*");

  /// Returns a lowercase headword suitable for lexicon lookup, or null when
  /// the selection does not contain an alphabetic token.
  static String? headwordFromSelection(String selection) {
    final trimmed = selection.trim();
    if (trimmed.isEmpty) return null;

    final match = _tokenPattern.firstMatch(trimmed);
    if (match == null) return null;

    var word = match.group(0)!.toLowerCase();
    word = word.replaceAll(RegExp(r"^'+|'+$"), '');
    if (word.isEmpty) return null;

    // Mild inflection stripping for common English reader selections.
    word = _stripSimpleInflection(word);
    return word.isEmpty ? null : word;
  }

  static String _stripSimpleInflection(String word) {
    if (word.length <= 3) return word;

    if (word.endsWith("'s")) {
      return word.substring(0, word.length - 2);
    }
    if (word.endsWith('ies') && word.length > 4) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.endsWith('ves') && word.length > 4) {
      return '${word.substring(0, word.length - 3)}f';
    }
    if (word.endsWith('ing') && word.length > 5) {
      final stem = word.substring(0, word.length - 3);
      if (stem.endsWith(stem[stem.length - 1]) && stem.length > 3) {
        // running -> runn -> run
        return stem.substring(0, stem.length - 1);
      }
      return stem;
    }
    if (word.endsWith('ed') && word.length > 4) {
      final stem = word.substring(0, word.length - 2);
      if (stem.endsWith(stem[stem.length - 1]) && stem.length > 3) {
        return stem.substring(0, stem.length - 1);
      }
      return stem;
    }
    if (word.endsWith('es') && word.length > 4) {
      return word.substring(0, word.length - 2);
    }
    if (word.endsWith('s') && !word.endsWith('ss') && word.length > 3) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }
}
