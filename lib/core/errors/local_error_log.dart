import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Appends unexpected errors to a local diagnostics file (opt-in remote later).
class LocalErrorLog {
  LocalErrorLog._();

  static const fileName = 'textara_errors.log';
  static final List<String> _ring = <String>[];
  static const int _ringLimit = 50;

  /// In-memory recent entries for Settings diagnostics (Milestone 6).
  static List<String> get recent => List.unmodifiable(_ring);

  static Future<void> record(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) async {
    final stamp = DateTime.now().toUtc().toIso8601String();
    final header = context == null ? stamp : '$stamp [$context]';
    final line = '$header\n$error\n${stackTrace ?? StackTrace.current}\n---\n';
    _ring.add(line);
    if (_ring.length > _ringLimit) {
      _ring.removeRange(0, _ring.length - _ringLimit);
    }
    debugPrint('Textara error: $error');
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, fileName));
      await file.writeAsString(line, mode: FileMode.append, flush: true);
    } catch (_) {
      // Logging must never throw into the app.
    }
  }

  static void installHooks() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        record(
          details.exception,
          stackTrace: details.stack,
          context: 'FlutterError',
        ),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(record(error, stackTrace: stack, context: 'Zone'));
      return true;
    };
  }
}
