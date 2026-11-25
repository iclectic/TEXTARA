import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/data/services/import_service.dart';
import 'package:textara/data/services/incoming_bridge.dart';
import 'package:textara/data/services/incoming_requests.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/presentation/providers/app_providers.dart';

/// Listens for books shared into Textara and for `textara://book/<id>` links.
class IncomingImportHost extends ConsumerStatefulWidget {
  final Widget child;

  const IncomingImportHost({super.key, required this.child});

  @override
  ConsumerState<IncomingImportHost> createState() => _IncomingImportHostState();
}

class _IncomingImportHostState extends ConsumerState<IncomingImportHost>
    with WidgetsBindingObserver {
  late final IncomingBridge _bridge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bridge = IncomingBridge();
    _bridge.onRequests = _handleRequests;
    unawaited(_bridge.start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bridge.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_bridge.drain());
    }
  }

  Future<void> _handleRequests(List<IncomingRequest> requests) async {
    final files = requests
        .where((request) => request.kind == IncomingKind.file)
        .map((request) => request.value)
        .toList();
    final bookIds = requests
        .where((request) => request.kind == IncomingKind.book)
        .map((request) => request.value)
        .toList();

    Book? imported;
    if (files.isNotEmpty) {
      imported = await _importFiles(files);
    }
    if (!mounted) return;

    if (bookIds.isNotEmpty) {
      await _openBookId(bookIds.last);
    } else if (imported != null) {
      ref.read(pendingReaderOpenProvider.notifier).state = PendingReaderOpen(
        book: imported,
      );
    }
  }

  Future<Book?> _importFiles(List<String> paths) async {
    final progress = ref.read(importProgressProvider.notifier);
    progress.startImport(
      paths
          .map(
            (path) => ImportJobFile(
              path: path,
              fileName: path.split(RegExp(r'[/\\]')).last,
            ),
          )
          .toList(),
    );

    final results = await ref
        .read(importServiceProvider)
        .importPaths(
          paths,
          onProgress: (completed, total, fileName) {
            progress.updateProgress(completed, fileName);
          },
          isCancelled: () => progress.isCancelled,
          onDuplicate: _resolveDuplicate,
        );
    progress.completeImport();
    if (!mounted) return null;

    await ref.read(booksProvider.notifier).loadBooks();
    if (!mounted) return null;
    _showSummary(results);

    final imported = results
        .where(
          (result) => result.success && result.book != null && !result.skipped,
        )
        .map((result) => result.book!)
        .toList();
    if (imported.length == 1) return imported.first;
    return null;
  }

  Future<DuplicateResolution> _resolveDuplicate(
    Book existing,
    Book incoming,
  ) async {
    if (!mounted) return DuplicateResolution.skip;
    final choice = await showDialog<DuplicateResolution>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate book'),
        content: Text(
          '"${existing.title}" by ${existing.author} is already in your library. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, DuplicateResolution.skip),
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
  }

  void _showSummary(List<ImportResult> results) {
    if (!mounted || results.isEmpty) return;
    final successCount = results.where((r) => r.success && !r.skipped).length;
    final skippedCount = results.where((r) => r.skipped).length;
    final failures = results.where((r) => !r.success).toList();
    final parts = <String>[];
    if (successCount > 0) {
      parts.add(
        successCount == 1 ? '1 book imported' : '$successCount books imported',
      );
    }
    if (skippedCount > 0) parts.add('$skippedCount skipped');
    if (failures.isNotEmpty) parts.add('${failures.length} failed');
    final message = parts.isEmpty
        ? 'Nothing was imported.'
        : '${parts.join(', ')}.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openBookId(String id) async {
    final book = await ref.read(libraryRepositoryProvider).getBookById(id);
    if (!mounted) return;
    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That book is not in your library.')),
      );
      return;
    }
    ref.read(pendingReaderOpenProvider.notifier).state = PendingReaderOpen(
      book: book,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
