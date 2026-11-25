import 'package:flutter/services.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/data/services/incoming_requests.dart';

/// Talks to the Android, iOS, and macOS shells that receive shared books,
/// document opens, drops, and `textara://book/<id>` links.
class IncomingBridge {
  IncomingBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConstants.incomingChannel);

  final MethodChannel _channel;
  Future<void> Function(List<IncomingRequest> requests)? onRequests;

  bool _draining = false;
  bool _again = false;

  Future<void> start() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'incomingAvailable') {
        await drain();
      }
    });
    await drain();
  }

  Future<void> drain() async {
    if (_draining) {
      _again = true;
      return;
    }
    _draining = true;
    try {
      while (true) {
        _again = false;
        final raw = await _channel.invokeMethod<dynamic>('takePending');
        final requests = IncomingPayload.parse(raw);
        if (requests.isEmpty) break;
        final handler = onRequests;
        if (handler != null) {
          await handler(requests);
        }
        if (!_again) break;
      }
    } on MissingPluginException {
      // Desktop tests and platforms without the shell channel.
    } on PlatformException {
      // A bad native payload should not take down the library.
    } finally {
      _draining = false;
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
