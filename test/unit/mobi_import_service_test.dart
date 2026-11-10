import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:textara/data/services/mobi_import_service.dart';

Uint8List _buildPalmDb({
  required int encryption,
  required int compression,
  required List<Uint8List> records,
}) {
  // Minimal PalmDB with BOOK/MOBI creator and N records.
  final recordCount = records.length;
  final headerSize = 78 + recordCount * 8;
  var offset = headerSize;
  final offsets = <int>[];
  for (final record in records) {
    offsets.add(offset);
    offset += record.length;
  }

  final bytes = Uint8List(offset);
  // name
  final name = 'DEMO BOOK'.codeUnits;
  bytes.setRange(0, name.length, name);
  // type / creator
  bytes.setRange(60, 64, 'BOOK'.codeUnits);
  bytes.setRange(64, 68, 'MOBI'.codeUnits);
  // record count
  bytes[76] = (recordCount >> 8) & 0xff;
  bytes[77] = recordCount & 0xff;
  for (var i = 0; i < recordCount; i++) {
    final o = offsets[i];
    final base = 78 + i * 8;
    bytes[base] = (o >> 24) & 0xff;
    bytes[base + 1] = (o >> 16) & 0xff;
    bytes[base + 2] = (o >> 8) & 0xff;
    bytes[base + 3] = o & 0xff;
  }

  // Record 0 = PalmDOC header (16 bytes) + padding
  final rec0 = Uint8List(16);
  rec0[0] = (compression >> 8) & 0xff;
  rec0[1] = compression & 0xff;
  // text length
  rec0[4] = 0;
  rec0[5] = 0;
  rec0[6] = 0;
  rec0[7] = 20;
  // text record count (records after header)
  final textCount = recordCount - 1;
  rec0[8] = (textCount >> 8) & 0xff;
  rec0[9] = textCount & 0xff;
  rec0[10] = 0x10;
  rec0[11] = 0x00; // record size
  rec0[12] = (encryption >> 8) & 0xff;
  rec0[13] = encryption & 0xff;

  // Write records into buffer
  bytes.setRange(offsets[0], offsets[0] + rec0.length, rec0);
  for (var i = 1; i < recordCount; i++) {
    bytes.setRange(
      offsets[i],
      offsets[i] + records[i].length,
      records[i],
    );
  }
  // records[0] placeholder ignored; we wrote rec0
  return bytes;
}

void main() {
  final service = MobiImportService();

  test('detects PalmDB MOBI container', () {
    final bytes = _buildPalmDb(
      encryption: 0,
      compression: 1,
      records: [
        Uint8List(16),
        Uint8List.fromList('Hello from mobi'.codeUnits),
      ],
    );
    expect(service.looksLikeMobi(bytes), isTrue);
    expect(service.hasDrm(bytes), isFalse);
  });

  test('rejects DRM-protected MOBI with clear message', () {
    final bytes = _buildPalmDb(
      encryption: 2,
      compression: 1,
      records: [
        Uint8List(16),
        Uint8List.fromList('secret'.codeUnits),
      ],
    );
    expect(service.hasDrm(bytes), isTrue);
    expect(
      () => service.convertBytes(bytes, fallbackTitle: 'DRM'),
      throwsA(
        isA<MobiImportException>().having(
          (e) => e.kind,
          'kind',
          MobiImportFailureKind.drmProtected,
        ),
      ),
    );
  });

  test('rejects HUFF/CDIC compression with guidance', () {
    final bytes = _buildPalmDb(
      encryption: 0,
      compression: 17480,
      records: [
        Uint8List(16),
        Uint8List.fromList('x'.codeUnits),
      ],
    );
    expect(
      () => service.convertBytes(bytes, fallbackTitle: 'KF8'),
      throwsA(
        isA<MobiImportException>().having(
          (e) => e.kind,
          'kind',
          MobiImportFailureKind.unsupportedCompression,
        ),
      ),
    );
  });

  test('converts uncompressed DRM-free text records', () {
    final bytes = _buildPalmDb(
      encryption: 0,
      compression: 1,
      records: [
        Uint8List(16),
        Uint8List.fromList('<html><body><p>Hello MOBI</p></body></html>'.codeUnits),
      ],
    );
    final book = service.convertBytes(bytes, fallbackTitle: 'Demo');
    expect(book.chapters, isNotEmpty);
    expect(book.chapters.first.text, contains('Hello MOBI'));
  });
}
