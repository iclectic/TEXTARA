import 'dart:io';

import 'package:xml/xml.dart';
import 'package:textara/domain/entities/parsed_text_book.dart';

class Fb2ParserService {
  Future<ParsedTextBook> parseFile(String filePath, {String? fallbackTitle}) async {
    final raw = await File(filePath).readAsString();
    return parseXml(raw, fallbackTitle: fallbackTitle ?? _titleFromPath(filePath));
  }

  ParsedTextBook parseXml(String raw, {required String fallbackTitle}) {
    final document = XmlDocument.parse(raw);
    final root = document.rootElement;
    if (root.name.local.toLowerCase() != 'fictionbook') {
      throw const FormatException('Not a FictionBook (FB2) document.');
    }

    final titleInfo = _firstDescendant(root, 'title-info');
    final title = _textOf(_firstDescendant(titleInfo, 'book-title')) ??
        fallbackTitle;
    final author = _authorFrom(titleInfo) ?? 'Unknown Author';
    final language = _textOf(_firstDescendant(titleInfo, 'lang'));

    final bodies = root.findElements('body').where((body) {
      final name = body.getAttribute('name');
      // Skip notes/comments bodies when present.
      if (name == null || name.isEmpty) return true;
      return name != 'notes' && name != 'comments';
    }).toList();

    final chapters = <TextChapter>[];
    for (final body in bodies) {
      final sections = body.findElements('section').toList();
      if (sections.isEmpty) {
        final text = _collectParagraphs(body);
        if (text.trim().isNotEmpty) {
          chapters.add(TextChapter(title: title, text: text.trim()));
        }
        continue;
      }
      for (var i = 0; i < sections.length; i++) {
        final section = sections[i];
        final sectionTitle =
            _sectionTitle(section) ?? 'Section ${chapters.length + 1}';
        final text = _collectParagraphs(section);
        if (text.trim().isEmpty) continue;
        chapters.add(TextChapter(title: sectionTitle, text: text.trim()));
      }
    }

    if (chapters.isEmpty) {
      chapters.add(const TextChapter(title: 'Text', text: ''));
    }

    return ParsedTextBook(
      title: title.trim().isEmpty ? fallbackTitle : title.trim(),
      author: author,
      language: language,
      chapters: chapters,
    );
  }

  XmlElement? _firstDescendant(XmlNode? node, String localName) {
    if (node == null) return null;
    for (final element in node.descendantElements) {
      if (element.name.local.toLowerCase() == localName.toLowerCase()) {
        return element;
      }
    }
    return null;
  }

  String? _authorFrom(XmlElement? titleInfo) {
    final author = _firstDescendant(titleInfo, 'author');
    if (author == null) return null;
    final first = _textOf(_firstDescendant(author, 'first-name')) ?? '';
    final middle = _textOf(_firstDescendant(author, 'middle-name')) ?? '';
    final last = _textOf(_firstDescendant(author, 'last-name')) ?? '';
    final nick = _textOf(_firstDescendant(author, 'nickname'));
    final parts = [first, middle, last]
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    if (nick != null && nick.trim().isNotEmpty) return nick.trim();
    return null;
  }

  String? _sectionTitle(XmlElement section) {
    final titleEl = section.findElements('title').firstOrNull;
    if (titleEl == null) return null;
    final text = titleEl.descendants
        .whereType<XmlText>()
        .map((t) => t.value.trim())
        .where((t) => t.isNotEmpty)
        .join(' ');
    return text.isEmpty ? null : text;
  }

  String _collectParagraphs(XmlElement root) {
    final buffer = StringBuffer();
    for (final element in root.descendants.whereType<XmlElement>()) {
      final name = element.name.local.toLowerCase();
      if (name == 'p' || name == 'v' || name == 'text-author' || name == 'subtitle') {
        // Skip nested title paragraphs already used as chapter titles when
        // they are direct children of <title>.
        if (element.parent is XmlElement &&
            (element.parent as XmlElement).name.local.toLowerCase() == 'title') {
          continue;
        }
        final text = element.innerText.trim();
        if (text.isEmpty) continue;
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.writeln(text);
      }
    }
    return buffer.toString();
  }

  String? _textOf(XmlElement? element) {
    if (element == null) return null;
    final text = element.innerText.trim();
    return text.isEmpty ? null : text;
  }

  String _titleFromPath(String path) {
    final name = path.split('/').last.split('\\').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
