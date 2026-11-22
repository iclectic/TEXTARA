import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/theme/leaf_tokens.dart';
import 'package:textara/domain/entities/collection.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:uuid/uuid.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  Future<void> _createOrEdit(
    BuildContext context,
    WidgetRef ref, {
    Collection? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController = TextEditingController(
      text: existing?.description ?? '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'New collection' : 'Edit collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: LeafTokens.spaceMd),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final now = DateTime.now();
    final collection = Collection(
      id: existing?.id ?? const Uuid().v4(),
      name: name,
      description: descController.text.trim().isEmpty
          ? null
          : descController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      bookCount: existing?.bookCount ?? 0,
    );
    final dao = ref.read(collectionDaoProvider);
    if (existing == null) {
      await dao.insertCollection(collection);
    } else {
      await dao.updateCollection(collection);
    }
    ref.invalidate(collectionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEdit(context, ref),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New'),
      ),
      body: collectionsAsync.when(
        data: (collections) {
          if (collections.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(LeafTokens.spaceXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No collections yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: LeafTokens.spaceSm),
                    Text(
                      'Group books by topic, course, or mood. Assign books from the library details sheet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(LeafTokens.spaceMd),
            itemCount: collections.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: LeafTokens.spaceSm),
            itemBuilder: (context, index) {
              final c = collections[index];
              return Card(
                child: ListTile(
                  title: Text(c.name),
                  subtitle: Text(
                    c.description?.isNotEmpty == true
                        ? c.description!
                        : '${c.bookCount} books',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _createOrEdit(context, ref, existing: c);
                      } else if (value == 'delete') {
                        await ref
                            .read(collectionDaoProvider)
                            .deleteCollection(c.id);
                        ref.invalidate(collectionsProvider);
                        ref
                                .read(libraryCollectionFilterProvider.notifier)
                                .state =
                            null;
                      } else if (value == 'filter') {
                        ref
                                .read(libraryCollectionFilterProvider.notifier)
                                .state =
                            c.id;
                        Navigator.pop(context);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'filter',
                        child: Text('Show in library'),
                      ),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load collections: $e')),
      ),
    );
  }
}
