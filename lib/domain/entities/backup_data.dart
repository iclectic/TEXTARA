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

  List<String> get validationErrors {
    final errors = <String>[];
    if (version.trim().isEmpty) {
      errors.add('Backup version is missing.');
    }

    final bookIds = <String>{};
    for (final book in books) {
      if (book.id.trim().isEmpty) {
        errors.add('A book is missing its id.');
      } else if (!bookIds.add(book.id)) {
        errors.add('Duplicate book id: ${book.id}.');
      }
      if (book.filePath.trim().isEmpty) {
        errors.add('Book ${book.id} is missing its file path.');
      }
    }

    final highlightIds = <String>{};
    for (final highlight in highlights) {
      if (highlight.id.trim().isEmpty) {
        errors.add('A highlight is missing its id.');
      } else if (!highlightIds.add(highlight.id)) {
        errors.add('Duplicate highlight id: ${highlight.id}.');
      }
      if (!bookIds.contains(highlight.bookId)) {
        errors.add('Highlight ${highlight.id} points at a missing book.');
      }
    }

    final bookmarkIds = <String>{};
    for (final bookmark in bookmarks) {
      if (bookmark.id.trim().isEmpty) {
        errors.add('A bookmark is missing its id.');
      } else if (!bookmarkIds.add(bookmark.id)) {
        errors.add('Duplicate bookmark id: ${bookmark.id}.');
      }
      if (!bookIds.contains(bookmark.bookId)) {
        errors.add('Bookmark ${bookmark.id} points at a missing book.');
      }
    }

    final threadIds = <String>{};
    for (final thread in ideaThreads) {
      if (thread.id.trim().isEmpty) {
        errors.add('An idea thread is missing its id.');
      } else if (!threadIds.add(thread.id)) {
        errors.add('Duplicate idea thread id: ${thread.id}.');
      }
    }

    final threadLinks = <String>{};
    for (final link in threadHighlightLinks) {
      final linkId = '${link.threadId}:${link.highlightId}';
      if (!threadLinks.add(linkId)) {
        errors.add('Duplicate thread highlight link: $linkId.');
      }
      if (!threadIds.contains(link.threadId)) {
        errors.add('Thread link points at a missing idea thread.');
      }
      if (!highlightIds.contains(link.highlightId)) {
        errors.add('Thread link points at a missing highlight.');
      }
    }

    return errors;
  }

  bool get isValid => validationErrors.isEmpty;
}
