import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/collection.dart';
import 'package:textara/domain/entities/idea_thread.dart';

class BackupData {
  final String version;
  final DateTime exportedAt;
  final List<Book> books;
  final List<Highlight> highlights;
  final List<Bookmark> bookmarks;
  final List<Collection> collections;
  final List<IdeaThread> ideaThreads;
  final List<ThreadHighlightLink> threadHighlightLinks;

  const BackupData({
    required this.version,
    required this.exportedAt,
    required this.books,
    required this.highlights,
    required this.bookmarks,
    required this.collections,
    this.ideaThreads = const [],
    this.threadHighlightLinks = const [],
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt.toIso8601String(),
    'books': books.map((b) => b.toJson()).toList(),
    'highlights': highlights.map((h) => h.toJson()).toList(),
    'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
    'collections': collections.map((c) => c.toJson()).toList(),
    'ideaThreads': ideaThreads.map((thread) => thread.toJson()).toList(),
    'threadHighlightLinks': threadHighlightLinks
        .map((link) => link.toJson())
        .toList(),
  };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String? ?? '1.0.0',
      exportedAt:
          DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      books:
          (json['books'] as List<dynamic>?)
              ?.map((e) => Book.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      highlights:
          (json['highlights'] as List<dynamic>?)
              ?.map((e) => Highlight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bookmarks:
          (json['bookmarks'] as List<dynamic>?)
              ?.map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      collections:
          (json['collections'] as List<dynamic>?)
              ?.map((e) => Collection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ideaThreads:
          (json['ideaThreads'] as List<dynamic>?)
              ?.map((e) => IdeaThread.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      threadHighlightLinks:
          (json['threadHighlightLinks'] as List<dynamic>?)
              ?.map(
                (e) => ThreadHighlightLink.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  bool get isValid => version.isNotEmpty && books.every((b) => b.id.isNotEmpty);
}
