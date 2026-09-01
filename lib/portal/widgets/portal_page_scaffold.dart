import 'package:flutter/material.dart';

import 'package:firepath/services/theme.dart';

class PortalPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  const PortalPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 980;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCompact)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: IconButton(
                      tooltip: 'Menu',
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: Icon(Icons.menu, color: cs.onSurface),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
