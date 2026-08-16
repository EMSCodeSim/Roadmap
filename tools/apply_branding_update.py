from pathlib import Path

path = Path('lib/pages/home/visual_home_page.dart')
text = path.read_text()

candidates = [
    'assets/graphics/career_road_banner.jpg',
    'assets/graphics/career_road_banner_v2.png',
    'assets/graphics/career_road_banner_v2.jpg',
    'assets/graphics/career_road_bannejpg',
]
preferred = 'assets/graphics/career_road_banner.jpg'

if preferred in text:
    print('Home banner already points at the current branded asset.')
else:
    replaced = False
    for old_asset in candidates[1:]:
        if old_asset in text:
            path.write_text(text.replace(old_asset, preferred, 1))
            print(f'Updated Home banner from {old_asset} to {preferred}.')
            replaced = True
            break
    if not replaced:
        raise SystemExit(
            'Expected Career Road banner asset reference not found; refusing a partial branding patch.'
        )
