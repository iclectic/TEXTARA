import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/core/theme/leaf_tokens.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/presentation/providers/app_providers.dart';

Future<void> showBookDetailsSheet({
  required BuildContext context,
  required Book book,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => BookDetailsSheet(book: book),
  );
}

class BookDetailsSheet extends ConsumerStatefulWidget {
  final Book book;

  const BookDetailsSheet({super.key, required this.book});

  @override
  ConsumerState<BookDetailsSheet> createState() => _BookDetailsSheetState();
}

class _BookDetailsSheetState extends ConsumerState<BookDetailsSheet> {
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _tags;
  late ReadingStatus _status;
  final Set<String> _selectedCollections = {};

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.book.title);
    _author = TextEditingController(text: widget.book.author);
    _tags = TextEditingController(text: widget.book.tags.join(', '));
    _status = widget.book.readingStatus;
    _loadMembership();
  }

  Future<void> _loadMembership() async {
    final collections = await ref
        .read(collectionDaoProvider)
        .getAllCollections();
    for (final c in collections) {
      final ids = await ref
          .read(collectionDaoProvider)
          .getBookIdsForCollection(c.id);
      if (ids.contains(widget.book.id)) {
        _selectedCollections.add(c.id);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tags = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final updated = widget.book.copyWith(
      title: _title.text.trim().isEmpty
          ? widget.book.title
          : _title.text.trim(),
      author: _author.text.trim().isEmpty
          ? widget.book.author
          : _author.text.trim(),
      tags: tags,
      readingStatus: _status,
    );
    await ref.read(booksProvider.notifier).updateBook(updated);

    final dao = ref.read(collectionDaoProvider);
    final all = await dao.getAllCollections();
    for (final c in all) {
      final ids = await dao.getBookIdsForCollection(c.id);
      final inCollection = ids.contains(widget.book.id);
      final shouldBe = _selectedCollections.contains(c.id);
      if (shouldBe && !inCollection) {
        await dao.addBookToCollection(widget.book.id, c.id);
      } else if (!shouldBe && inCollection) {
        await dao.removeBookFromCollection(widget.book.id, c.id);
      }
    }
    ref.invalidate(collectionsProvider);
    ref.invalidate(collectionBookIdsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collectionsAsync = ref.watch(collectionsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            LeafTokens.spaceLg,
            LeafTokens.spaceMd,
            LeafTokens.spaceLg,
            LeafTokens.spaceLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: LeafTokens.spaceMd),
              Text(
                'Book details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: LeafTokens.spaceMd),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: LeafTokens.spaceMd),
              TextField(
                controller: _author,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              const SizedBox(height: LeafTokens.spaceMd),
              TextField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                ),
              ),
              const SizedBox(height: LeafTokens.spaceMd),
              DropdownButtonFormField<ReadingStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ReadingStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: LeafTokens.spaceMd),
              Text('Collections', style: theme.textTheme.labelLarge),
              const SizedBox(height: LeafTokens.spaceSm),
              collectionsAsync.when(
                data: (collections) {
                  if (collections.isEmpty) {
                    return Text(
                      'No collections yet. Create one from the Collections screen.',
                      style: theme.textTheme.bodySmall,
                    );
                  }
                  return Wrap(
                    spacing: LeafTokens.spaceSm,
                    children: collections.map((c) {
                      final selected = _selectedCollections.contains(c.id);
                      return FilterChip(
                        label: Text(c.name),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedCollections.add(c.id);
                            } else {
                              _selectedCollections.remove(c.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: LeafTokens.spaceLg),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
