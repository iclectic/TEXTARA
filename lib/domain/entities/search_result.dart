import 'package:equatable/equatable.dart';
import 'package:textara/domain/entities/book.dart';

enum SearchMatchType { metadata, fullText }

class SearchResult extends Equatable {
  final Book book;
  final SearchMatchType matchType;
  final String? chapterId;
  final String? excerpt;
  final double rank;

  const SearchResult({
    required this.book,
    required this.matchType,
    this.chapterId,
    this.excerpt,
    required this.rank,
  });

  bool get isFullTextMatch => matchType == SearchMatchType.fullText;

  @override
  List<Object?> get props => [book, matchType, chapterId, excerpt, rank];
}
