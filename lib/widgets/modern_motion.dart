import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firepath/services/theme.dart';

/// Subtle screen-entry animation (fade + slide up).
///
/// Use for top-level sections so the UI feels responsive without being flashy.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double dy;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.medium,
    this.dy = 10,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      _timer = Timer(widget.delay, () {
        if (!mounted) return;
        setState(() => _visible = true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant FadeSlideIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.key != widget.child.key && mounted) {
      // If a different subtree is swapped in, replay animation.
      setState(() => _visible = false);
      _timer?.cancel();
      _timer = Timer(widget.delay, () {
        if (!mounted) return;
        setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: widget.duration,
      curve: AppMotion.standard,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: widget.duration,
        curve: AppMotion.standard,
        offset: _visible ? Offset.zero : Offset(0, widget.dy / 100),
        child: widget.child,
      ),
    );
  }
}

/// No-splash press feedback with light haptics.
///
/// This avoids Ink splash/ripples while still giving users an obvious pressed
/// state and keeping touch targets large.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.lg)),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  Future<void> _handleTap() async {
    if (widget.onTap == null) return;
    await HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
        onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
        onTap: widget.onTap == null ? null : _handleTap,
        child: AnimatedScale(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          scale: _pressed ? 0.985 : 1,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
            ),
            child: ClipRRect(borderRadius: widget.borderRadius, child: widget.child),
          ),
        ),
      ),
    );
  }
}
