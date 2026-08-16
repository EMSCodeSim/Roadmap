import 'package:flutter/material.dart';

/// Circular readiness / completion indicator.
class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final String? centerLabel;
  final Color? trackColor;
  final Color? progressColor;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 56,
    this.strokeWidth = 6,
    this.centerLabel,
    this.trackColor,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clamped,
              strokeWidth: strokeWidth,
              backgroundColor: trackColor ?? cs.surfaceContainerHighest,
              color: progressColor ?? cs.primary,
            ),
          ),
          if (centerLabel != null)
            Text(
              centerLabel!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
        ],
      ),
    );
  }
}
