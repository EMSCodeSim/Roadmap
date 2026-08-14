from pathlib import Path

TARGETS = {
    'lib/pages/career/personal_log_page.dart': 'toLog',
    'lib/pages/career/quick_log_setup_page.dart': 'toLog',
    'lib/pages/task_book/task_book_review_page.dart': 'toTaskBook',
    'lib/pages/task_book/task_book_requirements_editor_page.dart': 'toTaskBook',
    'lib/pages/path/goal_picker_page.dart': 'toTaskBook',
    'lib/pages/career/career_hub_page.dart': 'toAdvance',
    'lib/pages/career/career_intelligence_page.dart': 'toAdvance',
    'lib/pages/career/career_longevity_page.dart': 'toCareerIntelligence',
    'lib/pages/career/daily_focus_page.dart': 'toHome',
    'lib/pages/career/career_export_page.dart': 'toCareerIntelligence',
    'lib/pages/career/department_transfer_page.dart': 'toCareerIntelligence',
    'lib/pages/career/career_vault_page.dart': 'toAdvance',
    'lib/pages/task_book/qualification_task_book_page.dart': 'toTaskBook',
    'lib/pages/task_book/task_detail_page.dart': 'toTaskBook',
    'lib/pages/resources/resources_page.dart': 'toHome',
    'lib/pages/requirement/requirement_detail_page.dart': 'toTaskBook',
    'lib/pages/requirement/get_started_page.dart': 'toTaskBook',
    'lib/pages/certifications/certification_detail_page.dart': 'toCertifications',
    'lib/pages/certifications/certification_picker_page.dart': 'toCertifications',
}

IMPORT = "import 'package:firepath/widgets/app_back_button.dart';\n"

for file_name, destination in TARGETS.items():
    path = Path(file_name)
    if not path.exists():
        print(f'{file_name}: missing, skipped')
        continue

    text = path.read_text()
    changed = False

    if 'appBar: AppBar(' not in text:
        print(f'{file_name}: no AppBar found, skipped')
        continue

    if IMPORT not in text:
        marker = "import 'package:firepath/"
        idx = text.find(marker)
        if idx >= 0:
            text = text[:idx] + IMPORT + text[idx:]
        else:
            last_import = text.rfind("import '")
            end = text.find('\n', last_import)
            text = text[:end + 1] + IMPORT + text[end + 1:]
        changed = True

    replacement = (
        'appBar: AppBar(\n'
        f'        leading: const AppBackButton.{destination}(),\n'
    )
    if f'leading: const AppBackButton.{destination}(),' not in text:
        text = text.replace('appBar: AppBar(', replacement)
        changed = True

    if changed:
        path.write_text(text)
        print(f'{file_name}: patched')
    else:
        print(f'{file_name}: already patched')
