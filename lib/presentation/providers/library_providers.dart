import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/collection.dart';
import 'package:textara/domain/entities/search_result.dart';
import 'package:textara/domain/repositories/library_repository.dart';
import 'package:textara/presentation/providers/database_providers.dart';

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
    StateNotifierProvider<LibrarySortFieldNotifier, LibrarySortField>((ref) {
      return LibrarySortFieldNotifier();
    });

class LibrarySortFieldNotifier extends StateNotifier<LibrarySortField> {
  static const _prefKey = 'library_sort_field';

  LibrarySortFieldNotifier() : super(LibrarySortField.lastAdded) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefKey);
    if (value == null) return;
    state = LibrarySortField.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LibrarySortField.lastAdded,
    );
  }

  Future<void> set(LibrarySortField field) async {
    state = field;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, field.name);
  }
}

final librarySortOrderProvider =
    StateNotifierProvider<LibrarySortOrderNotifier, SortOrder>((ref) {
      return LibrarySortOrderNotifier();
    });

class LibrarySortOrderNotifier extends StateNotifier<SortOrder> {
  static const _prefKey = 'library_sort_order';

  LibrarySortOrderNotifier() : super(SortOrder.descending) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefKey);
    if (value == 'ascending') state = SortOrder.ascending;
  }

  Future<void> set(SortOrder order) async {
    state = order;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, order.name);
  }
}

final librarySearchQueryProvider = StateProvider<String>((ref) => '');

/// Library browse filters (independent of full-text search).
final libraryFavouritesOnlyProvider = StateProvider<bool>((ref) => false);
final libraryStatusFilterProvider = StateProvider<ReadingStatus?>(
  (ref) => null,
);
final libraryFormatFilterProvider = StateProvider<BookFormat?>((ref) => null);
final libraryCollectionFilterProvider = StateProvider<String?>((ref) => null);

final booksProvider =
    StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>((ref) {
      return BooksNotifier(ref.watch(libraryRepositoryProvider));
    });

class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final LibraryRepository _repository;

  BooksNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      state = const AsyncValue.loading();
      final books = await _repository.getAllBooks();
      state = AsyncValue.data(books);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBook(String bookId) async {
    await _repository.deleteBook(bookId);
    await loadBooks();
  }

  Future<void> toggleFavourite(String bookId) async {
    await _repository.toggleFavourite(bookId);
    await loadBooks();
  }

  Future<void> updateBook(Book book) async {
    await _repository.updateBook(book);
    await loadBooks();
  }
}

/// Browse mode: filtered + sorted library when the search box is empty.
final filteredBooksProvider = Provider<List<Book>>((ref) {
  final booksAsync = ref.watch(booksProvider);
  final sortField = ref.watch(librarySortProvider);
  final sortOrder = ref.watch(librarySortOrderProvider);
  final favouritesOnly = ref.watch(libraryFavouritesOnlyProvider);
  final statusFilter = ref.watch(libraryStatusFilterProvider);
  final formatFilter = ref.watch(libraryFormatFilterProvider);
  final collectionFilter = ref.watch(libraryCollectionFilterProvider);

  // Callers must also watch [booksProvider] for loading/error UI — this
  // provider only returns a list for browse mode and never hides failures.
  final books = booksAsync.valueOrNull;
  if (books == null) return const [];

  var filtered = List<Book>.from(books);
  if (favouritesOnly) {
    filtered = filtered.where((b) => b.isFavourite).toList();
  }
  if (statusFilter != null) {
    filtered = filtered.where((b) => b.readingStatus == statusFilter).toList();
  }
  if (formatFilter != null) {
    filtered = filtered.where((b) => b.format == formatFilter).toList();
  }
  if (collectionFilter != null) {
    final ids = ref.watch(collectionBookIdsProvider(collectionFilter));
    final allowed = ids.valueOrNull;
    if (allowed != null) {
      filtered = filtered.where((b) => allowed.contains(b.id)).toList();
    }
  }
  filtered.sort((a, b) {
    final int cmp;
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
});

final collectionBookIdsProvider = FutureProvider.family<List<String>, String>((
  ref,
  collectionId,
) async {
  return ref.watch(collectionDaoProvider).getBookIdsForCollection(collectionId);
});

/// Debounced full-text + metadata search via [LibraryRepository.search].
final librarySearchResultsProvider =
    FutureProvider.autoDispose<List<SearchResult>>((ref) async {
      final query = ref.watch(librarySearchQueryProvider).trim();
      if (query.isEmpty) return const [];

      // Debounce rapid keystrokes.
      final completer = Completer<void>();
      final timer = Timer(
        const Duration(milliseconds: 250),
        completer.complete,
      );
      ref.onDispose(timer.cancel);
      await completer.future;

      final results = await ref.read(libraryRepositoryProvider).search(query);
      if (results.length > AppConstants.searchResultLimit) {
        return results.take(AppConstants.searchResultLimit).toList();
      }
      return results;
    });

/// Set when a shared file or `textara://book/<id>` should open the reader.
class PendingReaderOpen {
  final Book book;
  final String? chapterId;

  const PendingReaderOpen({required this.book, this.chapterId});
}

final pendingReaderOpenProvider = StateProvider<PendingReaderOpen?>(
  (ref) => null,
);

/// True while the tablet library is showing a book beside the shelf.
final libraryReaderPaneOpenProvider = StateProvider<bool>((ref) => false);

final collectionsProvider = FutureProvider<List<Collection>>((ref) async {
  final dao = ref.watch(collectionDaoProvider);
  return dao.getAllCollections();
});
