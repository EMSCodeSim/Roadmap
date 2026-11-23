import 'package:flutter/material.dart';

/// A small pulsing marker for content the user has not read yet.
/// Motion is disabled when the device requests reduced animation.
class UnreadPulseIndicator extends StatefulWidget {
  const UnreadPulseIndicator({
    super.key,
    this.icon = Icons.fiber_new_rounded,
    this.size = 18,
    this.color,
    this.semanticLabel = 'Unread update',
  });

  final IconData icon;
  final double size;
  final Color? color;
  final String semanticLabel;

  @override
  State<UnreadPulseIndicator> createState() => _UnreadPulseIndicatorState();
}

class _UnreadPulseIndicatorState extends State<UnreadPulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.error;
    final icon = Icon(widget.icon, size: widget.size, color: color);
    if (MediaQuery.of(context).disableAnimations) {
      return Semantics(label: widget.semanticLabel, child: icon);
    }
    return Semantics(
      label: widget.semanticLabel,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.48, end: 1).animate(_pulse),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.08).animate(_pulse),
          child: icon,
        ),
      ),
    );
  }
}
