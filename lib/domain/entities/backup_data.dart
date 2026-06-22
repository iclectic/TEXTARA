import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/collection.dart';

class BackupData {
  final String version;
  final DateTime exportedAt;
  final List<Book> books;
  final List<Highlight> highlights;
  final List<Bookmark> bookmarks;
  final List<Collection> collections;

  const BackupData({
    required this.version,
    required this.exportedAt,
    required this.books,
    required this.highlights,
    required this.bookmarks,
    required this.collections,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt.toIso8601String(),
    'books': books.map((b) => b.toJson()).toList(),
    'highlights': highlights.map((h) => h.toJson()).toList(),
    'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
    'collections': collections.map((c) => c.toJson()).toList(),
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
    );
  }

  List<String> get validationIssues {
    final issues = <String>[];
    final bookIds = <String>{};
    final collectionIds = collections.map((c) => c.id).toSet();

    if (version.trim().isEmpty) {
      issues.add('Backup version is missing.');
    }

    for (final book in books) {
      if (book.id.trim().isEmpty) {
        issues.add('A book is missing its ID.');
        continue;
      }
      if (!bookIds.add(book.id)) {
        issues.add('Duplicate book ID found: ${book.id}.');
      }
      for (final collectionId in book.collectionIds) {
        if (!collectionIds.contains(collectionId)) {
          issues.add('Book "${book.title}" references a missing collection.');
        }
      }
    }

    for (final collection in collections) {
      if (collection.id.trim().isEmpty) {
        issues.add('A collection is missing its ID.');
      }
      if (collection.name.trim().isEmpty) {
        issues.add('A collection is missing its name.');
      }
    }

    for (final highlight in highlights) {
      if (!bookIds.contains(highlight.bookId)) {
        issues.add('A highlight references a missing book.');
      }
    }

    for (final bookmark in bookmarks) {
      if (!bookIds.contains(bookmark.bookId)) {
        issues.add('A bookmark references a missing book.');
      }
    }

    return issues;
  }

  bool get isValid => validationIssues.isEmpty;
}
