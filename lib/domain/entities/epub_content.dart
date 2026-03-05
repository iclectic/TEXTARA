class TocChapter {
  final String id;
  final String title;
  final String? htmlContent;
  final int order;
  final List<TocChapter> subChapters;

  const TocChapter({
    required this.id,
    required this.title,
    this.htmlContent,
    required this.order,
    this.subChapters = const [],
  });
}

class EpubTableOfContents {
  final List<TocChapter> chapters;

  const EpubTableOfContents({this.chapters = const []});

  int get totalChapters => _countChapters(chapters);

  int _countChapters(List<TocChapter> chaps) {
    int count = chaps.length;
    for (final c in chaps) {
      count += _countChapters(c.subChapters);
    }
    return count;
  }
}

class EpubSearchResult {
  final String chapterId;
  final String chapterTitle;
  final String excerpt;
  final int offset;

  const EpubSearchResult({
    required this.chapterId,
    required this.chapterTitle,
    required this.excerpt,
    required this.offset,
  });
}
