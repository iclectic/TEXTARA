import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/core/theme/design_tokens.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/widgets/library/book_grid_tile.dart';
import 'package:textara/presentation/widgets/library/book_list_tile.dart';
import 'package:textara/presentation/widgets/library/library_empty_state.dart';
import 'package:textara/presentation/widgets/library/sort_bottom_sheet.dart';
import 'package:textara/presentation/screens/reader/reader_screen.dart';
import 'package:textara/presentation/screens/settings/settings_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importBooks() async {
    HapticFeedback.mediumImpact();
    final importService = ref.read(importServiceProvider);
    final results = await importService.pickAndImportFiles();

    if (!mounted) return;

    final successCount = results.where((r) => r.success).length;
    final failCount = results.where((r) => !r.success).length;

    if (results.isNotEmpty) {
      ref.read(booksProvider.notifier).loadBooks();
      String message;
      if (failCount == 0) {
        message = successCount == 1
            ? 'Book imported successfully.'
            : '$successCount books imported successfully.';
      } else if (failCount == 1) {
        final failure = results.firstWhere((result) => !result.success);
        final failedName = failure.fileName == null
            ? '1 file'
            : '"${failure.fileName}"';
        message =
            '$failedName was not imported. ${failure.errorMessage ?? 'Please try again.'}';
      } else {
        message =
            '$successCount imported, $failCount failed. Check file format and try again.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openBook(Book book) {
    HapticFeedback.lightImpact();
    ref.read(bookDaoProvider).updateLastOpened(book.id);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ReaderScreen(book: book)));
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        ref.read(librarySearchQueryProvider.notifier).state = '';
      }
    });
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => const SortBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final books = ref.watch(filteredBooksProvider);
    final viewMode = ref.watch(libraryViewModeProvider);
    final booksState = ref.watch(booksProvider);
    final searchQuery = ref.watch(librarySearchQueryProvider);
    final isLoading = booksState is AsyncLoading;
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching ? _buildSearchField(theme) : const Text('Library'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: _toggleSearch,
            tooltip: _isSearching ? 'Close search' : 'Search library',
          ),
          IconButton(
            icon: Icon(
              viewMode == LibraryViewMode.grid
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(libraryViewModeProvider.notifier).toggle();
            },
            tooltip: viewMode == LibraryViewMode.grid
                ? 'Switch to list view'
                : 'Switch to grid view',
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: _showSortSheet,
            tooltip: 'Sort books',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
          ? LibraryEmptyState(onImport: _importBooks)
          : _buildLibraryContent(
              books,
              viewMode,
              isTablet,
              showShelves:
                  searchQuery.isEmpty && viewMode == LibraryViewMode.grid,
            ),
      floatingActionButton: books.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _importBooks,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Import'),
              tooltip: 'Import books',
            )
          : null,
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search by title, author, or tag...',
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
      style: theme.textTheme.bodyLarge,
      onChanged: (value) {
        ref.read(librarySearchQueryProvider.notifier).state = value;
      },
    );
  }

  Widget _buildLibraryContent(
    List<Book> books,
    LibraryViewMode viewMode,
    bool isTablet, {
    required bool showShelves,
  }) {
    if (showShelves) {
      return _buildLibraryHome(books, isTablet);
    }

    return _buildBooksList(books, viewMode, isTablet);
  }

  Widget _buildLibraryHome(List<Book> books, bool isTablet) {
    final continueReading =
        List<Book>.from(
          books.where(
            (book) => book.readingProgress > 0 && book.readingProgress < 1,
          ),
        )..sort((a, b) {
          final aDate = a.lastOpenedAt ?? DateTime(1970);
          final bDate = b.lastOpenedAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
    final recentlyAdded = List<Book>.from(books)
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TextaraSpacing.lg,
        TextaraSpacing.sm,
        TextaraSpacing.lg,
        96,
      ),
      children: [
        _LibrarySummary(books: books),
        if (continueReading.isNotEmpty) ...[
          const SizedBox(height: TextaraSpacing.xl),
          _ShelfHeader(
            title: 'Continue reading',
            subtitle: '${continueReading.length} in progress',
          ),
          const SizedBox(height: TextaraSpacing.md),
          _buildHorizontalBookShelf(continueReading.take(8).toList()),
        ],
        const SizedBox(height: TextaraSpacing.xl),
        _ShelfHeader(
          title: 'Recently added',
          subtitle: '${recentlyAdded.length} books',
        ),
        const SizedBox(height: TextaraSpacing.md),
        _buildHorizontalBookShelf(recentlyAdded.take(8).toList()),
        const SizedBox(height: TextaraSpacing.xl),
        const _ShelfHeader(title: 'All books'),
        const SizedBox(height: TextaraSpacing.md),
        _buildBooksGrid(books, isTablet, shrinkWrap: true),
      ],
    );
  }

  Widget _buildHorizontalBookShelf(List<Book> books) {
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: TextaraSpacing.md),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 136,
            child: BookGridTile(
              book: books[index],
              onTap: () => _openBook(books[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBooksList(
    List<Book> books,
    LibraryViewMode viewMode,
    bool isTablet,
  ) {
    if (viewMode == LibraryViewMode.list) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          return BookListTile(
            book: books[index],
            onTap: () => _openBook(books[index]),
            onFavourite: () {
              ref.read(booksProvider.notifier).toggleFavourite(books[index].id);
            },
          );
        },
      );
    }

    return _buildBooksGrid(books, isTablet);
  }

  Widget _buildBooksGrid(
    List<Book> books,
    bool isTablet, {
    bool shrinkWrap = false,
  }) {
    final crossAxisCount = isTablet ? 4 : 2;
    return GridView.builder(
      padding: shrinkWrap ? EdgeInsets.zero : const EdgeInsets.all(16),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return BookGridTile(
          book: books[index],
          onTap: () => _openBook(books[index]),
        );
      },
    );
  }
}

class _LibrarySummary extends StatelessWidget {
  final List<Book> books;

  const _LibrarySummary({required this.books});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reading = books
        .where((book) => book.readingStatus == ReadingStatus.reading)
        .length;
    final finished = books
        .where((book) => book.readingStatus == ReadingStatus.finished)
        .length;
    final favourites = books.where((book) => book.isFavourite).length;

    return Semantics(
      label:
          'Library summary. ${books.length} books, $reading currently reading, $finished finished, $favourites favourites.',
      child: Container(
        padding: const EdgeInsets.all(TextaraSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(TextaraRadius.lg),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            _SummaryMetric(label: 'Books', value: books.length.toString()),
            _SummaryMetric(label: 'Reading', value: reading.toString()),
            _SummaryMetric(label: 'Finished', value: finished.toString()),
            _SummaryMetric(label: 'Saved', value: favourites.toString()),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: TextaraSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _ShelfHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }
}
