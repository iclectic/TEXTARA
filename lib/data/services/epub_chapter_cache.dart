import 'package:epub_pro/epub_pro.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:textara/data/services/epub_parser_service.dart';

class CachedChapter {
  final String id;
  final String title;
  final String text;
  final String htmlContent;
  final int order;

  const CachedChapter({
    required this.id,
    required this.title,
    required this.text,
    required this.htmlContent,
    required this.order,
  });
}

/// Session LRU cache of parsed EPUB chapter text keyed by file path.
class EpubChapterCache {
  EpubChapterCache(this._parser, {this.maxEntries = 4});

  final EpubParserService _parser;
  final int maxEntries;
  final Map<String, List<CachedChapter>> _cache = {};
  final List<String> _order = [];

  Future<List<CachedChapter>> chaptersFor(String filePath) async {
    final hit = _cache[filePath];
    if (hit != null) {
      _order.remove(filePath);
      _order.add(filePath);
      return hit;
    }

    final epubBook = await _parser.parseEpub(filePath);
    final loaded = _extract(epubBook);
    _cache[filePath] = loaded;
    _order.add(filePath);
    while (_order.length > maxEntries) {
      final evict = _order.removeAt(0);
      _cache.remove(evict);
    }
    return loaded;
  }

  void invalidate(String filePath) {
    _cache.remove(filePath);
    _order.remove(filePath);
  }

  List<CachedChapter> _extract(EpubBook epubBook) {
    final chapters = epubBook.chapters;
    final loaded = <CachedChapter>[];
    var readableIndex = 0;
    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final html = chapter.htmlContent ?? '';
      if (html.isEmpty) continue;
      final document = html_parser.parse(html);
      final text = document.body?.text ?? '';
      if (text.trim().isEmpty) continue;
      final title = chapter.title ?? 'Chapter ${readableIndex + 1}';
      loaded.add(
        CachedChapter(
          id: chapter.contentFileName ?? 'chapter_$readableIndex',
          title: title,
          text: text.trim(),
          htmlContent: html,
          order: readableIndex,
        ),
      );
      readableIndex++;
    }
    return loaded;
  }
}
