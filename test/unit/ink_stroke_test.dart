import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textara/domain/entities/ink_stroke.dart';
import 'package:textara/domain/entities/reader_location.dart';
import 'package:textara/core/constants/enums.dart';

void main() {
  group('InkStroke', () {
    test('points encode/decode round-trip with pressure', () {
      const points = [
        InkPoint(x: 10, y: 20, pressure: 0.2),
        InkPoint(x: 30, y: 40, pressure: 0.9),
      ];
      final encoded = InkStroke(
        id: '1',
        bookId: 'b',
        locationKey: 'epub|0|Ch',
        tool: InkTool.pen,
        colorValue: 0xFF112233,
        baseWidth: 2.5,
        points: points,
        createdAt: DateTime(2026, 1, 1),
      ).encodePoints();

      final decoded = InkStroke.decodePoints(encoded);
      expect(decoded, hasLength(2));
      expect(decoded[0].x, 10);
      expect(decoded[0].pressure, closeTo(0.2, 0.001));
      expect(decoded[1].y, 40);
      expect(decoded[1].pressure, closeTo(0.9, 0.001));
    });

    test('json round-trip preserves tool and location', () {
      final stroke = InkStroke(
        id: 's1',
        bookId: 'book',
        locationKey: 'pdf|12|',
        tool: InkTool.highlighter,
        colorValue: const Color(0x88FFF176).toARGB32(),
        baseWidth: 6,
        points: const [
          InkPoint(x: 1, y: 2),
          InkPoint(x: 3, y: 4, pressure: 0.7),
        ],
        createdAt: DateTime(2026, 3, 4, 5, 6, 7),
      );

      final restored = InkStroke.fromJson(stroke.toJson());
      expect(restored.id, 's1');
      expect(restored.tool, InkTool.highlighter);
      expect(restored.locationKey, 'pdf|12|');
      expect(restored.points, hasLength(2));
      expect(restored.baseWidth, 6);
    });

    test('eraser intersection detects nearby strokes', () {
      final stroke = InkStroke(
        id: 's',
        bookId: 'b',
        locationKey: 'k',
        tool: InkTool.pen,
        colorValue: 0xFF000000,
        baseWidth: 2,
        points: const [
          InkPoint(x: 100, y: 100),
          InkPoint(x: 120, y: 100),
        ],
        createdAt: DateTime(2026, 1, 1),
      );

      expect(
        stroke.intersectsEraserPath(const [InkPoint(x: 110, y: 105)]),
        isTrue,
      );
      expect(
        stroke.intersectsEraserPath(const [InkPoint(x: 400, y: 400)]),
        isFalse,
      );
    });
  });

  group('ReaderLocation.inkLocationKey', () {
    test('keys page and chapter stably', () {
      const epub = ReaderLocation(
        format: BookFormat.epub,
        pageIndex: 2,
        chapterId: 'Storm',
        progress: 0.2,
      );
      const pdf = ReaderLocation(
        format: BookFormat.pdf,
        pageIndex: 9,
        progress: 0.1,
      );
      expect(epub.inkLocationKey, 'epub|2|Storm');
      expect(pdf.inkLocationKey, 'pdf|9|');
      // Progress must not affect ink key (typography/scroll independent).
      expect(
        epub.copyWith(progress: 0.9).inkLocationKey,
        epub.inkLocationKey,
      );
    });
  });

  group('InkTool', () {
    test('off is distinct from drawing tools', () {
      expect(InkTool.off.name, 'off');
      expect(InkTool.values.contains(InkTool.pen), isTrue);
      expect(InkTool.values.contains(InkTool.eraser), isTrue);
      expect(InkTool.values.contains(InkTool.highlighter), isTrue);
    });
  });
}
