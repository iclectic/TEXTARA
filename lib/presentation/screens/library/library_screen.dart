import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/data/services/import_service.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/widgets/library/book_grid_tile.dart';
import 'package:textara/presentation/widgets/library/book_list_tile.dart';
import 'package:textara/presentation/widgets/library/continue_reading_card.dart';
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
    HapticFeedback.mediumImpact();
    final importService = ref.read(importServiceProvider);
    final results = await importService.pickAndImportFiles();

    if (!mounted) return;
    if (results.isEmpty) return;

    final successCount = results.where((r) => r.success).length;
    final failures = results.where((r) => !r.success).toList();

    if (successCount > 0) {
      ref.read(booksProvider.notifier).loadBooks();
    }

    if (failures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successCount == 1
                ? 'Book imported successfully.'
                : '$successCount books imported successfully.',
          ),
        ),
      );
      return;
    }

    final summary = successCount == 0
        ? '${failures.length} import${failures.length == 1 ? '' : 's'} failed'
        : '$successCount imported, ${failures.length} failed';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(summary),
        action: SnackBarAction(
          label: 'Details',
          onPressed: () => _showImportFailures(failures),
        ),
        duration: const Duration(seconds: 6),
      ),
    );

    // Always surface reasons when everything failed.
    if (successCount == 0) {
      await _showImportFailures(failures);
    }
  }

  Future<void> _showImportFailures(List<ImportResult> failures) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import issues',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Textara never removes DRM. Files over the size limit or with unsupported compression are rejected with a reason.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: failures.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = failures[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.sourceFileName ?? 'Unknown file',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.errorMessage ?? 'Import failed.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              height: 1.4,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          : books.isEmpty
          ? LibraryEmptyState(onImport: _importBooks)
          : _buildBooksList(books, viewMode, isTablet),
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

  Widget _buildBooksList(
    List<Book> books,
    LibraryViewMode viewMode,
    bool isTablet,
  ) {
    final continueBook = ref.watch(continueReadingBookProvider);

    if (viewMode == LibraryViewMode.list) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: books.length + (continueBook != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (continueBook != null && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ContinueReadingCard(
                book: continueBook,
                onContinue: () => _openBook(continueBook),
              ),
            );
          }
          final bookIndex = continueBook != null ? index - 1 : index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: BookListTile(
              book: books[bookIndex],
              onTap: () => _openBook(books[bookIndex]),
              onFavourite: () {
                ref
                    .read(booksProvider.notifier)
                    .toggleFavourite(books[bookIndex].id);
              },
            ),
          );
        },
      );
    }

    final crossAxisCount = isTablet ? 4 : 2;
    return CustomScrollView(
      slivers: [
        if (continueBook != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ContinueReadingCard(
                book: continueBook,
                onContinue: () => _openBook(continueBook),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return BookGridTile(
                  book: books[index],
                  onTap: () => _openBook(books[index]),
                );
              },
              childCount: books.length,
            ),
          ),
        ),
      ],
    );
  }
}
