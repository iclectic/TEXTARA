import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaf_reader/core/constants/enums.dart';
import 'package:leaf_reader/presentation/providers/app_providers.dart';

class SortBottomSheet extends ConsumerWidget {
  const SortBottomSheet({super.key});

  String _sortLabel(LibrarySortField field) {
    switch (field) {
      case LibrarySortField.lastAdded:
        return 'Date added';
      case LibrarySortField.recentlyOpened:
        return 'Recently opened';
      case LibrarySortField.title:
        return 'Title';
      case LibrarySortField.author:
        return 'Author';
      case LibrarySortField.progress:
        return 'Progress';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentField = ref.watch(librarySortProvider);
    final currentOrder = ref.watch(librarySortOrderProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 20),
            Text(
              'Sort by',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...LibrarySortField.values.map((field) {
              final isSelected = field == currentField;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
                title: Text(
                  _sortLabel(field),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(librarySortProvider.notifier).state = field;
                },
              );
            }),
            const Divider(height: 24),
            Row(
              children: [
                Text(
                  'Order',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SegmentedButton<SortOrder>(
                  segments: const [
                    ButtonSegment(
                      value: SortOrder.ascending,
                      label: Text('A to Z'),
                      icon: Icon(Icons.arrow_upward_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: SortOrder.descending,
                      label: Text('Z to A'),
                      icon: Icon(Icons.arrow_downward_rounded, size: 16),
                    ),
                  ],
                  selected: {currentOrder},
                  onSelectionChanged: (set) {
                    HapticFeedback.selectionClick();
                    ref.read(librarySortOrderProvider.notifier).state =
                        set.first;
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
