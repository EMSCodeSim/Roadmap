from pathlib import Path

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
