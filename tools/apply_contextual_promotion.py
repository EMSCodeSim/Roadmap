from pathlib import Path


def patch_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    if new in text:
        print(f'{path}: already patched')
        return
    if old not in text:
        raise SystemExit(f'{path}: expected anchor not found')
    p.write_text(text.replace(old, new, 1))
    print(f'{path}: patched')


patch_once(
    'lib/pages/home/visual_home_page.dart',
    "import 'package:firepath/services/catalog.dart';\n",
    "import 'package:firepath/services/catalog.dart';\nimport 'package:firepath/services/ecosystem_recommendations.dart';\nimport 'package:firepath/widgets/ecosystem_recommendation_card.dart';\n",
)

patch_once(
    'lib/pages/home/visual_home_page.dart',
    "    final nextExpiration = datedCerts\n        .where((cert) => !cert.expirationDate!.isBefore(_today()))\n        .firstOrNull;\n\n    return Scaffold(\n",
    "    final nextExpiration = datedCerts\n        .where((cert) => !cert.expirationDate!.isBefore(_today()))\n        .firstOrNull;\n    final ecosystemRecommendation = EcosystemRecommendations.forTopic(\n      roadmap?.nextStep?.requirement.name,\n    );\n\n    return Scaffold(\n",
)

patch_once(
    'lib/pages/home/visual_home_page.dart',
    "            const _DailyFocusCard(),\n            const SizedBox(height: 12),\n            _CurrentLevelCard(\n",
    "            const _DailyFocusCard(),\n            if (ecosystemRecommendation != null) ...[\n              const SizedBox(height: 12),\n              EcosystemRecommendationCard(\n                recommendation: ecosystemRecommendation,\n                compact: true,\n              ),\n            ],\n            const SizedBox(height: 12),\n            _CurrentLevelCard(\n",
)

patch_once(
    'lib/pages/career/daily_focus_page.dart',
    "import 'package:firepath/services/career_record_store.dart';\n",
    "import 'package:firepath/services/career_record_store.dart';\nimport 'package:firepath/services/ecosystem_recommendations.dart';\nimport 'package:firepath/widgets/ecosystem_recommendation_card.dart';\n",
)

patch_once(
    'lib/pages/career/daily_focus_page.dart',
    "    final recentHours = recent.fold<double>(\n      0,\n      (sum, record) => sum + (record.hours ?? 0),\n    );\n\n    return Scaffold(\n",
    "    final recentHours = recent.fold<double>(\n      0,\n      (sum, record) => sum + (record.hours ?? 0),\n    );\n    final ecosystemRecommendation = EcosystemRecommendations.forTopic(\n      [task?.title, next?.name].whereType<String>().join(' '),\n    );\n\n    return Scaffold(\n",
)

patch_once(
    'lib/pages/career/daily_focus_page.dart',
    "                  _FocusPlan(\n                    mode: _mode,\n                    goalId: goalId!,\n                    requirement: next,\n                    task: task,\n                    onOpenTask: task == null\n                        ? () => context.go(AppRoutes.myPath)\n                        : () => context.push(\n                            AppRoutes.taskDetail,\n                            extra: {\n                              'goalId': goalId,\n                              'requirementId': next.id,\n                              'qualificationName': next.name,\n                              'task': task,\n                            },\n                          ),\n                    onRecord: () => QuickLogLauncher.open(\n                      context,\n                      prefill: LogPrefill(\n                        title: task?.title ?? next.name,\n                        category: 'Daily Focus',\n                        relatedGoalId: goalId,\n                        relatedRequirementId: next.id,\n                        relatedTaskId: task?.id,\n                        tags: const ['daily-focus'],\n                      ),\n                    ),\n                  ),\n",
    "                  _FocusPlan(\n                    mode: _mode,\n                    goalId: goalId!,\n                    requirement: next,\n                    task: task,\n                    onOpenTask: task == null\n                        ? () => context.go(AppRoutes.myPath)\n                        : () => context.push(\n                            AppRoutes.taskDetail,\n                            extra: {\n                              'goalId': goalId,\n                              'requirementId': next.id,\n                              'qualificationName': next.name,\n                              'task': task,\n                            },\n                          ),\n                    onRecord: () => QuickLogLauncher.open(\n                      context,\n                      prefill: LogPrefill(\n                        title: task?.title ?? next.name,\n                        category: 'Daily Focus',\n                        relatedGoalId: goalId,\n                        relatedRequirementId: next.id,\n                        relatedTaskId: task?.id,\n                        tags: const ['daily-focus'],\n                      ),\n                    ),\n                  ),\n                if (ecosystemRecommendation != null) ...[\n                  const SizedBox(height: 12),\n                  EcosystemRecommendationCard(\n                    recommendation: ecosystemRecommendation,\n                    compact: true,\n                  ),\n                ],\n",
)
