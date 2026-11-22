import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/search_result.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/widgets/library/book_grid_tile.dart';
import 'package:textara/presentation/widgets/library/book_list_tile.dart';
import 'package:textara/presentation/widgets/library/library_empty_state.dart';
import 'package:textara/presentation/widgets/library/sort_bottom_sheet.dart';
import 'package:textara/presentation/screens/reader/reader_screen.dart';
import 'package:textara/presentation/screens/settings/settings_screen.dart';
import 'package:textara/presentation/screens/threads/idea_threads_screen.dart';

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
    final lowStim = ref.read(lowStimulationProvider);
    if (!lowStim) {
      unawaited(HapticFeedback.mediumImpact());
    }
    final importService = ref.read(importServiceProvider);
    final results = await importService.pickAndImportFiles();

    if (!mounted) return;

    final successCount = results.where((r) => r.success).length;
    final failCount = results.where((r) => !r.success).length;

    if (results.isNotEmpty) {
      await ref.read(booksProvider.notifier).loadBooks();
      if (!mounted) return;
      final String message;
      if (failCount == 0) {
        message = successCount == 1
            ? 'Book imported successfully.'
            : '$successCount books imported successfully.';
      } else {
        message =
            '$successCount imported, $failCount failed. Check file format and try again.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openBook(Book book) async {
    final lowStim = ref.read(lowStimulationProvider);
    if (!lowStim) {
      unawaited(HapticFeedback.lightImpact());
    }
    await ref.read(libraryRepositoryProvider).updateLastOpened(book.id);
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ReaderScreen(book: book)));
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });
    if (!_isSearching) {
      _searchController.clear();
      ref.read(librarySearchQueryProvider.notifier).state = '';
    }
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
    final searchQuery = ref.watch(librarySearchQueryProvider).trim();
    final isSearching = _isSearching && searchQuery.isNotEmpty;
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
              if (!ref.read(lowStimulationProvider)) {
                unawaited(HapticFeedback.selectionClick());
              }
              unawaited(ref.read(libraryViewModeProvider.notifier).toggle());
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
            icon: const Icon(Icons.account_tree_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IdeaThreadsScreen()),
              );
            },
            tooltip: 'Idea Threads',
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
          : booksState is AsyncError
          ? _ErrorState(
              onRetry: () => ref.read(booksProvider.notifier).loadBooks(),
            )
          : isSearching
          ? _buildSearchBody(theme)
          : books.isEmpty
          ? LibraryEmptyState(onImport: _importBooks)
          : _buildBooksList(books, viewMode, isTablet),
      floatingActionButton: (!isSearching && books.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: _importBooks,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Import'),
              tooltip: 'Import books',
            )
          : null,
    );
  }

  Widget _buildSearchBody(ThemeData theme) {
    final resultsAsync = ref.watch(librarySearchResultsProvider);
    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No books or passages matched your search.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: results.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            return _SearchResultTile(
              result: results[index],
              onTap: () => _openBook(results[index].book),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorState(
        message: 'Search failed. Please try again.',
        onRetry: () => ref.invalidate(librarySearchResultsProvider),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search title, author, tags, or text…',
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

    final crossAxisCount = isTablet ? 4 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
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

class _SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _SearchResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPassage = result.isFullTextMatch;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        foregroundColor: theme.colorScheme.primary,
        child: Icon(
          isPassage ? Icons.menu_book_outlined : Icons.auto_stories_outlined,
        ),
      ),
      title: Text(
        result.book.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (result.excerpt != null && result.excerpt!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              result.excerpt!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            isPassage ? 'Passage match' : 'Library match',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    this.message = 'Could not load your library.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
