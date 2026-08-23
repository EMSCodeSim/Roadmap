import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/readiness_action_plan.dart';
import 'package:firepath/services/readiness_snapshot.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/career_inbox_preview.dart';
import 'package:firepath/widgets/career_readiness_panel.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roadmap = app.roadmap;
    final goal = roadmap?.goal;
    final next = roadmap?.nextStep?.requirement;
    final hasRoadmap = roadmap != null && roadmap.totalCount > 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _Header(
              onSettings: () => context.push(AppRoutes.settings),
            ),
            const SizedBox(height: 18),
            if (!hasRoadmap)
              _ChooseGoalCard(
                onChooseGoal: () => context.go(AppRoutes.myPath),
              )
            else ...[
              CareerReadinessPanel(
                snapshot: CareerReadinessSnapshot.fromRoadmap(roadmap),
                actionPlan: CareerReadinessActionPlan.fromState(app),
                goalTitle: goal?.title ?? 'Career Road',
                onViewPath: () => context.go(AppRoutes.myPath),
                onActionTap: (item) {
                  context.push(
                    AppRoutes.requirementDetail,
                    extra: item.requirement,
                  );
                },
              ),
              const SizedBox(height: 14),
              _DailyFocusCta(
                nextTitle: next?.name,
                onStart: () => context.push(AppRoutes.dailyFocus),
              ),
            ],
            const SizedBox(height: 14),
            const CareerInboxPreview(),
            const SizedBox(height: 12),
            _SinglePrimaryAction(
              label: 'Quick Log',
              icon: Icons.add_task_outlined,
              onTap: () => QuickLogLauncher.open(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onSettings;

  const _Header({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: FirefighterRoadmapWordmark(),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _ChooseGoalCard extends StatelessWidget {
  final VoidCallback onChooseGoal;

  const _ChooseGoalCard({required this.onChooseGoal});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose what you are working toward.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Build your Task Book first. FireOps Career Road will then turn the next requirement into one clear focus for today.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: onChooseGoal,
              icon: const Icon(Icons.route_outlined),
              label: const Text('Build My Task Book'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyFocusCta extends StatelessWidget {
  final String? nextTitle;
  final VoidCallback onStart;

  const _DailyFocusCta({
    required this.nextTitle,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAILY FOCUS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                  color: cs.primary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            nextTitle ?? 'Continue your next requirement',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick 15 min, 30 min, 1 hour, or a crew drill. Learn → Practice → Record.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text("Start Today's Focus"),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinglePrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SinglePrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
