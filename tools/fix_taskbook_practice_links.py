from pathlib import Path

path = Path('lib/pages/task_book/task_detail_page.dart')
text = path.read_text()

old = """                  onPressed: () => context.push(
                    AppRoutes.resources,
                    extra: {'tool': t.route, 'title': t.title},
                  ),
"""

new = """                  onPressed: () {
                    final String? externalUrl = switch (t.route) {
                      '/resources?tool=firepumpsim' =>
                        'https://fireopssim.com/fire-pump-training-scenarios.html',
                      '/resources?tool=fireops_calc' =>
                        'https://fireopssim.com/fire-pump-calculator.html',
                      '/resources?tool=hydrant_flow' =>
                        'https://fireopssim.com/hydrant-flow-calculator.html',
                      _ => null,
                    };
                    if (externalUrl != null) {
                      _openExternalUrl(externalUrl);
                      return;
                    }
                    context.push(
                      AppRoutes.resources,
                      extra: {'tool': t.route, 'title': t.title},
                    );
                  },
"""

if new in text:
    print('Task Book practice links already fixed.')
elif old in text:
    path.write_text(text.replace(old, new, 1))
    print('Mapped Task Book practice buttons to FireOpsSim tools.')
else:
    raise SystemExit('Expected Task Book practice button block not found; refusing partial patch.')
