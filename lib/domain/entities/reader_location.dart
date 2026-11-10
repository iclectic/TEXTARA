import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/book.dart';

/// Stable reading position shared by EPUB/PDF resume and manual bookmarks.
///
/// EPUB [pageIndex] is a 0-based chapter index. PDF [pageIndex] is a 1-based
/// page number (matching pdfrx). Progress is always 0.0–1.0.
class ReaderLocation extends Equatable {
  final BookFormat format;
  final int pageIndex;
  final String? chapterId;
  final double progress;

  const ReaderLocation({
    required this.format,
    required this.pageIndex,
    this.chapterId,
    this.progress = 0.0,
  });

  bool get isValid => pageIndex >= 0 && progress >= 0 && progress <= 1.0;

  String get displayLabel {
    final chapter = chapterId?.trim();
    if (chapter != null && chapter.isNotEmpty) {
      return chapter;
    }
    if (format == BookFormat.pdf) {
      return 'Page $pageIndex';
    }
    return 'Chapter ${pageIndex + 1}';
  }

  /// Stable key for per-page/chapter ink storage.
  String get inkLocationKey =>
      '${format.name}|$pageIndex|${chapterId ?? ''}';

  ReaderLocation copyWith({
    BookFormat? format,
    int? pageIndex,
    String? chapterId,
    double? progress,
  }) {
    return ReaderLocation(
      format: format ?? this.format,
      pageIndex: pageIndex ?? this.pageIndex,
      chapterId: chapterId ?? this.chapterId,
      progress: progress ?? this.progress,
    );
  }

  /// Compact token stored on bookmarks (`cfi_location`) so manual places
  /// survive independently of auto-resume fields on [Book].
  String toStableToken() => jsonEncode({
        'v': 1,
        'format': format.name,
        'pageIndex': pageIndex,
        'chapterId': chapterId,
        'progress': progress,
      });

  factory ReaderLocation.fromStableToken(
    String? token, {
    required BookFormat fallbackFormat,
  }) {
    if (token == null || token.trim().isEmpty) {
      return ReaderLocation(format: fallbackFormat, pageIndex: 0);
    }
    try {
      final decoded = jsonDecode(token);
      if (decoded is Map<String, dynamic>) {
        return ReaderLocation.fromJson(decoded, fallbackFormat: fallbackFormat);
      }
      if (decoded is Map) {
        return ReaderLocation.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
          fallbackFormat: fallbackFormat,
        );
      }
    } catch (_) {
      // Legacy plain strings are treated as chapter labels only.
      return ReaderLocation(
        format: fallbackFormat,
        pageIndex: 0,
        chapterId: token,
      );
    }
    return ReaderLocation(format: fallbackFormat, pageIndex: 0);
  }

  factory ReaderLocation.fromJson(
    Map<String, dynamic> json, {
    BookFormat fallbackFormat = BookFormat.epub,
  }) {
    final format = BookFormat.values.firstWhere(
      (e) => e.name == json['format'],
      orElse: () => fallbackFormat,
    );
    final rawProgress = (json['progress'] as num?)?.toDouble() ?? 0.0;
    return ReaderLocation(
      format: format,
      pageIndex: json['pageIndex'] as int? ?? 0,
      chapterId: json['chapterId'] as String?,
      progress: rawProgress.clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'format': format.name,
        'pageIndex': pageIndex,
        'chapterId': chapterId,
        'progress': progress,
      };

  factory ReaderLocation.fromBook(Book book) {
    return ReaderLocation(
      format: book.format,
      pageIndex: book.currentPage,
      chapterId: book.currentChapterId,
      progress: book.readingProgress.clamp(0.0, 1.0),
    );
  }

  factory ReaderLocation.fromBookmark(
    Bookmark bookmark, {
    required BookFormat format,
  }) {
    final fromToken = ReaderLocation.fromStableToken(
      bookmark.cfiLocation,
      fallbackFormat: format,
    );
    if (bookmark.cfiLocation != null &&
        bookmark.cfiLocation!.trim().startsWith('{')) {
      return fromToken.copyWith(
        chapterId: fromToken.chapterId ?? bookmark.chapterId,
        pageIndex: fromToken.pageIndex > 0 || format == BookFormat.epub
            ? fromToken.pageIndex
            : bookmark.pageNumber,
      );
    }
    return ReaderLocation(
      format: format,
      pageIndex: bookmark.pageNumber,
      chapterId: bookmark.chapterId,
      progress: fromToken.progress,
    );
  }

  /// Nearest stable EPUB chapter when typography changes reflow pages.
  /// Chapter index itself is already font-independent in Textara's model.
  ReaderLocation preservedAcrossTypographyChange() => this;

  @override
  List<Object?> get props => [format, pageIndex, chapterId, progress];
}
