from pathlib import Path

visual = Path('lib/pages/home/visual_home_page.dart')
visual.write_text("""import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:firepath/pages/home/home_page.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: _CareerHeader(
                onPath: () => context.go('/path'),
                onLog: () => context.go('/log'),
                onGrowth: () => context.go('/growth'),
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: const HomePage(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerHeader extends StatelessWidget {
  final VoidCallback onPath;
  final VoidCallback onLog;
  final VoidCallback onGrowth;

  const _CareerHeader({
    required this.onPath,
    required this.onLog,
    required this.onGrowth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/icons/career_road_icon.png',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.route, color: cs.onPrimaryContainer, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FireOps Career Road',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Plan the next move. Keep the proof.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _ActionChip(icon: Icons.route_outlined, label: 'Roadmap', onTap: onPath),
                    _ActionChip(icon: Icons.add_task_outlined, label: 'Log', onTap: onLog),
                    _ActionChip(icon: Icons.trending_up_outlined, label: 'Growth', onTap: onGrowth),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: cs.primary),
            const SizedBox(width: 5),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
""")

pubspec = Path('pubspec.yaml')
text = pubspec.read_text()
old_assets = """  assets:\n    - assets/icons/career_road_icon.jpg\n    - assets/images/firefighter_shield_badge_icon_minimal_flat_red_1786483176521.png\n    - assets/graphics/professional_growth_roadmap_banner.jpg\n    - assets/graphics/career_vault.jpg\n    - assets/graphics/advancement_dashboard.jpg\n    - assets/graphics/promotion_story_bank.jpg\n"""
new_assets = """  assets:\n    - assets/icons/career_road_icon.png\n"""
if old_assets not in text:
    raise SystemExit('Expected asset block not found')
text = text.replace(old_assets, new_assets)
old_icons = """flutter_launcher_icons:\n  android: true\n  ios: true\n  image_path: assets/images/firefighter_shield_badge_icon_minimal_flat_red_1786483176521.png\n  remove_alpha_ios: true\n"""
new_icons = """flutter_launcher_icons:\n  android: true\n  ios: true\n  image_path: assets/icons/career_road_icon.png\n  remove_alpha_ios: true\n  web:\n    generate: true\n    image_path: assets/icons/career_road_icon.png\n    background_color: \"#071A33\"\n    theme_color: \"#071A33\"\n"""
if old_icons not in text:
    raise SystemExit('Expected launcher icon block not found')
text = text.replace(old_icons, new_icons)
pubspec.write_text(text)

for path in [
    'assets/icons/career_road_icon.jpg',
    'assets/icons/dreamflow_icon.jpg',
    'assets/images/firefighter_shield_badge_icon_minimal_flat_red_1786483176521.png',
    'assets/graphics/professional_growth_roadmap_banner.jpg',
    'assets/graphics/career_vault.jpg',
    'assets/graphics/advancement_dashboard.jpg',
    'assets/graphics/promotion_story_bank.jpg',
]:
    Path(path).unlink(missing_ok=True)
