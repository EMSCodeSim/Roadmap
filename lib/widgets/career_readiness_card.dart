import 'package:flutter/material.dart';

import 'package:firepath/services/readiness_snapshot.dart';

/// Compact presentation model for career readiness UI.
class CareerReadinessViewModel {
  final String percentLabel;
  final String gapLabel;
  final String statusLabel;
  final double progressValue;
  final bool isReady;

  const CareerReadinessViewModel({
    required this.percentLabel,
    required this.gapLabel,
    required this.statusLabel,
    required this.progressValue,
    required this.isReady,
  });

  factory CareerReadinessViewModel.fromSnapshot(
    CareerReadinessSnapshot snapshot,
  ) {
    final percent = (snapshot.percentComplete * 100).round().clamp(0, 100);
    final major = snapshot.majorGapCount;
    final remaining = snapshot.remainingCount;

    final gapLabel = snapshot.isReady
        ? 'All included requirements complete'
        : major > 0
            ? '$major major ${major == 1 ? 'gap' : 'gaps'} remaining'
            : '$remaining ${remaining == 1 ? 'requirement' : 'requirements'} remaining';

    final statusLabel = snapshot.isReady
        ? 'READY'
        : major == 0
            ? 'DEVELOPING'
            : major <= 2
                ? 'CLOSE'
                : 'BUILDING';

    return CareerReadinessViewModel(
      percentLabel: '$percent% ready',
      gapLabel: gapLabel,
      statusLabel: statusLabel,
      progressValue: snapshot.percentComplete.clamp(0, 1),
      isReady: snapshot.isReady,
    );
  }
}

/// A reusable phone-friendly summary card for Home and My Path.
///
/// This widget contains no roadmap logic. It renders a
/// [CareerReadinessSnapshot], keeping the roadmap engine as the single source
/// of truth.
class CareerReadinessCard extends StatelessWidget {
  final CareerReadinessSnapshot snapshot;
  final VoidCallback? onViewGaps;

  const CareerReadinessCard({
    super.key,
    required this.snapshot,
    this.onViewGaps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vm = CareerReadinessViewModel.fromSnapshot(snapshot);

    final statusColor = vm.isReady
        ? Colors.green.shade700
        : snapshot.majorGapCount <= 2
            ? cs.primary
            : Colors.orange.shade800;

    return Semantics(
      container: true,
      label: 'Career readiness. ${vm.percentLabel}. ${vm.gapLabel}.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CAREER READINESS',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    vm.statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              vm.percentLabel,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              vm.gapLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: vm.progressValue,
                minHeight: 9,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
            if (!vm.isReady && onViewGaps != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onViewGaps,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('VIEW GAPS'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
