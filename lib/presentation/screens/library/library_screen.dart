import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/core/layout/textara_layout.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/search_result.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/core/theme/leaf_tokens.dart';
import 'package:textara/presentation/screens/library/collections_screen.dart';
import 'package:textara/presentation/screens/reader/reader_screen.dart';
import 'package:textara/presentation/screens/shell/app_shell.dart';
import 'package:textara/presentation/widgets/common/async_state_views.dart';
import 'package:textara/presentation/widgets/library/book_details_sheet.dart';
import 'package:textara/presentation/widgets/library/book_grid_tile.dart';
import 'package:textara/presentation/widgets/library/book_list_tile.dart';
import 'package:textara/presentation/widgets/library/library_empty_state.dart';
import 'package:textara/presentation/widgets/library/sort_bottom_sheet.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final bool embeddedInShell;

  const LibraryScreen({super.key, this.embeddedInShell = false});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Book? _paneBook;
  String? _paneChapterId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _consumePendingOpen();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _consumePendingOpen() {
    final pending = ref.read(pendingReaderOpenProvider);
    if (pending == null || !mounted) return;
    ref.read(pendingReaderOpenProvider.notifier).state = null;
    unawaited(_openBook(pending.book, chapterId: pending.chapterId));
  }

  void _closeReaderPane() {
    setState(() {
      _paneBook = null;
      _paneChapterId = null;
    });
    ref.read(libraryReaderPaneOpenProvider.notifier).state = false;
  }

  Future<void> _importBooks() async {
    final lowStim = ref.read(lowStimulationProvider);
    if (!lowStim) {
      unawaited(HapticFeedback.mediumImpact());
    }
    final progress = ref.read(importProgressProvider.notifier);
    final importService = ref.read(importServiceProvider);

    final results = await importService.pickAndImportFiles(
      onProgress: (completed, total, fileName) {
        if (completed == 0 && total > 0) {
          progress.startImport(
            List.generate(
              total,
              (i) => ImportJobFile(
                path: '',
                fileName: fileName ?? 'file ${i + 1}',
              ),
            ),
          );
        }
        progress.updateProgress(completed, fileName);
      },
      isCancelled: () => progress.isCancelled,
      onDuplicate: (existing, incoming) async {
        if (!mounted) return DuplicateResolution.keepBoth;
        final choice = await showDialog<DuplicateResolution>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Duplicate book'),
            content: Text(
              '"${existing.title}" by ${existing.author} is already in your library. What would you like to do?',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, DuplicateResolution.skip),
                child: const Text('Skip'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, DuplicateResolution.replace),
                child: const Text('Replace'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, DuplicateResolution.keepBoth),
                child: const Text('Keep both'),
              ),
            ],
          ),
        );
        return choice ?? DuplicateResolution.skip;
      },
    );

    progress.completeImport();
    if (!mounted) return;

    final successCount = results.where((r) => r.success && !r.skipped).length;
    final skippedCount = results.where((r) => r.skipped).length;
    final failures = results.where((r) => !r.success).toList();

    if (results.isNotEmpty) {
      await ref.read(booksProvider.notifier).loadBooks();
      if (!mounted) return;
      final parts = <String>[];
      if (successCount > 0) {
        parts.add(
          successCount == 1
              ? '1 book imported'
              : '$successCount books imported',
        );
      }
      if (skippedCount > 0) {
        parts.add('$skippedCount skipped');
      }
      if (failures.isNotEmpty) {
        parts.add('${failures.length} failed');
      }

      if (failures.isNotEmpty) {
        final details = failures
            .map((r) {
              final name = r.sourceFileName ?? 'Unknown file';
              final reason = r.errorMessage ?? 'Unknown error';
              return '• $name — $reason';
            })
            .join('\n');
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import summary'),
            content: SingleChildScrollView(
              child: Text('${parts.join(', ')}.\n\n$details'),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${parts.join(', ')}.')));
      }
    }
  }

  Future<void> _openBook(Book book, {String? chapterId}) async {
    final lowStim = ref.read(lowStimulationProvider);
    if (!lowStim) {
      unawaited(HapticFeedback.lightImpact());
    }
    await ref.read(libraryRepositoryProvider).updateLastOpened(book.id);
    if (!mounted) return;
    if (isTextaraTablet(MediaQuery.sizeOf(context))) {
      setState(() {
        _paneBook = book;
        _paneChapterId = chapterId;
      });
      ref.read(libraryReaderPaneOpenProvider.notifier).state = true;
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(book: book, initialChapterId: chapterId),
      ),
    );
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
    final importProgress = ref.watch(importProgressProvider);
    final isTablet = isTextaraTablet(MediaQuery.sizeOf(context));

    ref.listen<PendingReaderOpen?>(pendingReaderOpenProvider, (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _consumePendingOpen();
      });
    });
    ref.listen<bool>(libraryReaderPaneOpenProvider, (previous, next) {
      if (!next &&
          _paneBook != null &&
          isTextaraTablet(MediaQuery.sizeOf(context))) {
        setState(() {
          _paneBook = null;
          _paneChapterId = null;
        });
      }
    });
    final paneShouldBlockBack = isTablet && _paneBook != null;
    if (ref.read(libraryReaderPaneOpenProvider) != paneShouldBlockBack) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final block =
            isTextaraTablet(MediaQuery.sizeOf(context)) && _paneBook != null;
        if (ref.read(libraryReaderPaneOpenProvider) != block) {
          ref.read(libraryReaderPaneOpenProvider.notifier).state = block;
        }
      });
    }

    final library = Scaffold(
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
            icon: const Icon(Icons.folder_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CollectionsScreen()),
              );
            },
            tooltip: 'Collections',
          ),
          if (!widget.embeddedInShell)
            IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AppShell()),
                );
              },
              tooltip: 'Open shell',
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_isSearching) _buildFilterChips(theme),
          if (importProgress.isImporting)
            Material(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: importProgress.progress > 0
                            ? importProgress.progress
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        importProgress.currentFileName == null
                            ? 'Importing ${importProgress.completed}/${importProgress.total}…'
                            : 'Importing ${importProgress.currentFileName} '
                                  '(${importProgress.completed}/${importProgress.total})',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(importProgressProvider.notifier)
                          .requestCancel(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : booksState is AsyncError
                ? _ErrorState(
                    onRetry: () => ref.read(booksProvider.notifier).loadBooks(),
                  )
                : isSearching
                ? _buildSearchBody(theme)
                : books.isEmpty
                ? LibraryEmptyState(onImport: _importBooks)
                : _buildBooksList(books, viewMode),
          ),
        ],
      ),
      floatingActionButton:
          (!isSearching && books.isNotEmpty && !importProgress.isImporting)
          ? FloatingActionButton.extended(
              onPressed: _importBooks,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Import'),
              tooltip: 'Import books',
            )
          : null,
    );

    if (!isTablet) return library;

    return Row(
      children: [
        Expanded(flex: 2, child: library),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: _paneBook == null
              ? const _ReaderPlaceholder()
              : ReaderScreen(
                  key: ValueKey('${_paneBook!.id}:${_paneChapterId ?? ''}'),
                  book: _paneBook!,
                  initialChapterId: _paneChapterId,
                  onClose: _closeReaderPane,
                ),
        ),
      ],
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
              onTap: () => _openBook(
                results[index].book,
                chapterId: results[index].chapterId,
              ),
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

  Widget _buildFilterChips(ThemeData theme) {
    final favouritesOnly = ref.watch(libraryFavouritesOnlyProvider);
    final status = ref.watch(libraryStatusFilterProvider);
    final format = ref.watch(libraryFormatFilterProvider);
    final collectionId = ref.watch(libraryCollectionFilterProvider);
    final collections = ref.watch(collectionsProvider).valueOrNull ?? const [];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        LeafTokens.spaceMd,
        LeafTokens.spaceSm,
        LeafTokens.spaceMd,
        LeafTokens.spaceSm,
      ),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Favourites'),
            selected: favouritesOnly,
            onSelected: (v) =>
                ref.read(libraryFavouritesOnlyProvider.notifier).state = v,
          ),
          const SizedBox(width: LeafTokens.spaceSm),
          FilterChip(
            label: Text(status?.name ?? 'Status'),
            selected: status != null,
            onSelected: (_) async {
              final next = await showModalBottomSheet<ReadingStatus?>(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Any status'),
                        onTap: () => Navigator.pop(context, null),
                      ),
                      ...ReadingStatus.values.map(
                        (s) => ListTile(
                          title: Text(s.name),
                          onTap: () => Navigator.pop(context, s),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              ref.read(libraryStatusFilterProvider.notifier).state = next;
            },
          ),
          const SizedBox(width: LeafTokens.spaceSm),
          FilterChip(
            label: Text(format?.name.toUpperCase() ?? 'Format'),
            selected: format != null,
            onSelected: (_) async {
              final next = await showModalBottomSheet<BookFormat?>(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Any format'),
                        onTap: () => Navigator.pop(context, null),
                      ),
                      ...BookFormat.values.map(
                        (f) => ListTile(
                          title: Text(f.name.toUpperCase()),
                          onTap: () => Navigator.pop(context, f),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              ref.read(libraryFormatFilterProvider.notifier).state = next;
            },
          ),
          if (collections.isNotEmpty) ...[
            const SizedBox(width: LeafTokens.spaceSm),
            FilterChip(
              label: Text(
                collectionId == null
                    ? 'Collection'
                    : collections
                          .firstWhere(
                            (c) => c.id == collectionId,
                            orElse: () => collections.first,
                          )
                          .name,
              ),
              selected: collectionId != null,
              onSelected: (_) async {
                final next = await showModalBottomSheet<String?>(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('All collections'),
                          onTap: () => Navigator.pop(context, null),
                        ),
                        ...collections.map(
                          (c) => ListTile(
                            title: Text(c.name),
                            onTap: () => Navigator.pop(context, c.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                ref.read(libraryCollectionFilterProvider.notifier).state = next;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBooksList(List<Book> books, LibraryViewMode viewMode) {
    final reduced = ref.watch(reducedMotionProvider);
    if (viewMode == LibraryViewMode.list) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          return _Appear(
            index: index,
            reducedMotion: reduced,
            child: BookListTile(
              book: books[index],
              onTap: () => _openBook(books[index]),
              onLongPress: () =>
                  showBookDetailsSheet(context: context, book: books[index]),
              onFavourite: () {
                ref
                    .read(booksProvider.notifier)
                    .toggleFavourite(books[index].id);
              },
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 5
            : width >= 800
            ? 4
            : width >= 520
            ? 3
            : 2;
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
            return _Appear(
              index: index,
              reducedMotion: reduced,
              child: BookGridTile(
                book: books[index],
                onTap: () => _openBook(books[index]),
                onLongPress: () =>
                    showBookDetailsSheet(context: context, book: books[index]),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReaderPlaceholder extends StatelessWidget {
  const _ReaderPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Select a book to read',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _Appear extends StatelessWidget {
  final int index;
  final bool reducedMotion;
  final Widget child;

  const _Appear({
    required this.index,
    required this.reducedMotion,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (reducedMotion || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: LeafTokens.motionFast + Duration(milliseconds: 20 * index),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: child,
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
    return AppErrorView(message: message, onRetry: onRetry);
  }
}
