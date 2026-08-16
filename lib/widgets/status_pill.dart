import 'package:flutter/material.dart';

/// Compact status chip for readiness, cert health, and story state.
class StatusPill extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double maxWidth;

  const StatusPill({
    super.key,
    required this.text,
    this.backgroundColor,
    this.foregroundColor,
    this.maxWidth = 155,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
            ),
      ),
    );
  }
}
