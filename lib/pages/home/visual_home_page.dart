import 'package:flutter/material.dart';
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  _HeroBanner(onTap: () => context.go('/career')),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 98,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _GraphicLink(
                          imagePath: 'assets/graphics/career_vault.jpg',
                          label: 'Career Vault',
                          onTap: () => context.push('/career/vault'),
                        ),
                        const SizedBox(width: 10),
                        _GraphicLink(
                          imagePath: 'assets/graphics/advancement_dashboard.jpg',
                          label: 'Advancement',
                          onTap: () => context.go('/career'),
                        ),
                        const SizedBox(width: 10),
                        _GraphicLink(
                          imagePath: 'assets/graphics/promotion_story_bank.jpg',
                          label: 'Story Bank',
                          onTap: () => context.go('/career'),
                        ),
                      ],
                    ),
                  ),
                ],
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

class _HeroBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 148,
          width: double.infinity,
          child: Image.asset(
            'assets/graphics/professional_growth_roadmap_banner.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

class _GraphicLink extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _GraphicLink({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 104,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
