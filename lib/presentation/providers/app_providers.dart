import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/core/theme/reading_theme_mapper.dart';
import 'package:textara/domain/entities/app_theme.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/collection.dart';
import 'package:textara/domain/entities/continue_reading.dart';
import 'package:textara/domain/entities/reader_location.dart';
import 'package:textara/domain/entities/reader_settings.dart';
import 'package:textara/domain/entities/idea_thread.dart';
import 'package:textara/data/database/database_helper.dart';
import 'package:textara/data/database/book_dao.dart';
import 'package:textara/data/database/annotation_dao.dart';
import 'package:textara/data/database/collection_dao.dart';
import 'package:textara/data/database/idea_thread_dao.dart';
import 'package:textara/data/database/ink_stroke_dao.dart';
import 'package:textara/data/services/brightness_service.dart';
import 'package:textara/data/services/dictionary_service.dart';
import 'package:textara/data/services/file_storage_service.dart';
import 'package:textara/data/services/epub_parser_service.dart';
import 'package:textara/data/services/import_service.dart';
import 'package:textara/data/services/export_service.dart';
import 'package:textara/domain/entities/dictionary_entry.dart';
import 'package:textara/domain/entities/ink_stroke.dart';

// Database and DAOs
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final bookDaoProvider = Provider<BookDao>((ref) {
  return BookDao(ref.watch(databaseHelperProvider));
});

final annotationDaoProvider = Provider<AnnotationDao>((ref) {
  return AnnotationDao(ref.watch(databaseHelperProvider));
});

final collectionDaoProvider = Provider<CollectionDao>((ref) {
  return CollectionDao(ref.watch(databaseHelperProvider));
});

final ideaThreadDaoProvider = Provider<IdeaThreadDao>((ref) {
  return IdeaThreadDao(ref.watch(databaseHelperProvider));
});

final inkStrokeDaoProvider = Provider<InkStrokeDao>((ref) {
  return InkStrokeDao(ref.watch(databaseHelperProvider));
});

/// Active ink tool for the open reader. Defaults to off so scroll is unaffected.
final inkToolProvider = StateProvider<InkTool>((ref) => InkTool.off);

/// Strokes for one book + [ReaderLocation.inkLocationKey].
final inkStrokesProvider = StateNotifierProvider.autoDispose
    .family<InkStrokesNotifier, AsyncValue<List<InkStroke>>, InkLocationArgs>(
  (ref, args) {
    return InkStrokesNotifier(ref.watch(inkStrokeDaoProvider), args);
  },
);

class InkLocationArgs extends Equatable {
  final String bookId;
  final String locationKey;

  const InkLocationArgs({required this.bookId, required this.locationKey});

  @override
  List<Object?> get props => [bookId, locationKey];
}

class InkStrokesNotifier extends StateNotifier<AsyncValue<List<InkStroke>>> {
  InkStrokesNotifier(this._dao, this._args)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final InkStrokeDao _dao;
  final InkLocationArgs _args;

  Future<void> _load() async {
    try {
      final strokes = await _dao.getStrokesForLocation(
        bookId: _args.bookId,
        locationKey: _args.locationKey,
      );
      if (!mounted) return;
      state = AsyncValue.data(strokes);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addStroke(InkStroke stroke) async {
    final current = state.valueOrNull ?? const <InkStroke>[];
    state = AsyncValue.data([...current, stroke]);
    await _dao.insertStroke(stroke);
  }

  Future<void> eraseStrokes(Iterable<String> ids) async {
    final idSet = ids.toSet();
    if (idSet.isEmpty) return;
    final current = state.valueOrNull ?? const <InkStroke>[];
    state = AsyncValue.data(
      current.where((stroke) => !idSet.contains(stroke.id)).toList(),
    );
    await _dao.deleteStrokes(idSet);
  }

  Future<void> clearPage() async {
    state = const AsyncValue.data([]);
    await _dao.clearLocation(
      bookId: _args.bookId,
      locationKey: _args.locationKey,
    );
  }
}

// Services
final fileStorageProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

final epubParserProvider = Provider<EpubParserService>((ref) {
  return EpubParserService();
});

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(
    ref.watch(bookDaoProvider),
    ref.watch(fileStorageProvider),
    ref.watch(epubParserProvider),
  );
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    ref.watch(bookDaoProvider),
    ref.watch(annotationDaoProvider),
    ref.watch(collectionDaoProvider),
    ref.watch(ideaThreadDaoProvider),
    ref.watch(fileStorageProvider),
  );
});

final brightnessServiceProvider = Provider<BrightnessService>((ref) {
  return ScreenBrightnessService();
});

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  return DictionaryService();
});

/// Opt-in online dictionary fallback. Off by default (privacy-first).
final dictionaryOnlineFallbackProvider =
    StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier(AppConstants.prefKeyDictionaryOnline);
});

final dictionaryLookupProvider = StateNotifierProvider.autoDispose<
    DictionaryLookupNotifier, DictionaryLookupResult>((ref) {
  return DictionaryLookupNotifier(ref);
});

class DictionaryLookupNotifier extends StateNotifier<DictionaryLookupResult> {
  DictionaryLookupNotifier(this._ref)
      : super(const DictionaryLookupResult.idle());

  final Ref _ref;

  Future<void> lookup(String selection) async {
    final query = selection.trim();
    if (query.isEmpty) {
      state = const DictionaryLookupResult.idle();
      return;
    }

    state = DictionaryLookupResult.loading(query);
    final allowOnline = _ref.read(dictionaryOnlineFallbackProvider);
    final result = await _ref.read(dictionaryServiceProvider).lookup(
          query,
          allowOnline: allowOnline,
        );
    if (!mounted) return;
    state = result;
  }

  void reset() {
    state = const DictionaryLookupResult.idle();
  }
}

// App preferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

final isFirstRunProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool(AppConstants.prefKeyFirstRun) ?? true;
});

// Theme state
final currentThemeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((
  ref,
) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier() : super(BuiltInThemes.porcelain);

  void setTheme(AppTheme theme) {
    state = theme;
    _saveTheme(theme.id);
  }

  Future<void> _saveTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyTheme, themeId);
  }

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString(AppConstants.prefKeyTheme) ?? 'porcelain';
    state = BuiltInThemes.findById(themeId);
  }
}

// Accessibility settings
final reducedMotionProvider = StateNotifierProvider<BoolSettingNotifier, bool>((
  ref,
) {
  return BoolSettingNotifier(AppConstants.prefKeyReducedMotion);
});

final highContrastProvider = StateNotifierProvider<BoolSettingNotifier, bool>((
  ref,
) {
  return BoolSettingNotifier(AppConstants.prefKeyHighContrast);
});

final dyslexiaModeProvider = StateNotifierProvider<BoolSettingNotifier, bool>((
  ref,
) {
  return BoolSettingNotifier(AppConstants.prefKeyDyslexiaMode);
});

final lowStimulationProvider = StateNotifierProvider<BoolSettingNotifier, bool>(
  (ref) {
    return BoolSettingNotifier(AppConstants.prefKeyLowStimulation);
  },
);

class BoolSettingNotifier extends StateNotifier<bool> {
  final String _prefKey;

  BoolSettingNotifier(this._prefKey) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefKey) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, state);
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}

// Library state
final libraryViewModeProvider =
    StateNotifierProvider<LibraryViewModeNotifier, LibraryViewMode>((ref) {
      return LibraryViewModeNotifier();
    });

class LibraryViewModeNotifier extends StateNotifier<LibraryViewMode> {
  LibraryViewModeNotifier() : super(LibraryViewMode.grid) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppConstants.prefKeyLibraryView);
    if (value == 'list') state = LibraryViewMode.list;
  }

  Future<void> toggle() async {
    state = state == LibraryViewMode.grid
        ? LibraryViewMode.list
        : LibraryViewMode.grid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyLibraryView, state.name);
  }
}

final librarySortProvider = StateProvider<LibrarySortField>(
  (ref) => LibrarySortField.lastAdded,
);

final librarySortOrderProvider = StateProvider<SortOrder>(
  (ref) => SortOrder.descending,
);

final librarySearchQueryProvider = StateProvider<String>((ref) => '');

// Books state
final booksProvider =
    StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>((ref) {
      return BooksNotifier(ref.watch(bookDaoProvider));
    });

class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final BookDao _bookDao;

  BooksNotifier(this._bookDao) : super(const AsyncValue.loading()) {
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      state = const AsyncValue.loading();
      final books = await _bookDao.getAllBooks();
      state = AsyncValue.data(books);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBook(String bookId) async {
    await _bookDao.deleteBook(bookId);
    await loadBooks();
  }

  Future<void> toggleFavourite(String bookId) async {
    await _bookDao.toggleFavourite(bookId);
    await loadBooks();
  }

  Future<void> updateBook(Book book) async {
    await _bookDao.updateBook(book);
    await loadBooks();
  }
}

// Filtered books
final filteredBooksProvider = Provider<List<Book>>((ref) {
  final booksAsync = ref.watch(booksProvider);
  final query = ref.watch(librarySearchQueryProvider);
  final sortField = ref.watch(librarySortProvider);
  final sortOrder = ref.watch(librarySortOrderProvider);

  return booksAsync.when(
    data: (books) {
      var filtered = List<Book>.from(books);

      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        filtered = filtered.where((b) {
          return b.title.toLowerCase().contains(lowerQuery) ||
              b.author.toLowerCase().contains(lowerQuery) ||
              b.tags.any((t) => t.toLowerCase().contains(lowerQuery));
        }).toList();
      }

      filtered.sort((a, b) {
        int cmp;
        switch (sortField) {
          case LibrarySortField.title:
            cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          case LibrarySortField.author:
            cmp = a.author.toLowerCase().compareTo(b.author.toLowerCase());
          case LibrarySortField.progress:
            cmp = a.readingProgress.compareTo(b.readingProgress);
          case LibrarySortField.recentlyOpened:
            final aDate = a.lastOpenedAt ?? DateTime(1970);
            final bDate = b.lastOpenedAt ?? DateTime(1970);
            cmp = aDate.compareTo(bDate);
          case LibrarySortField.lastAdded:
            cmp = a.dateAdded.compareTo(b.dateAdded);
        }
        return sortOrder == SortOrder.ascending ? cmp : -cmp;
      });

      return filtered;
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

// Reader settings
final readerSettingsProvider =
    StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>((ref) {
      return ReaderSettingsNotifier(ref);
    });

class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  ReaderSettingsNotifier(this._ref) : super(const ReaderSettings());

  final Ref _ref;
  bool _loaded = false;

  Future<void> loadSavedSettings() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefKeyReaderDefaults);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          state = ReaderSettings.fromJson(decoded);
        } else if (decoded is Map) {
          state = ReaderSettings.fromJson(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      } catch (_) {
        // Keep defaults if stored JSON is corrupt.
      }
    }
    _loaded = true;
    await _applyBrightness(state.brightness);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefKeyReaderDefaults,
      jsonEncode(state.toJson()),
    );
  }

  Future<void> _applyBrightness(double brightness) async {
    await _ref.read(brightnessServiceProvider).apply(brightness);
  }

  Future<void> _commit(ReaderSettings next) async {
    state = next;
    await _persist();
  }

  Future<void> update(ReaderSettings settings) async {
    await _commit(settings);
    await _applyBrightness(settings.brightness);
  }

  Future<void> setFontFamily(String fontFamily) async {
    await _commit(state.copyWith(fontFamily: fontFamily));
  }

  Future<void> setFontSize(double fontSize) async {
    await _commit(state.copyWith(fontSize: fontSize));
  }

  Future<void> setLineHeight(double lineHeight) async {
    await _commit(state.copyWith(lineHeight: lineHeight));
  }

  Future<void> setMargin(double margin) async {
    await _commit(state.copyWith(horizontalMargin: margin));
  }

  Future<void> setAlignment(TextAlignment alignment) async {
    await _commit(state.copyWith(textAlignment: alignment));
  }

  Future<void> toggleHyphenation() async {
    await _commit(
      state.copyWith(hyphenationEnabled: !state.hyphenationEnabled),
    );
  }

  Future<void> setThemeMode(ReaderThemeMode mode) async {
    await _commit(state.copyWith(themeMode: mode));
    final theme = ReadingThemeMapper.appThemeFor(mode);
    _ref.read(currentThemeProvider.notifier).setTheme(theme);
  }

  Future<void> setBrightness(double brightness) async {
    final clamped = brightness.clamp(
      AppConstants.minReaderBrightness,
      AppConstants.maxReaderBrightness,
    );
    await _commit(state.copyWith(brightness: clamped));
    await _applyBrightness(clamped);
  }
}

// Annotations for a specific book
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

/// One-shot navigation request inside an open reader (bookmark jump, etc.).
final pendingReaderJumpProvider =
    StateProvider<ReaderLocation?>((ref) => null);

/// Most recently opened in-progress book for the library "Continue reading" card.
final continueReadingBookProvider = Provider<Book?>((ref) {
  final booksAsync = ref.watch(booksProvider);
  return booksAsync.maybeWhen(
    data: ContinueReading.select,
    orElse: () => null,
  );
});

// Collections
final collectionsProvider = FutureProvider<List<Collection>>((ref) async {
  final dao = ref.watch(collectionDaoProvider);
  return dao.getAllCollections();
});

final ideaThreadsProvider = FutureProvider<List<IdeaThread>>((ref) async {
  return ref.watch(ideaThreadDaoProvider).getAllThreads();
});

final threadEvidenceProvider =
    FutureProvider.family<List<ThreadEvidence>, String>((ref, threadId) async {
      return ref.watch(ideaThreadDaoProvider).getEvidenceForThread(threadId);
    });

// Import state
final importProgressProvider =
    StateNotifierProvider<ImportProgressNotifier, ImportProgress>((ref) {
      return ImportProgressNotifier();
    });

class ImportProgress {
  final bool isImporting;
  final int total;
  final int completed;
  final String? currentFileName;

  const ImportProgress({
    this.isImporting = false,
    this.total = 0,
    this.completed = 0,
    this.currentFileName,
  });

  double get progress => total > 0 ? completed / total : 0;
}

class ImportProgressNotifier extends StateNotifier<ImportProgress> {
  ImportProgressNotifier() : super(const ImportProgress());

  void startImport(int total) {
    state = ImportProgress(isImporting: true, total: total);
  }

  void updateProgress(int completed, String? fileName) {
    state = ImportProgress(
      isImporting: true,
      total: state.total,
      completed: completed,
      currentFileName: fileName,
    );
  }

  void completeImport() {
    state = const ImportProgress();
  }
}
