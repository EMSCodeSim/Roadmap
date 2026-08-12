from pathlib import Path

path = Path('lib/pages/home/visual_home_page.dart')
text = path.read_text()

old_asset = 'assets/graphics/career_road_banner_v2.jpg'
new_asset = 'assets/graphics/career_road_bannejpg'

if new_asset in text:
    print('Home banner already points at the current uploaded asset.')
elif old_asset in text:
    path.write_text(text.replace(old_asset, new_asset, 1))
    print('Updated Home banner to the current uploaded asset path.')
else:
    raise SystemExit(
        'Expected Career Road banner asset reference not found; refusing a partial branding patch.'
    )
