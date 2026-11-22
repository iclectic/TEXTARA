import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/reader_settings.dart';
import 'package:textara/domain/repositories/library_repository.dart';
import 'package:textara/presentation/providers/database_providers.dart';

final readerSettingsProvider =
    StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>((ref) {
      return ReaderSettingsNotifier();
    });

class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  ReaderSettingsNotifier() : super(const ReaderSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefKeyReaderDefaults);
    if (raw == null || raw.isEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      state = ReaderSettings.fromJson(json);
    } catch (_) {
      // Keep defaults if stored JSON is corrupt.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefKeyReaderDefaults,
      jsonEncode(state.toJson()),
    );
  }

  void update(ReaderSettings settings) {
    state = settings;
    unawaited(_persist());
  }

  void setFontFamily(String fontFamily) {
    state = state.copyWith(fontFamily: fontFamily);
    unawaited(_persist());
  }

  void setFontSize(double fontSize) {
    state = state.copyWith(fontSize: fontSize);
    unawaited(_persist());
  }

  void setLineHeight(double lineHeight) {
    state = state.copyWith(lineHeight: lineHeight);
    unawaited(_persist());
  }

  void setMargin(double margin) {
    state = state.copyWith(horizontalMargin: margin);
    unawaited(_persist());
  }

  void setAlignment(TextAlignment alignment) {
    state = state.copyWith(textAlignment: alignment);
    unawaited(_persist());
  }

  void toggleHyphenation() {
    state = state.copyWith(hyphenationEnabled: !state.hyphenationEnabled);
    unawaited(_persist());
  }
}

/// Coalesces rapid reader progress writes into a single DAO call.
class ReadingProgressWriter {
  ReadingProgressWriter(
    this._repository, {
    this.delay = const Duration(milliseconds: 400),
  });

  final LibraryRepository _repository;
  final Duration delay;

  Timer? _timer;
  String? _bookId;
  double _progress = 0;
  int _page = 0;
  String? _chapterId;

  void schedule({
    required String bookId,
    required double progress,
    required int page,
    String? chapterId,
  }) {
    _bookId = bookId;
    _progress = progress;
    _page = page;
    _chapterId = chapterId;
    _timer?.cancel();
    _timer = Timer(delay, flush);
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final bookId = _bookId;
    if (bookId == null) return;
    await _repository.updateReadingProgress(
      bookId,
      _progress,
      _page,
      _chapterId,
    );
  }

  void dispose() {
    // Best-effort final persist; callers should await [flush] on leave.
    _timer?.cancel();
    _timer = null;
  }
}

final bookHighlightsProvider = FutureProvider.family<List<Highlight>, String>((
  ref,
  bookId,
) async {
  final dao = ref.watch(annotationDaoProvider);
  return dao.getHighlightsForBook(bookId);
});

final bookBookmarksProvider = FutureProvider.family<List<Bookmark>, String>((
  ref,
  bookId,
) async {
  final dao = ref.watch(annotationDaoProvider);
  return dao.getBookmarksForBook(bookId);
});
