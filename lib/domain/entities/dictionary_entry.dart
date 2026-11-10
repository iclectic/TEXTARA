import 'package:equatable/equatable.dart';

enum DictionarySource { offline, cache, online }

class DictionarySense extends Equatable {
  final String partOfSpeech;
  final String definition;
  final String? example;

  const DictionarySense({
    required this.partOfSpeech,
    required this.definition,
    this.example,
  });

  Map<String, dynamic> toJson() => {
    'pos': partOfSpeech,
    'definition': definition,
    if (example != null) 'example': example,
  };

  factory DictionarySense.fromJson(Map<String, dynamic> json) {
    return DictionarySense(
      partOfSpeech:
          (json['pos'] as String?) ??
          (json['partOfSpeech'] as String?) ??
          'unknown',
      definition: (json['definition'] as String?) ?? '',
      example: json['example'] as String?,
    );
  }

  @override
  List<Object?> get props => [partOfSpeech, definition, example];
}

class DictionaryEntry extends Equatable {
  final String word;
  final List<DictionarySense> senses;
  final DictionarySource source;

  const DictionaryEntry({
    required this.word,
    required this.senses,
    this.source = DictionarySource.offline,
  });

  bool get hasSenses => senses.isNotEmpty;

  DictionaryEntry copyWith({
    String? word,
    List<DictionarySense>? senses,
    DictionarySource? source,
  }) {
    return DictionaryEntry(
      word: word ?? this.word,
      senses: senses ?? this.senses,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'senses': senses.map((s) => s.toJson()).toList(),
    'source': source.name,
  };

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    final rawSenses = json['senses'] as List<dynamic>? ?? const [];
    return DictionaryEntry(
      word: (json['word'] as String? ?? '').toLowerCase(),
      senses: rawSenses
          .whereType<Map>()
          .map(
            (s) => DictionarySense.fromJson(
              s.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((s) => s.definition.trim().isNotEmpty)
          .toList(),
      source: DictionarySource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => DictionarySource.offline,
      ),
    );
  }

  @override
  List<Object?> get props => [word, senses, source];
}

enum DictionaryLookupStatus { idle, loading, found, notFound, error }

class DictionaryLookupResult extends Equatable {
  final String query;
  final DictionaryLookupStatus status;
  final DictionaryEntry? entry;
  final String? errorMessage;
  final bool usedNetwork;

  const DictionaryLookupResult({
    required this.query,
    required this.status,
    this.entry,
    this.errorMessage,
    this.usedNetwork = false,
  });

  const DictionaryLookupResult.idle()
    : query = '',
      status = DictionaryLookupStatus.idle,
      entry = null,
      errorMessage = null,
      usedNetwork = false;

  factory DictionaryLookupResult.loading(String query) =>
      DictionaryLookupResult(
        query: query,
        status: DictionaryLookupStatus.loading,
      );

  factory DictionaryLookupResult.found(
    DictionaryEntry entry, {
    bool usedNetwork = false,
  }) {
    return DictionaryLookupResult(
      query: entry.word,
      status: DictionaryLookupStatus.found,
      entry: entry,
      usedNetwork: usedNetwork,
    );
  }

  factory DictionaryLookupResult.notFound(String query) =>
      DictionaryLookupResult(
        query: query,
        status: DictionaryLookupStatus.notFound,
      );

  factory DictionaryLookupResult.error(String query, String message) =>
      DictionaryLookupResult(
        query: query,
        status: DictionaryLookupStatus.error,
        errorMessage: message,
      );

  @override
  List<Object?> get props => [query, status, entry, errorMessage, usedNetwork];
}
