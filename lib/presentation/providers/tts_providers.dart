import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/services/tts_controller.dart';

final ttsControllerProvider = Provider<TtsController>((ref) {
  final controller = TtsController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final ttsStateProvider = StateNotifierProvider<TtsNotifier, TtsUiState>((ref) {
  return TtsNotifier(ref.watch(ttsControllerProvider));
});

class TtsUiState {
  final TtsState state;
  final double rate;

  const TtsUiState({this.state = TtsState.stopped, this.rate = 0.5});

  TtsUiState copyWith({TtsState? state, double? rate}) {
    return TtsUiState(state: state ?? this.state, rate: rate ?? this.rate);
  }
}

class TtsNotifier extends StateNotifier<TtsUiState> {
  TtsNotifier(this._controller) : super(const TtsUiState()) {
    _init();
  }

  final TtsController _controller;
  bool _ready = false;

  Future<void> _init() async {
    await _controller.init();
    _ready = true;
  }

  Future<void> speak(String text) async {
    if (!_ready) await _init();
    await _controller.speak(text);
    state = state.copyWith(state: TtsState.playing);
  }

  Future<void> pause() async {
    await _controller.pause();
    state = state.copyWith(state: TtsState.paused);
  }

  Future<void> stop() async {
    await _controller.stop();
    state = state.copyWith(state: TtsState.stopped);
  }

  Future<void> setRate(double rate) async {
    await _controller.setRate(rate);
    state = state.copyWith(rate: rate);
  }
}
