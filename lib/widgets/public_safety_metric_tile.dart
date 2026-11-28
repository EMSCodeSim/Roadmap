import 'package:flutter/material.dart';

import 'package:firepath/services/theme.dart';

/// Compact metric tile used on responder dashboards.
///
/// Designed for 3-up layouts on small phones with strong hierarchy and
/// accessible contrast.
class PublicSafetyMetricTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String value;
  final String label;

  const PublicSafetyMetricTile({
    super.key,
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
