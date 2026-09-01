import 'package:flutter/material.dart';

import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';

/// A compact, consistent primary header for top-level screens.
///
/// - Always displays the full brand title: "Responder Roadmap" (scale-down, no truncation)
/// - Uses a device-safe raster icon with iOS-friendly fallbacks
/// - Supports an optional subtitle for the current tab/context
class FirefighterRoadmapAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const FirefighterRoadmapAppBar({
    super.key,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final titleWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FirefighterRoadmapWordmark(
          iconSize: 18,
          gap: 8,
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.1,
            height: 1.0,
          ),
        ),
        if ((subtitle ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          // Subtitle is often context (e.g., active Task Book name). Prefer
          // scale-down over truncation so custom department names stay visible.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle!.trim(),
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        ],
      ],
    );

    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: false,
      titleSpacing: 16,
      title: titleWidget,
      actions: actions,
    );
  }
}
