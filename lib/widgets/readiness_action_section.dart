import 'package:flutter/material.dart';

import 'package:firepath/services/readiness_action_plan.dart';

/// Compact, phone-first presentation of the user's highest-priority readiness
/// actions. Routing stays outside this widget so Home/My Path can decide where
/// each action should navigate.
class ReadinessActionSection extends StatelessWidget {
  final CareerReadinessActionPlan plan;
  final void Function(ReadinessActionItem item)? onAction;
  final int maxVisible;

  const ReadinessActionSection({
    super.key,
    required this.plan,
    this.onAction,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.items.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final visible = plan.items.take(maxVisible).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT TO WORK ON',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your highest-priority remaining actions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          ...visible.indexed.map((entry) {
            final index = entry.$1;
            final item = entry.$2;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == visible.length - 1 ? 0 : 12,
              ),
              child: _ActionRow(
                item: item,
                rank: index + 1,
                onTap: onAction == null ? null : () => onAction!(item),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final ReadinessActionItem item;
  final int rank;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.item,
    required this.rank,
    required this.onTap,
  });

  IconData get _icon {
    switch (item.actionKind) {
      case ReadinessActionKind.getStarted:
        return Icons.flag_outlined;
      case ReadinessActionKind.seePrerequisite:
        return Icons.account_tree_outlined;
      case ReadinessActionKind.logProgress:
        return Icons.add_chart_outlined;
      case ReadinessActionKind.updateTaskBook:
        return Icons.checklist_outlined;
      case ReadinessActionKind.viewTraining:
        return Icons.event_available_outlined;
      case ReadinessActionKind.continueWork:
        return Icons.play_arrow_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$rank',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.requirement.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(_icon, size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          item.actionLabel,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
