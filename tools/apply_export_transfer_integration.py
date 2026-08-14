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
    "import 'package:firepath/pages/career/career_longevity_page.dart';\nimport 'package:firepath/pages/career/career_export_page.dart';\nimport 'package:firepath/pages/career/department_transfer_page.dart';\n",
)

replace_once(
    'lib/nav.dart',
    "      GoRoute(\n        path: AppRoutes.careerLongevity,\n        name: 'career_longevity',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: CareerLongevityPage()),\n      ),\n",
    "      GoRoute(\n        path: AppRoutes.careerLongevity,\n        name: 'career_longevity',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: CareerLongevityPage()),\n      ),\n      GoRoute(\n        path: AppRoutes.careerExport,\n        name: 'career_export',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: CareerExportPage()),\n      ),\n      GoRoute(\n        path: AppRoutes.departmentTransfer,\n        name: 'department_transfer',\n        pageBuilder: (context, state) =>\n            const MaterialPage(child: DepartmentTransferPage()),\n      ),\n",
)

replace_once(
    'lib/nav.dart',
    "  static const String careerLongevity = '/career-intelligence/long-term';\n",
    "  static const String careerLongevity = '/career-intelligence/long-term';\n  static const String careerExport = '/career-intelligence/export';\n  static const String departmentTransfer = '/career-intelligence/department-transfer';\n",
)

anchor = """                  _ToolCard(
                    icon: Icons.timeline_outlined,
                    title: 'Long-Term Career Tools',
                    description: 'Compare future career paths, review past goals, catch stale skills, build STAR interview stories, and create resume source material.',
                    onTap: () => context.push(AppRoutes.careerLongevity),
                  ),
                  const SizedBox(height: 22),
"""
replacement = """                  _ToolCard(
                    icon: Icons.timeline_outlined,
                    title: 'Long-Term Career Tools',
                    description: 'Compare future career paths, review past goals, catch stale skills, build STAR interview stories, and create resume source material.',
                    onTap: () => context.push(AppRoutes.careerLongevity),
                  ),
                  const SizedBox(height: 10),
                  _ToolCard(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Career Export Center',
                    description: 'Create polished resume, promotion packet, and full career portfolio PDFs from your saved career record.',
                    onTap: () => context.push(AppRoutes.careerExport),
                  ),
                  const SizedBox(height: 10),
                  _ToolCard(
                    icon: Icons.compare_arrows_outlined,
                    title: 'Department Transfer',
                    description: 'Compare another department’s requirements against your existing credentials, Task Book history, and career evidence without changing your active path.',
                    onTap: () => context.push(AppRoutes.departmentTransfer),
                  ),
                  const SizedBox(height: 22),
"""
replace_once('lib/pages/career/career_intelligence_page.dart', anchor, replacement)
