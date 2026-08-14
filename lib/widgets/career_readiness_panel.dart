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
    final majorGaps = snapshot.majorGaps.take(maxMajorGaps).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CareerReadinessCard(
          snapshot: snapshot,
          goalTitle: goalTitle,
          onTap: onViewPath,
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
            onActionTap: onActionTap,
          ),
        ],
      ],
    );
  }
}
