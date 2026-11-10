import 'package:flutter_test/flutter_test.dart';
import 'package:textara/data/services/fb2_parser_service.dart';

void main() {
  final parser = Fb2ParserService();

  test('parses FictionBook metadata and sections', () {
    const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<FictionBook>
  <description>
    <title-info>
      <book-title>River Watch</book-title>
      <author>
        <first-name>Ada</first-name>
        <last-name>Lovelace</last-name>
      </author>
      <lang>en</lang>
    </title-info>
  </description>
  <body>
    <section>
      <title><p>Opening</p></title>
      <p>The river was quiet.</p>
      <p>Birds waited.</p>
    </section>
    <section>
      <title><p>Crossing</p></title>
      <p>A bridge appeared.</p>
    </section>
  </body>
</FictionBook>
''';

    final book = parser.parseXml(xml, fallbackTitle: 'Fallback');
    expect(book.title, 'River Watch');
    expect(book.author, 'Ada Lovelace');
    expect(book.language, 'en');
    expect(book.chapters, hasLength(2));
    expect(book.chapters.first.title, 'Opening');
    expect(book.chapters.first.text, contains('river was quiet'));
    expect(book.chapters[1].title, 'Crossing');
  });

  test('rejects non-fb2 root', () {
    expect(
      () => parser.parseXml('<html></html>', fallbackTitle: 'x'),
      throwsA(isA<FormatException>()),
    );
  });
}
