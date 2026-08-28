import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/readiness_action_plan.dart';
import 'package:firepath/services/readiness_snapshot.dart';
import 'package:firepath/services/smart_next_step.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/career_inbox_preview.dart';
import 'package:firepath/widgets/career_readiness_panel.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';
import 'package:firepath/widgets/needs_attention_preview.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roadmap = app.roadmap;
    final goal = roadmap?.goal;
    final smartNext = SmartNextStepEngine.resolve(app);
    final next = smartNext?.requirement;
    final hasRoadmap = roadmap != null && roadmap.totalCount > 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _Header(
              onSettings: () => context.push(AppRoutes.settings),
            ),
            const SizedBox(height: 10),
            _QuickAccessRow(
              onQuickLog: () => QuickLogLauncher.open(context),
              onDepartment: () => context.push(AppRoutes.department),
            ),
            const SizedBox(height: 14),
            if (!hasRoadmap)
              _ChooseGoalCard(
                onChooseGoal: () => context.go(AppRoutes.myPath),
              )
            else ...[
              _DailyFocusCta(
                goalTitle: goal?.title,
                nextTitle: smartNext?.focusTitle ?? next?.name,
                nextReason: smartNext?.reason,
                onStart: () => context.push(AppRoutes.dailyFocus),
              ),
              const SizedBox(height: 14),
              CareerReadinessPanel(
                snapshot: CareerReadinessSnapshot.fromRoadmap(roadmap),
                actionPlan: CareerReadinessActionPlan.fromState(app),
                goalTitle: goal?.title ?? 'Career Road',
                onViewPath: () => context.go(AppRoutes.myPath),
                onActionTap: (item) {
                  AppRouter.openRequirement(context, item.requirement);
                },
              ),
            ],
            const SizedBox(height: 14),
            const NeedsAttentionPreview(),
            const SizedBox(height: 14),
            const CareerInboxPreview(),
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

class _QuickAccessRow extends StatelessWidget {
  final VoidCallback onQuickLog;
  final VoidCallback onDepartment;

  const _QuickAccessRow({
    required this.onQuickLog,
    required this.onDepartment,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('home_quick_access_row'),
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: onQuickLog,
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Quick Log'),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: FilledButton.tonalIcon(
              onPressed: onDepartment,
              icon: const Icon(Icons.apartment_rounded),
              label: const Text('Department'),
            ),
          ),
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
  final String? goalTitle;
  final String? nextTitle;
  final String? nextReason;
  final VoidCallback onStart;

  const _DailyFocusCta({
    required this.goalTitle,
    required this.nextTitle,
    required this.nextReason,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.primary.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'TODAY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: .9,
                      color: cs.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            nextTitle ?? 'Continue your next requirement',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (goalTitle != null && goalTitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Moving you toward $goalTitle',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          if (nextReason != null && nextReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              nextReason!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
          const SizedBox(height: 9),
          Text(
            'Choose 15 min, 30 min, 1 hour, or a crew drill. Career Road will turn this requirement into a focused Learn → Practice → Record session.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
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