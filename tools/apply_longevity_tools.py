from pathlib import Path


def replace_once(path: Path, old: str, new: str):
    text = path.read_text()
    if old not in text:
        raise SystemExit(f'Expected text not found in {path}: {old[:100]!r}')
    path.write_text(text.replace(old, new, 1))

nav = Path('lib/nav.dart')
replace_once(
    nav,
    "import 'package:firepath/pages/career/career_intelligence_page.dart';\n",
    "import 'package:firepath/pages/career/career_intelligence_page.dart';\nimport 'package:firepath/pages/career/career_longevity_page.dart';\n",
)
replace_once(
    nav,
    "      GoRoute(\n        path: AppRoutes.careerEvidence,\n",
    "      GoRoute(\n        path: AppRoutes.careerLongevity,\n        name: 'career_longevity',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: CareerLongevityPage()),\n      ),\n      GoRoute(\n        path: AppRoutes.careerEvidence,\n",
)
replace_once(
    nav,
    "  static const String careerIntelligence = '/career-intelligence';\n",
    "  static const String careerIntelligence = '/career-intelligence';\n  static const String careerLongevity = '/career-intelligence/long-term';\n",
)

page = Path('lib/pages/career/career_intelligence_page.dart')
replace_once(
    page,
    "import 'package:flutter/services.dart';\nimport 'package:provider/provider.dart';\n",
    "import 'package:flutter/services.dart';\nimport 'package:go_router/go_router.dart';\nimport 'package:provider/provider.dart';\n",
)
replace_once(
    page,
    "import 'package:firepath/models/career_record.dart';\n",
    "import 'package:firepath/models/career_record.dart';\nimport 'package:firepath/nav.dart';\n",
)
needle = """                  _ToolCard(\n                    icon: Icons.workspace_premium_outlined,\n                    title: 'Promotion Portfolio',\n                    description: 'Build a promotion-ready snapshot from your credentials, evidence gaps, competencies, and strongest career stories.',\n                    onTap: () => _showText(\n                      title: 'Promotion Portfolio',\n                      text: CareerIntelligence.buildPromotionPortfolio(\n                        app: app,\n                        records: _records,\n                      ),\n                    ),\n                  ),\n"""
addition = needle + """                  const SizedBox(height: 10),\n                  _ToolCard(\n                    icon: Icons.timeline_outlined,\n                    title: 'Long-Term Career Tools',\n                    description: 'Compare future career paths, review past goals, catch stale skills, build STAR interview stories, and create resume source material.',\n                    onTap: () => context.push(AppRoutes.careerLongevity),\n                  ),\n"""
replace_once(page, needle, addition)

print('Long-term career tools integrated.')
