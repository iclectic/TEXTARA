import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/search_result.dart';
import 'package:textara/domain/repositories/library_repository.dart';
import 'package:textara/presentation/providers/database_providers.dart';
import 'package:textara/presentation/providers/library_providers.dart';

class _FakeLibraryRepository extends Mock implements LibraryRepository {}

Book _book({
  required String id,
  String title = 'Title',
  String author = 'Author',
  double progress = 0,
  DateTime? dateAdded,
  DateTime? lastOpenedAt,
  List<String> tags = const [],
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    filePath: '/tmp/$id.epub',
    format: BookFormat.epub,
    dateAdded: dateAdded ?? DateTime(2024, 1, 1),
    lastOpenedAt: lastOpenedAt,
    readingProgress: progress,
    tags: tags,
  );
}

Future<void> _waitUntilLoaded(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    final state = container.read(booksProvider);
    if (!state.isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    registerFallbackValue(_book(id: 'fallback'));
    registerFallbackValue(ReadingStatus.notStarted);
  });

  group('BooksNotifier', () {
    test('loads books from the repository on construction', () async {
      final repository = _FakeLibraryRepository();
      final books = [
        _book(id: '1', title: 'Alpha'),
        _book(id: '2', title: 'Beta'),
      ];
      when(() => repository.getAllBooks()).thenAnswer((_) async => books);

      final container = ProviderContainer(
        overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.read(booksProvider);
      await _waitUntilLoaded(container);

      final state = container.read(booksProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, books);
    });

    test('toggleFavourite refreshes the book list', () async {
      final repository = _FakeLibraryRepository();
      final books = [_book(id: '1', title: 'Alpha')];
      when(() => repository.getAllBooks()).thenAnswer((_) async => books);
      when(() => repository.toggleFavourite('1')).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.read(booksProvider);
      await _waitUntilLoaded(container);
      await container.read(booksProvider.notifier).toggleFavourite('1');
      await _waitUntilLoaded(container);

      verify(() => repository.toggleFavourite('1')).called(1);
      verify(() => repository.getAllBooks()).called(greaterThanOrEqualTo(2));
    });

    test('repository failure surfaces as AsyncError', () async {
      final repository = _FakeLibraryRepository();
      when(
        () => repository.getAllBooks(),
      ).thenThrow(Exception('database locked'));

      final container = ProviderContainer(
        overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.read(booksProvider);
      await _waitUntilLoaded(container);

      expect(container.read(booksProvider).hasError, isTrue);
    });
  });

  group('filteredBooksProvider sorting', () {
    test('sorts by title ascending when configured', () async {
      final repository = _FakeLibraryRepository();
      final books = [
        _book(id: '2', title: 'Zebra'),
        _book(id: '1', title: 'Apple'),
      ];
      when(() => repository.getAllBooks()).thenAnswer((_) async => books);

      final container = ProviderContainer(
        overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.read(booksProvider);
      await _waitUntilLoaded(container);
      await container
          .read(librarySortProvider.notifier)
          .set(LibrarySortField.title);
      await container
          .read(librarySortOrderProvider.notifier)
          .set(SortOrder.ascending);

      final filtered = container.read(filteredBooksProvider);
      expect(filtered.map((b) => b.title).toList(), ['Apple', 'Zebra']);
    });

    test('empty repository yields empty filtered list', () async {
      final repository = _FakeLibraryRepository();
      when(() => repository.getAllBooks()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.read(booksProvider);
      await _waitUntilLoaded(container);
      expect(container.read(filteredBooksProvider), isEmpty);
    });
  });

  group('LibraryRepository search contract', () {
    test('search returns ranked SearchResult list', () async {
      final repository = _FakeLibraryRepository();
      final book = _book(id: '1', title: 'Moby Dick', tags: ['classic']);
      when(() => repository.search('moby')).thenAnswer(
        (_) async => [
          SearchResult(
            book: book,
            matchType: SearchMatchType.metadata,
            rank: 100,
          ),
        ],
      );

      final results = await repository.search('moby');
      expect(results, hasLength(1));
      expect(results.first.book.title, 'Moby Dick');
      expect(results.first.isFullTextMatch, isFalse);
      expect(results.first.rank, 100);
    });
  });
}
