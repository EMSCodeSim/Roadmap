import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/services/task_book_setup_store.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class TaskBookReviewPage extends StatefulWidget {
  const TaskBookReviewPage({super.key});

  @override
  State<TaskBookReviewPage> createState() => _TaskBookReviewPageState();
}

class _TaskBookReviewPageState extends State<TaskBookReviewPage> {
  final TaskBookSetupStore _setupStore = TaskBookSetupStore();
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _setupStore.setReviewPending(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    final cs = Theme.of(context).colorScheme;

    if (roadmap == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Task Book')),
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Choose a career goal before building a Task Book.'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () => context.go(AppRoutes.goalSetup),
                    child: const Text('Choose Career Goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final included = roadmap.included.length;
    final excluded = roadmap.all.length - included;
    final currentRole = state.profile.currentRoles.isEmpty
        ? 'Current role not set'
        : state.profile.currentRoles.join(' / ');
    final stateName = FireOpsCatalog.stateNameForCode(state.profile.state);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Your Task Book')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Task Book is ready to review',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Before you start using it, make it match your department. Remove requirements that do not apply and add local requirements, hours, practicals, or department task books.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      currentRole,
                      if (stateName != null && stateName.isNotEmpty) stateName,
                    ].join(' • '),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Icon(Icons.arrow_downward, size: 18),
                  ),
                  Text(
                    roadmap.goal.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Metric(label: 'Included', value: '$included'),
                      _Metric(label: 'Removed', value: '$excluded'),
                      _Metric(
                        label: 'Ready',
                        value: '${(roadmap.percentComplete * 100).round()}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SetupCard(
              number: '1',
              title: 'Review requirements',
              description:
                  'Turn off anything your department does not require. Add local certifications, experience minimums, drive hours, practicals, interviews, or department task books.',
              buttonLabel: 'Customize Task Book',
              icon: Icons.fact_check_outlined,
              onTap: () => context.push(AppRoutes.taskBookRequirementsSetup),
            ),
            const SizedBox(height: 12),
            _SetupCard(
              number: '2',
              title: 'Set up Quick Log',
              description:
                  'Choose the buttons you want at the top of Quick Log. Pinned buttons prefill common activity details so routine logging stays fast.',
              buttonLabel: 'Set Up Quick Log',
              icon: Icons.add_task_outlined,
              onTap: () => context.push(AppRoutes.quickLogSetup),
            ),
            const SizedBox(height: 18),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'You can change Task Book requirements and Quick Log buttons later. Fire Career Roadmap should match your department—not force your department to match the app.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: _finishing ? null : _useTaskBook,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_finishing ? 'Saving…' : 'Use This Task Book'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _useTaskBook() async {
    setState(() => _finishing = true);
    await _setupStore.setReviewPending(false);
    if (!mounted) return;
    context.go(AppRoutes.myPath);
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onTap;

  const _SetupCard({
    required this.number,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  number,
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.chevron_right),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
