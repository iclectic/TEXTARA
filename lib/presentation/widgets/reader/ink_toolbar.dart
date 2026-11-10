import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textara/domain/entities/ink_stroke.dart';

class InkToolbar extends StatelessWidget {
  final InkTool tool;
  final ValueChanged<InkTool> onToolChanged;
  final VoidCallback? onClearPage;

  const InkToolbar({
    super.key,
    required this.tool,
    required this.onToolChanged,
    this.onClearPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.96),
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolButton(
              selected: tool == InkTool.off,
              icon: Icons.pan_tool_alt_rounded,
              tooltip: 'Ink off — scroll normally',
              onTap: () {
                HapticFeedback.selectionClick();
                onToolChanged(InkTool.off);
              },
            ),
            _ToolButton(
              selected: tool == InkTool.pen,
              icon: Icons.edit_rounded,
              tooltip: 'Pen (stylus preferred)',
              onTap: () {
                HapticFeedback.selectionClick();
                onToolChanged(InkTool.pen);
              },
            ),
            _ToolButton(
              selected: tool == InkTool.highlighter,
              icon: Icons.highlight_rounded,
              tooltip: 'Highlighter',
              onTap: () {
                HapticFeedback.selectionClick();
                onToolChanged(InkTool.highlighter);
              },
            ),
            _ToolButton(
              selected: tool == InkTool.eraser,
              icon: Icons.auto_fix_high_rounded,
              tooltip: 'Eraser',
              onTap: () {
                HapticFeedback.selectionClick();
                onToolChanged(InkTool.eraser);
              },
            ),
            if (onClearPage != null) ...[
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: theme.dividerColor,
              ),
              _ToolButton(
                selected: false,
                icon: Icons.delete_sweep_outlined,
                tooltip: 'Clear ink on this page',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onClearPage!();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolButton({
    required this.selected,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 20,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
      ),
    );
  }
}
