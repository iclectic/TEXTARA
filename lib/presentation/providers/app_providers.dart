import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leaf_reader/core/constants/app_constants.dart';
import 'package:leaf_reader/core/constants/enums.dart';
import 'package:leaf_reader/domain/entities/app_theme.dart';
import 'package:leaf_reader/domain/entities/book.dart';
import 'package:leaf_reader/domain/entities/annotation.dart';
import 'package:leaf_reader/domain/entities/collection.dart';
import 'package:leaf_reader/domain/entities/reader_settings.dart';
import 'package:leaf_reader/data/database/database_helper.dart';
import 'package:leaf_reader/data/database/book_dao.dart';
import 'package:leaf_reader/data/database/annotation_dao.dart';
import 'package:leaf_reader/data/database/collection_dao.dart';
import 'package:leaf_reader/data/services/file_storage_service.dart';
import 'package:leaf_reader/data/services/epub_parser_service.dart';
import 'package:leaf_reader/data/services/import_service.dart';
import 'package:leaf_reader/data/services/export_service.dart';

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
    ref.watch(fileStorageProvider),
  );
});

// App preferences
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final isFirstRunProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool(AppConstants.prefKeyFirstRun) ?? true;
});

// Theme state
final currentThemeProvider =
    StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
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
    final themeId =
        prefs.getString(AppConstants.prefKeyTheme) ?? 'porcelain';
    state = BuiltInThemes.findById(themeId);
  }
}

// Accessibility settings
final reducedMotionProvider =
    StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier(AppConstants.prefKeyReducedMotion);
});

final highContrastProvider =
    StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier(AppConstants.prefKeyHighContrast);
});

final dyslexiaModeProvider =
    StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier(AppConstants.prefKeyDyslexiaMode);
});

final lowStimulationProvider =
    StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier(AppConstants.prefKeyLowStimulation);
});

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

final librarySortProvider =
    StateProvider<LibrarySortField>((ref) => LibrarySortField.lastAdded);

final librarySortOrderProvider =
    StateProvider<SortOrder>((ref) => SortOrder.descending);

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
    error: (_, __) => [],
  );
});

// Reader settings
final readerSettingsProvider =
    StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>((ref) {
  return ReaderSettingsNotifier();
});

class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  ReaderSettingsNotifier() : super(const ReaderSettings());

  void update(ReaderSettings settings) {
    state = settings;
  }

  void setFontFamily(String fontFamily) {
    state = state.copyWith(fontFamily: fontFamily);
  }

  void setFontSize(double fontSize) {
    state = state.copyWith(fontSize: fontSize);
  }

  void setLineHeight(double lineHeight) {
    state = state.copyWith(lineHeight: lineHeight);
  }

  void setMargin(double margin) {
    state = state.copyWith(horizontalMargin: margin);
  }

  void setAlignment(TextAlignment alignment) {
    state = state.copyWith(textAlignment: alignment);
  }

  void toggleHyphenation() {
    state = state.copyWith(hyphenationEnabled: !state.hyphenationEnabled);
  }
}

// Annotations for a specific book
final bookHighlightsProvider =
    FutureProvider.family<List<Highlight>, String>((ref, bookId) async {
  final dao = ref.watch(annotationDaoProvider);
  return dao.getHighlightsForBook(bookId);
});

final bookBookmarksProvider =
    FutureProvider.family<List<Bookmark>, String>((ref, bookId) async {
  final dao = ref.watch(annotationDaoProvider);
  return dao.getBookmarksForBook(bookId);
});

// Collections
final collectionsProvider =
    FutureProvider<List<Collection>>((ref) async {
  final dao = ref.watch(collectionDaoProvider);
  return dao.getAllCollections();
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
