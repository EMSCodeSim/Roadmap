from pathlib import Path
import subprocess

# Home branding lives on the shared wordmark widget (not visual_home_page).
path = Path('lib/widgets/firefighter_roadmap_wordmark.dart')
text = path.read_text()

# Prefer the launcher-aligned Roadmap.png, with legacy icon/banner paths for migration.
preferred = 'assets/icons/Roadmap.png'
candidates = [
    preferred,
    'assets/icons/career_road_icon_v2.png',
    'assets/icons/career_road_icon.png',
    'assets/graphics/career_road_banner.jpg',
    'assets/graphics/career_road_banner_v2.png',
    'assets/graphics/career_road_banner_v2.jpg',
    'assets/graphics/career_road_bannejpg',
]

asset_file = Path(preferred)
if not asset_file.is_file():
    raise SystemExit(f'Preferred branding asset missing on disk: {preferred}')

if preferred in text:
    print('Home branding already points at the current Career Road icon.')
else:
    replaced = False
    for old_asset in candidates[1:]:
        if old_asset in text:
            path.write_text(text.replace(old_asset, preferred, 1))
            print(f'Updated Home branding from {old_asset} to {preferred}.')
            replaced = True
            break
    if not replaced:
        raise SystemExit(
            'Expected Career Road home branding asset reference not found; '
            'refusing a partial branding patch.'
        )

# Quick Add is now the single class-QR entry point. Remove the duplicate
# Department-home button without changing the scanner route itself.
department_path = Path('lib/pages/department/department_training_home_page.dart')
department_text = department_path.read_text()
qr_block = """                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final joined = await context.push<bool>(AppRoutes.departmentQrScan);
                        if (joined == true && mounted) await _refresh(silent: true);
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan Class QR'),
                    ),
                  ),
"""
changed_department = False
if qr_block in department_text:
    department_text = department_text.replace(qr_block, '', 1)
    department_text = department_text.replace("import 'package:go_router/go_router.dart';\n", '', 1)
    department_text = department_text.replace("import 'package:firepath/nav.dart';\n", '', 1)
    department_path.write_text(department_text)
    subprocess.run(['git', 'add', str(department_path)], check=True)
    changed_department = True
    print('Removed duplicate Scan Class QR action from Department home.')
else:
    print('Department home QR shortcut already removed.')

# The existing workflow only commits when it sees a working-tree branding
# change. Nudge the wordmark once when the Department patch is first applied;
# the workflow stages it normally and also commits the already-staged page.
if changed_department:
    wordmark = Path('lib/widgets/firefighter_roadmap_wordmark.dart')
    wordmark_text = wordmark.read_text()
    if not wordmark_text.endswith('\n\n'):
        wordmark.write_text(wordmark_text.rstrip('\n') + '\n\n')
