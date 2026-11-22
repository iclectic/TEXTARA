import 'package:flutter_tts/flutter_tts.dart';
import 'package:textara/core/constants/enums.dart';

/// Thin wrapper around [FlutterTts] for EPUB read-aloud.
class TtsController {
  TtsController({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;
  TtsState _state = TtsState.stopped;
  double _rate = 0.5;

  TtsState get state => _state;
  double get rate => _rate;

  Future<void> init() async {
    await _tts.setSpeechRate(_rate);
    await _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() => _state = TtsState.playing);
    _tts.setCompletionHandler(() => _state = TtsState.stopped);
    _tts.setCancelHandler(() => _state = TtsState.stopped);
    _tts.setPauseHandler(() => _state = TtsState.paused);
    _tts.setContinueHandler(() => _state = TtsState.playing);
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _state = TtsState.playing;
    await _tts.speak(trimmed);
  }

  Future<void> pause() async {
    await _tts.pause();
    _state = TtsState.paused;
  }

  Future<void> stop() async {
    await _tts.stop();
    _state = TtsState.stopped;
  }

  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.2, 1.0);
    await _tts.setSpeechRate(_rate);
  }

  Future<void> dispose() async {
    await stop();
  }
}
