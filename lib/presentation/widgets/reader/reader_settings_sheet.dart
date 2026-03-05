import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/presentation/providers/app_providers.dart';

class ReaderSettingsSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const ReaderSettingsSheet({super.key, required this.scrollController});

  static const _fontFamilies = [
    'Literata',
    'Merriweather',
    'Lora',
    'Source Serif Pro',
    'Inter',
    'Roboto',
    'Open Sans',
    'Atkinson Hyperlegible',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(readerSettingsProvider);
    final notifier = ref.read(readerSettingsProvider.notifier);
    final dyslexia = ref.watch(dyslexiaModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
            'Reader Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Font family
          Text('Font', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fontFamilies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final font = _fontFamilies[index];
                final isSelected = settings.fontFamily == font && !dyslexia;
                return ChoiceChip(
                  label: Text(font, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    notifier.setFontFamily(font);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Font size
          _SliderRow(
            label: 'Font size',
            value: settings.fontSize,
            min: AppConstants.minFontSize,
            max: AppConstants.maxFontSize,
            displayValue: '${settings.fontSize.round()}',
            onChanged: (v) => notifier.setFontSize(v),
          ),
          const SizedBox(height: 16),

          // Line height
          _SliderRow(
            label: 'Line height',
            value: settings.lineHeight,
            min: AppConstants.minLineHeight,
            max: AppConstants.maxLineHeight,
            displayValue: settings.lineHeight.toStringAsFixed(1),
            onChanged: (v) => notifier.setLineHeight(v),
          ),
          const SizedBox(height: 16),

          // Margins
          _SliderRow(
            label: 'Margins',
            value: settings.horizontalMargin,
            min: AppConstants.minMargin,
            max: AppConstants.maxMargin,
            displayValue: '${settings.horizontalMargin.round()}',
            onChanged: (v) => notifier.setMargin(v),
          ),
          const SizedBox(height: 20),

          // Text alignment
          Text('Alignment', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<TextAlignment>(
            segments: const [
              ButtonSegment(
                value: TextAlignment.left,
                icon: Icon(Icons.format_align_left_rounded, size: 18),
              ),
              ButtonSegment(
                value: TextAlignment.centre,
                icon: Icon(Icons.format_align_center_rounded, size: 18),
              ),
              ButtonSegment(
                value: TextAlignment.right,
                icon: Icon(Icons.format_align_right_rounded, size: 18),
              ),
              ButtonSegment(
                value: TextAlignment.justify,
                icon: Icon(Icons.format_align_justify_rounded, size: 18),
              ),
            ],
            selected: {settings.textAlignment},
            onSelectionChanged: (set) {
              HapticFeedback.selectionClick();
              notifier.setAlignment(set.first);
            },
          ),
          const SizedBox(height: 16),

          // Hyphenation toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hyphenation'),
            subtitle: const Text('Break long words across lines'),
            value: settings.hyphenationEnabled,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              notifier.toggleHyphenation();
            },
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            Text(
              displayValue,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
