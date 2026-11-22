import 'package:flutter_test/flutter_test.dart';
import 'package:textara/domain/entities/reader_location.dart';

void main() {
  group('ReaderLocation', () {
    test('positionLabel uses Chapter for EPUB (1-based)', () {
      const location = ReaderLocation(
        pageIndex: 2,
        totalPages: 10,
        isEpub: true,
      );
      expect(location.positionLabel, 'Chapter 3 of 10');
    });

    test('positionLabel uses Page for PDF', () {
      const location = ReaderLocation(
        pageIndex: 0,
        totalPages: 40,
        isEpub: false,
      );
      expect(location.positionLabel, 'Page 1 of 40');
    });

    test('progress clamps using pageIndex / totalPages', () {
      const location = ReaderLocation(pageIndex: 5, totalPages: 10);
      expect(location.progress, 0.5);
    });
  });
}
