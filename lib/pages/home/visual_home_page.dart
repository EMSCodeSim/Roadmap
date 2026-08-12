import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/pages/home/home_page.dart';
import 'package:firepath/theme.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _CareerGraphicsHeader(),
            Expanded(child: HomePage(embedded: true, showTopHeader: false)),
          ],
        ),
      ),
    );
  }
}

class _CareerGraphicsHeader extends StatelessWidget {
  const _CareerGraphicsHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [FireOpsSemanticColors.headerDark, cs.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Image.asset(
                    'assets/icons/career_road_icon.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FireOps Career Road',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.onSecondary, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your Fire Service Career Roadmap',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSecondary.withValues(alpha: 0.9), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: const [
                _HeaderNavChip(label: 'Roadmap', icon: Icons.route, route: AppRoutes.myPath),
                _HeaderNavChip(label: 'Log', icon: Icons.edit_note, route: AppRoutes.personalLog),
                _HeaderNavChip(label: 'Growth', icon: Icons.trending_up, route: AppRoutes.growth),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderNavChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _HeaderNavChip({required this.label, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => context.go(route),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: cs.onSecondary),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSecondary, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
