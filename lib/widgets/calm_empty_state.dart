import 'package:flutter/material.dart';

import 'package:firepath/services/theme.dart';

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
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: cs.outline.withValues(alpha: 0.9)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
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
    );
  }
}
