import 'package:flutter/material.dart';

import 'package:firepath/theme.dart';

/// Calm, consistent empty-state panel used across top-level screens.
class CalmEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  const CalmEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.primaryAction,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(icon, size: 44, color: cs.primary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                ),
                if (primaryAction != null || secondaryAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  if (primaryAction != null) primaryAction!,
                  if (secondaryAction != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    secondaryAction!,
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
