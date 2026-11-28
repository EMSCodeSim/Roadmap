import 'package:flutter/material.dart';

import 'package:firepath/services/theme.dart';

/// A modern, dense, no-splash card tile used for primary navigation rows.
///
/// This widget is intentionally behavior-agnostic: it only renders UI and
/// forwards taps to [onTap].
class AppCardTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const AppCardTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.iconBackground,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final effectiveTrailing = trailing ?? const Icon(Icons.chevron_right_rounded);

    final content = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LeadingIcon(
            icon: icon,
            foregroundColor: iconColor ?? cs.primary,
            backgroundColor: iconBackground ?? cs.primaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                if ((subtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!.trim(),
                    maxLines: 4,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.25),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconTheme(
            data: IconThemeData(color: cs.onSurfaceVariant),
            child: effectiveTrailing,
          ),
        ],
      ),
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: cs.primary.withValues(alpha: 0.06),
          child: content,
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  const _LeadingIcon({
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: foregroundColor, size: 20),
    );
  }
}
