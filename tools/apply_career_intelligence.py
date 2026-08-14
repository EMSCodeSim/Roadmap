from pathlib import Path


def replace_once(path, old, new):
    p = Path(path)
    text = p.read_text()
    if old not in text:
        raise SystemExit(f'Expected pattern not found in {path}: {old[:100]!r}')
    p.write_text(text.replace(old, new, 1))


replace_once(
    'lib/nav.dart',
    "import 'package:firepath/pages/career/growth_overview_page.dart';\n",
    "import 'package:firepath/pages/career/growth_overview_page.dart';\nimport 'package:firepath/pages/career/career_intelligence_page.dart';\n",
)

replace_once(
    'lib/nav.dart',
    "      GoRoute(\n        path: AppRoutes.growthDetails,\n        name: 'growth_details',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: CareerHubPage()),\n      ),\n",
    "      GoRoute(\n        path: AppRoutes.growthDetails,\n        name: 'growth_details',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: CareerHubPage()),\n      ),\n      GoRoute(\n        path: AppRoutes.careerIntelligence,\n        name: 'career_intelligence',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: CareerIntelligencePage()),\n      ),\n",
)

replace_once(
    'lib/nav.dart',
    "  static const String growthDetails = '/growth-tools';\n",
    "  static const String growthDetails = '/growth-tools';\n  static const String careerIntelligence = '/career-intelligence';\n",
)

replace_once(
    'lib/pages/career/growth_overview_page.dart',
    "      appBar: AppBar(title: const Text('Growth')),\n",
    "      appBar: AppBar(title: const Text('Advance')),\n",
)

replace_once(
    'lib/pages/career/growth_overview_page.dart',
    "                  _GrowthToolsCard(\n                    onDetailedGrowth: () =>\n                        context.push(AppRoutes.growthDetails),\n                    onEvidence: () => context.push(AppRoutes.careerEvidence),\n                  ),\n",
    "                  _GrowthToolsCard(\n                    onIntelligence: () =>\n                        context.push(AppRoutes.careerIntelligence),\n                    onDetailedGrowth: () =>\n                        context.push(AppRoutes.growthDetails),\n                    onEvidence: () => context.push(AppRoutes.careerEvidence),\n                  ),\n",
)

replace_once(
    'lib/pages/career/growth_overview_page.dart',
    "class _GrowthToolsCard extends StatelessWidget {\n  final VoidCallback onDetailedGrowth;\n  final VoidCallback onEvidence;\n\n  const _GrowthToolsCard({\n    required this.onDetailedGrowth,\n    required this.onEvidence,\n  });\n",
    "class _GrowthToolsCard extends StatelessWidget {\n  final VoidCallback onIntelligence;\n  final VoidCallback onDetailedGrowth;\n  final VoidCallback onEvidence;\n\n  const _GrowthToolsCard({\n    required this.onIntelligence,\n    required this.onDetailedGrowth,\n    required this.onEvidence,\n  });\n",
)

replace_once(
    'lib/pages/career/growth_overview_page.dart',
    "          const SizedBox(height: AppSpacing.sm),\n          ListTile(\n            contentPadding: EdgeInsets.zero,\n            leading: const Icon(Icons.insights_outlined),\n",
    "          const SizedBox(height: AppSpacing.sm),\n          ListTile(\n            contentPadding: EdgeInsets.zero,\n            leading: const Icon(Icons.auto_graph_outlined),\n            title: const Text('Career Intelligence'),\n            subtitle: const Text(\n              'Annual review, promotion portfolio, career patterns, and highlights',\n            ),\n            trailing: const Icon(Icons.chevron_right),\n            onTap: onIntelligence,\n          ),\n          const Divider(height: 1),\n          ListTile(\n            contentPadding: EdgeInsets.zero,\n            leading: const Icon(Icons.insights_outlined),\n",
)

print('Career Intelligence integrated.')
