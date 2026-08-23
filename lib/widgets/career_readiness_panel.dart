import 'package:flutter/material.dart';

import 'package:firepath/services/readiness_action_plan.dart';
import 'package:firepath/services/readiness_snapshot.dart';
import 'package:firepath/widgets/career_readiness_card.dart';
import 'package:firepath/widgets/major_gaps_section.dart';
import 'package:firepath/widgets/readiness_action_section.dart';

/// A single drop-in, phone-friendly readiness surface for Home/My Path.
///
/// It composes the existing readiness summary, major gaps, and top actions so
/// host pages only need to provide the snapshot/action plan and routing
/// callbacks. No roadmap logic is duplicated here.
class CareerReadinessPanel extends StatelessWidget {
  final CareerReadinessSnapshot snapshot;
  final CareerReadinessActionPlan actionPlan;
  final String goalTitle;
  final ValueChanged<ReadinessActionItem>? onActionTap;
  final VoidCallback? onViewPath;
  final int maxMajorGaps;

  const CareerReadinessPanel({
    super.key,
    required this.snapshot,
    required this.actionPlan,
    required this.goalTitle,
    this.onActionTap,
    this.onViewPath,
    this.maxMajorGaps = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final majorGaps = snapshot.majorGaps.take(maxMajorGaps).toList();
    final trimmedGoal = goalTitle.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trimmedGoal.isNotEmpty) ...[
          Text(
            trimmedGoal,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
        ],
        CareerReadinessCard(
          snapshot: snapshot,
          // The readiness card exposes a "view gaps" affordance. In this panel,
          // we reuse it as the main navigation entrypoint to the user's path.
          onViewGaps: onViewPath,
        ),
        if (majorGaps.isNotEmpty) ...[
          const SizedBox(height: 12),
          MajorGapsSection(
            snapshot: snapshot,
            maxItems: maxMajorGaps,
          ),
        ],
        if (actionPlan.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          ReadinessActionSection(
            plan: actionPlan,
            onAction: onActionTap,
          ),
        ],
      ],
    );
  }
}
