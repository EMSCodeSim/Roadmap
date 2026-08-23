import 'package:flutter/material.dart';

/// A modern, consistent chip button used for multi-select role pickers.
///
/// - No splash (calmer feel)
/// - 44dp min height for reliable touch target
/// - Animated background/border transitions
class RoleToggleChip extends StatelessWidget {
  const RoleToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = selected ? cs.primaryContainer : cs.surface;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurface;
    final border = selected
        ? cs.primary.withValues(alpha: 0.28)
        : cs.outline.withValues(alpha: 0.22);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[
                      Icon(leading, size: 18, color: fg),
                      const SizedBox(width: 8),
                    ] else if (selected) ...[
                      Icon(Icons.check, size: 18, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
