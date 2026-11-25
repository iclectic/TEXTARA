import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/data/services/incoming_bridge.dart';
import 'package:textara/data/services/incoming_requests.dart';

void main() {
  group('IncomingPayload.parse', () {
    test('keeps epub and pdf paths and book ids', () {
      final requests = IncomingPayload.parse([
        {'type': 'file', 'value': '/tmp/incoming/Welcome.epub'},
        {'type': 'file', 'value': r'C:\Books\notes.PDF'},
        {'type': 'book', 'value': 'book-id_1'},
      ]);

      expect(requests, hasLength(3));
      expect(requests[0].kind, IncomingKind.file);
      expect(requests[1].value, r'C:\Books\notes.PDF');
      expect(requests[2].kind, IncomingKind.book);
      expect(requests[2].value, 'book-id_1');
    });

    test('drops other files, empty values, and malformed payloads', () {
      final requests = IncomingPayload.parse([
        {'type': 'file', 'value': '/tmp/notes.txt'},
        {'type': 'file', 'value': '   '},
        {'type': 'book', 'value': '../secrets'},
        {'type': 'book', 'value': 'has space'},
        'not-a-map',
        {'type': 'other', 'value': 'abc'},
      ]);

      expect(requests, isEmpty);
    });

    test('ignores a non-list payload', () {
      expect(IncomingPayload.parse(null), isEmpty);
      expect(IncomingPayload.parse({'type': 'file'}), isEmpty);
    });
  });

  test('IncomingBridge drains a pending batch once', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final channel = const MethodChannel(AppConstants.incomingChannel);
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'takePending') return null;
          calls += 1;
          if (calls == 1) {
            return [
              {'type': 'file', 'value': '/tmp/book.epub'},
              {'type': 'book', 'value': 'abc-123'},
              {'type': 'file', 'value': '/tmp/notes.txt'},
            ];
          }
          return <Map<String, String>>[];
        });

    final seen = <IncomingRequest>[];
    final bridge = IncomingBridge(channel: channel);
    bridge.onRequests = (requests) async {
      seen.addAll(requests);
    };
    await bridge.start();
    await bridge.drain();

    expect(seen, hasLength(2));
    expect(seen.first.value, '/tmp/book.epub');
    expect(seen.last.kind, IncomingKind.book);
    bridge.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
