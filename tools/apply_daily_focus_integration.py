from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    if new in text:
        print(f'{path}: already patched')
        return
    if old not in text:
        raise SystemExit(f'{path}: expected patch anchor not found')
    p.write_text(text.replace(old, new, 1))
    print(f'{path}: patched')


replace_once(
    'lib/nav.dart',
    "import 'package:firepath/pages/career/career_longevity_page.dart';\n",
    "import 'package:firepath/pages/career/career_longevity_page.dart';\nimport 'package:firepath/pages/career/daily_focus_page.dart';\n",
)

replace_once(
    'lib/nav.dart',
    "      GoRoute(\n        path: AppRoutes.careerLongevity,\n        name: 'career_longevity',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: CareerLongevityPage()),\n      ),\n",
    "      GoRoute(\n        path: AppRoutes.careerLongevity,\n        name: 'career_longevity',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: CareerLongevityPage()),\n      ),\n      GoRoute(\n        path: AppRoutes.dailyFocus,\n        name: 'daily_focus',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: DailyFocusPage()),\n      ),\n",
)

replace_once(
    'lib/nav.dart',
    "  static const String careerLongevity = '/career-intelligence/long-term';\n",
    "  static const String careerLongevity = '/career-intelligence/long-term';\n  static const String dailyFocus = '/daily-focus';\n",
)

replace_once(
    'lib/pages/home/visual_home_page.dart',
    "            const SizedBox(height: 12),\n            _CurrentLevelCard(\n",
    "            const SizedBox(height: 12),\n            const _DailyFocusCard(),\n            const SizedBox(height: 12),\n            _CurrentLevelCard(\n",
)

anchor = "class _CurrentLevelCard extends StatelessWidget {"
insert = r'''class _DailyFocusCard extends StatelessWidget {
  const _DailyFocusCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: () => context.push(AppRoutes.dailyFocus),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(Icons.bolt_outlined, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHAT CAN I WORK ON TODAY?',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick 15 min, 30 min, 1 hour, or a crew drill. Career Road builds the session around your Next Best Step.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

'''

p = Path('lib/pages/home/visual_home_page.dart')
text = p.read_text()
if insert in text:
    print('lib/pages/home/visual_home_page.dart: Daily Focus card already patched')
elif anchor not in text:
    raise SystemExit('lib/pages/home/visual_home_page.dart: card anchor not found')
else:
    p.write_text(text.replace(anchor, insert + anchor, 1))
    print('lib/pages/home/visual_home_page.dart: Daily Focus card patched')
