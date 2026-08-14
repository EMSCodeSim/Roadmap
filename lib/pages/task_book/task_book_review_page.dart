import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/widgets/app_back_button.dart';
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
        appBar: AppBar(
          leading: const AppBackButton.toTaskBook(),
          title: const Text('Review Task Book'),
        ),
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
      appBar: AppBar(
        leading: const AppBackButton.toTaskBook(),
        title: const Text('Your Career Road'),
      ),
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
                    'Your Career Road is ready',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We built a starting path from your current role, location, certifications, and career goal. Start with the recommended next step and refine department-specific requirements whenever you are ready.',
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Icon(Icons.arrow_downward, size: 18),
                  ),
                  Text(
                    roadmap.goal.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
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
              title: 'Customize department requirements',
              description:
                  'Optional: add local certifications, experience minimums, drive hours, practicals, interviews, or department task books.',
              buttonLabel: 'Customize Later or Now',
              icon: Icons.fact_check_outlined,
              onTap: () => context.push(AppRoutes.taskBookRequirementsSetup),
            ),
            const SizedBox(height: 18),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'Start using your path now. You can customize Task Book requirements and Quick Log buttons later; FireOps Career Road should adapt to your department, not the other way around.',
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
              label: Text(_finishing ? 'Saving…' : 'Start My Career Road'),
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
    context.go(AppRoutes.home);
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
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
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
