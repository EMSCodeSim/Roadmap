import 'package:flutter/material.dart';

import 'package:firepath/services/theme.dart';

/// Calm loading panel to avoid "empty white screen" moments.
class CalmLoading extends StatelessWidget {
  final String? label;

  const CalmLoading({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Card(
        child: Padding(
          padding: AppCardTokens.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: cs.primary),
              ),
              if ((label ?? '').trim().isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(label!.trim(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
