import 'package:flutter/material.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/readiness_snapshot.dart';

/// Compact, phone-friendly list of the highest-impact gaps on a career path.
///
/// This widget is intentionally presentation-only. It consumes the existing
/// [CareerReadinessSnapshot] so Home/My Path never invent a second readiness
/// calculation.
class MajorGapsSection extends StatelessWidget {
  final CareerReadinessSnapshot snapshot;
  final int maxItems;
  final ValueChanged<Requirement>? onRequirementTap;
  final VoidCallback? onViewAll;

  const MajorGapsSection({
    super.key,
    required this.snapshot,
    this.maxItems = 4,
    this.onRequirementTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final gaps = snapshot.majorGaps.take(maxItems).toList();
    if (gaps.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MAJOR GAPS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (onViewAll != null)
                TextButton(onPressed: onViewAll, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _summary(snapshot.majorGapCount),
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...gaps.map((item) => _GapRow(
                requirement: item.requirement,
                label: gapLabel(snapshot, item),
                onTap: onRequirementTap == null
                    ? null
                    : () => onRequirementTap!(item.requirement),
              )),
        ],
      ),
    );
  }

  static String _summary(int count) =>
      count == 1 ? '1 major item remains.' : '$count major items remain.';

  static String gapLabel(
    CareerReadinessSnapshot snapshot,
    dynamic item,
  ) {
    final id = item.requirement.id as String;
    bool contains(List list) => list.any((e) => e.requirement.id == id);

    if (contains(snapshot.prerequisiteGaps)) return 'PREREQUISITE';
    if (contains(snapshot.coreGaps)) return 'CORE';
    if (contains(snapshot.experienceGaps)) return 'EXPERIENCE';
    if (contains(snapshot.taskBookGaps)) return 'TASK BOOK';
    if (contains(snapshot.departmentGaps)) return 'DEPARTMENT';
    return 'REQUIREMENT';
  }
}

class _GapRow extends StatelessWidget {
  final Requirement requirement;
  final String label;
  final VoidCallback? onTap;

  const _GapRow({
    required this.requirement,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requirement.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
