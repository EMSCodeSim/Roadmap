from pathlib import Path


def replace(path, old, new, label):
    p = Path(path)
    text = p.read_text()
    if old not in text:
        raise SystemExit(f'Missing anchor for {label}: {path}')
    p.write_text(text.replace(old, new, 1))
    print(f'Updated {label}')

# 1) Onboarding wording: keep product name consistent.
p='lib/pages/onboarding/onboarding_v2_page.dart'
text=Path(p).read_text()
text=text.replace('This gives Fire Career Roadmap the right starting point.', 'This gives FireOps Career Road the right starting point.')
text=text.replace('The app will build a Task Book, then let you review and customize it before you use it.', 'FireOps Career Road will build your starting Task Book. You can customize department-specific requirements later.')
Path(p).write_text(text)

# 2) Turn post-onboarding review into a rewarding reveal and make customization optional.
p='lib/pages/task_book/task_book_review_page.dart'
text=Path(p).read_text()
text=text.replace("appBar: AppBar(title: const Text('Review Your Task Book'))", "appBar: AppBar(title: const Text('Your Career Road'))")
text=text.replace("'Your Task Book is ready to review'", "'Your Career Road is ready'")
text=text.replace("'Before you start using it, make it match your department. Remove requirements that do not apply and add local requirements, hours, practicals, or department task books.'", "'We built a starting path from your current role, location, certifications, and career goal. Start with the recommended next step and refine department-specific requirements whenever you are ready.'")
text=text.replace("title: 'Review requirements',", "title: 'Customize department requirements',")
text=text.replace("description:\n                  'Turn off anything your department does not require. Add local certifications, experience minimums, drive hours, practicals, interviews, or department task books.',", "description:\n                  'Optional: add local certifications, experience minimums, drive hours, practicals, interviews, or department task books.',")
text=text.replace("buttonLabel: 'Customize Task Book',", "buttonLabel: 'Customize Later or Now',")
# Remove forced quick-log setup card from first run.
start="""            const SizedBox(height: 12),
            _SetupCard(
              number: '2',
              title: 'Set up Quick Log',
              description:
                  'Choose the buttons you want at the top of Quick Log. Pinned buttons prefill common activity details so routine logging stays fast.',
              buttonLabel: 'Set Up Quick Log',
              icon: Icons.add_task_outlined,
              onTap: () => context.push(AppRoutes.quickLogSetup),
            ),
"""
text=text.replace(start, '')
text=text.replace("'You can change Task Book requirements and Quick Log buttons later. Fire Career Roadmap should match your department—not force your department to match the app.'", "'Start using your path now. You can customize Task Book requirements and Quick Log buttons later; FireOps Career Road should adapt to your department, not the other way around.'")
text=text.replace("label: Text(_finishing ? 'Saving…' : 'Use This Task Book'),", "label: Text(_finishing ? 'Saving…' : 'Start My Career Road'),")
# Send first-run user to Home so the new Career Readiness card teaches the loop.
text=text.replace("context.go(AppRoutes.myPath);", "context.go(AppRoutes.home);", 1)
Path(p).write_text(text)

# 3) Preserve authored task sequence instead of alphabetizing inside sections.
p='lib/pages/task_book/qualification_task_book_page.dart'
text=Path(p).read_text()
text=text.replace("final items = grouped[section]!..sort((a, b) => a.title.compareTo(b.title));", "final items = grouped[section]!;")
# Add hierarchy language to the progress card.
text=text.replace("Text('${(pct * 100).round()}% Complete',", "Text('PREPARATION TASKS  •  ${(pct * 100).round()}% Complete',")
Path(p).write_text(text)

# 4) Use one recommendation term everywhere.
p='lib/pages/task_book/task_book_page.dart'
text=Path(p).read_text().replace("Text('NEXT TASK',", "Text('NEXT BEST STEP',")
Path(p).write_text(text)

p='lib/pages/career/growth_overview_page.dart'
text=Path(p).read_text().replace("'BEST NEXT MOVE'", "'NEXT BEST STEP'")
Path(p).write_text(text)

# 5) Clarify task status is personal preparation, and standardize Learn → Practice → Record wording.
p='lib/pages/task_book/task_detail_page.dart'
text=Path(p).read_text()
text=text.replace("TaskBookTaskStatus.complete => 'Complete',", "TaskBookTaskStatus.complete => 'Self-completed',")
text=text.replace("label: const Text('Study this task'),", "label: const Text('Learn'),")
text=text.replace("label: const Text('Practice / tools'),", "label: const Text('Practice'),")
text=text.replace("title: 'MY RECORD'", "title: 'RECORD'")
text=text.replace("child: const Text('Log Practice')", "child: const Text('Record Practice')")
Path(p).write_text(text)

# 6) Make Growth navigation purpose explicit.
p='lib/pages/shell/app_shell_page.dart'
text=Path(p).read_text().replace("label: 'Growth',", "label: 'Advance',")
Path(p).write_text(text)

print('Applied first-run UX and career-loop upgrade.')
