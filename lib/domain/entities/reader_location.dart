import 'package:equatable/equatable.dart';

/// Stable reader position for EPUB (chapter + optional offset) or PDF (page).
class ReaderLocation extends Equatable {
  final int pageIndex;
  final int totalPages;
  final String? chapterId;
  final String? chapterTitle;
  final int? textOffset;
  final bool isEpub;

  const ReaderLocation({
    required this.pageIndex,
    required this.totalPages,
    this.chapterId,
    this.chapterTitle,
    this.textOffset,
    this.isEpub = true,
  });

  double get progress =>
      totalPages > 0 ? (pageIndex / totalPages).clamp(0.0, 1.0) : 0.0;

  /// Honest chrome label: "Chapter 3 of 12" or "Page 3 of 12".
  String get positionLabel {
    final current = pageIndex + 1;
    final total = totalPages < 1 ? 1 : totalPages;
    if (isEpub) {
      return 'Chapter $current of $total';
    }
    return 'Page $current of $total';
  }

  ReaderLocation copyWith({
    int? pageIndex,
    int? totalPages,
    String? chapterId,
    String? chapterTitle,
    int? textOffset,
    bool? isEpub,
  }) {
    return ReaderLocation(
      pageIndex: pageIndex ?? this.pageIndex,
      totalPages: totalPages ?? this.totalPages,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      textOffset: textOffset ?? this.textOffset,
      isEpub: isEpub ?? this.isEpub,
    );
  }

  @override
  List<Object?> get props => [
    pageIndex,
    totalPages,
    chapterId,
    chapterTitle,
    textOffset,
    isEpub,
  ];
}
