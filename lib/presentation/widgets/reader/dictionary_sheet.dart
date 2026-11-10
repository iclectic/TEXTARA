import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/domain/entities/dictionary_entry.dart';
import 'package:textara/presentation/providers/app_providers.dart';

Future<void> showDictionarySheet(
  BuildContext context, {
  required String selection,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DictionarySheet(selection: selection),
  );
}

class DictionarySheet extends ConsumerStatefulWidget {
  final String selection;

  const DictionarySheet({super.key, required this.selection});

  @override
  ConsumerState<DictionarySheet> createState() => _DictionarySheetState();
}

class _DictionarySheetState extends ConsumerState<DictionarySheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dictionaryLookupProvider.notifier).lookup(widget.selection);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = ref.watch(dictionaryLookupProvider);
    final onlineEnabled = ref.watch(dictionaryOnlineFallbackProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.48,
        minChildSize: 0.32,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return Material(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dictionary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      _buildBody(theme, result, onlineEnabled),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    DictionaryLookupResult result,
    bool onlineEnabled,
  ) {
    switch (result.status) {
      case DictionaryLookupStatus.idle:
      case DictionaryLookupStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        );
      case DictionaryLookupStatus.error:
        return _MessageState(
          icon: Icons.wifi_off_rounded,
          title: 'Lookup failed',
          body: result.errorMessage ?? 'Something went wrong.',
          actionLabel: 'Try again',
          onAction: () => ref
              .read(dictionaryLookupProvider.notifier)
              .lookup(widget.selection),
        );
      case DictionaryLookupStatus.notFound:
        return _MessageState(
          icon: Icons.menu_book_outlined,
          title: 'No definition found',
          body: onlineEnabled
              ? '“${result.query}” is not in the offline pack or online results.'
              : '“${result.query}” is not in the offline dictionary. You can enable optional online lookup in Settings — it stays off by default for privacy.',
          actionLabel: onlineEnabled ? 'Try again' : null,
          onAction: onlineEnabled
              ? () => ref
                  .read(dictionaryLookupProvider.notifier)
                  .lookup(widget.selection)
              : null,
        );
      case DictionaryLookupStatus.found:
        final entry = result.entry!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.word,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _sourceLabel(entry.source, result.usedNetwork),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < entry.senses.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _SenseCard(sense: entry.senses[i], index: i + 1),
            ],
          ],
        );
    }
  }

  String _sourceLabel(DictionarySource source, bool usedNetwork) {
    switch (source) {
      case DictionarySource.offline:
        return 'Offline dictionary';
      case DictionarySource.cache:
        return 'Saved on this device';
      case DictionarySource.online:
        return usedNetwork
            ? 'Online lookup (cached on this device)'
            : 'Online dictionary';
    }
  }
}

class _SenseCard extends StatelessWidget {
  final DictionarySense sense;
  final int index;

  const _SenseCard({required this.sense, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label:
          'Sense $index. ${sense.partOfSpeech}. ${sense.definition}'
          '${sense.example != null ? '. Example: ${sense.example}' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sense.partOfSpeech,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sense.definition,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          if (sense.example != null && sense.example!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '“${sense.example!.trim()}”',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
