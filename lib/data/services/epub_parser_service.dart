import 'dart:io';
import 'dart:typed_data';
import 'package:epub_pro/epub_pro.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:textara/domain/entities/epub_content.dart';

class EpubParserService {
  Future<EpubBook> parseEpub(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('EPUB file not found', filePath);
    }
    final bytes = await file.readAsBytes();
    return await EpubReader.readBook(bytes);
  }

  String extractTitle(EpubBook book) {
    return book.title ?? 'Untitled';
  }

  String extractAuthor(EpubBook book) {
    return book.author ?? 'Unknown Author';
  }

  String? extractDescription(EpubBook book) {
    return book.schema?.package?.metadata?.description;
  }

  String? extractLanguage(EpubBook book) {
    final langs = book.schema?.package?.metadata?.languages;
    if (langs != null && langs.isNotEmpty) {
      return langs.first;
    }
    return null;
  }

  String? extractPublisher(EpubBook book) {
    final pubs = book.schema?.package?.metadata?.publishers;
    if (pubs != null && pubs.isNotEmpty) {
      return pubs.first;
    }
    return null;
  }

  Uint8List? extractCoverImage(EpubBook book) {
    final cover = book.coverImage;
    if (cover != null) {
      return Uint8List.fromList(cover.getBytes());
    }
    return null;
  }

  EpubTableOfContents extractTableOfContents(EpubBook book) {
    final chapters = <TocChapter>[];
    final epubChapters = book.chapters;
    for (int i = 0; i < epubChapters.length; i++) {
      chapters.add(_convertChapter(epubChapters[i], i));
    }
    return EpubTableOfContents(chapters: chapters);
  }

  TocChapter _convertChapter(EpubChapter ref, int order) {
    final subChapters = <TocChapter>[];
    final subs = ref.subChapters;
    for (int i = 0; i < subs.length; i++) {
      subChapters.add(_convertChapter(subs[i], i));
    }
    return TocChapter(
      id: ref.contentFileName ?? 'chapter_$order',
      title: ref.title ?? 'Chapter ${order + 1}',
      htmlContent: ref.htmlContent,
      order: order,
      subChapters: subChapters,
    );
  }

  List<String> getChapterHtmlContents(EpubBook book) {
    final chapters = book.chapters;
    return chapters
        .map((c) => c.htmlContent ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
  }

  String stripHtml(String html) {
    final document = html_parser.parse(html);
    return document.body?.text ?? '';
  }

  List<MapEntry<String, String>> getChapterTexts(EpubBook book) {
    final chapters = book.chapters;
    final results = <MapEntry<String, String>>[];
    for (final chapter in chapters) {
      final html = chapter.htmlContent ?? '';
      if (html.isNotEmpty) {
        final text = stripHtml(html);
        final chapterId = chapter.contentFileName ?? '';
        results.add(MapEntry(chapterId, text));
      }
    }
    return results;
  }

  int estimateTotalPages(EpubBook book, {int wordsPerPage = 250}) {
    int totalWords = 0;
    for (final chapter in book.chapters) {
      final text = stripHtml(chapter.htmlContent ?? '');
      totalWords += text.split(RegExp(r'\s+')).length;
    }
    return (totalWords / wordsPerPage).ceil().clamp(1, 999999);
  }
}
