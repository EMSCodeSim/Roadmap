import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/certification_urgency.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roadmap = app.roadmap;
    final goal = roadmap?.goal;
    final next = roadmap?.nextStep?.requirement;
    final completed = roadmap?.completedCount ?? 0;
    final total = roadmap?.totalCount ?? 0;
    final progress = total <= 0 ? 0.0 : completed / total;
    final urgentCerts = CertificationUrgency.urgent(
      app.certifications,
      withinDays: 90,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _Header(
              onSettings: () => context.push(AppRoutes.settings),
            ),
            const SizedBox(height: 18),
            _TodayCard(
              goalTitle: goal?.title,
              nextTitle: next?.name,
              completed: completed,
              total: total,
              progress: progress,
              onStart: () => context.push(AppRoutes.dailyFocus),
              onChooseGoal: () => context.go(AppRoutes.myPath),
            ),
            const SizedBox(height: 12),
            _PrimaryActions(
              onQuickLog: () => QuickLogLauncher.open(context),
              onTaskBook: () => context.go(AppRoutes.myPath),
              onCerts: () => context.go(AppRoutes.certifications),
            ),
            if (urgentCerts.isNotEmpty) ...[
              const SizedBox(height: 14),
              _AttentionStrip(
                count: urgentCerts.length,
                onTap: () => context.go(AppRoutes.certifications),
              ),
            ],
            const SizedBox(height: 18),
            _ProgressSummary(
              completed: completed,
              total: total,
              nextTitle: next?.name,
              onAdvance: () => context.go(AppRoutes.growth),
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

class _TodayCard extends StatelessWidget {
  final String? goalTitle;
  final String? nextTitle;
  final int completed;
  final int total;
  final double progress;
  final VoidCallback onStart;
  final VoidCallback onChooseGoal;

  const _TodayCard({
    required this.goalTitle,
    required this.nextTitle,
    required this.completed,
    required this.total,
    required this.progress,
    required this.onStart,
    required this.onChooseGoal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasRoadmap = goalTitle != null && total > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'TODAY',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                    color: cs.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (hasRoadmap)
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasRoadmap) ...[
            Text(
              'Choose what you are working toward.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Build your Task Book first. Roadmap will then turn the next requirement into one clear focus for today.',
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
          ] else ...[
            Text(
              goalTitle!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              nextTitle ?? 'Continue your next requirement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your next meaningful step. Choose the time you have and Roadmap will build the session.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                backgroundColor: cs.surface.withValues(alpha: .55),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '$completed of $total requirements complete',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
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
        ],
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  final VoidCallback onQuickLog;
  final VoidCallback onTaskBook;
  final VoidCallback onCerts;

  const _PrimaryActions({
    required this.onQuickLog,
    required this.onTaskBook,
    required this.onCerts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_task_outlined,
            label: 'Quick Log',
            onTap: onQuickLog,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.route_outlined,
            label: 'Task Book',
            onTap: onTaskBook,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.verified_outlined,
            label: 'Certs',
            onTap: onCerts,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: .16)),
        ),
        child: Column(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionStrip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AttentionStrip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: cs.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count certification${count == 1 ? '' : 's'} need attention within 90 days',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final int completed;
  final int total;
  final String? nextTitle;
  final VoidCallback onAdvance;

  const _ProgressSummary({
    required this.completed,
    required this.total,
    required this.nextTitle,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.trending_up_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Career progress',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  total == 0
                      ? 'Set a goal to start building your career record.'
                      : '$completed of $total requirements complete${nextTitle == null ? '' : ' • Next: $nextTitle'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAdvance,
            child: const Text('Advance'),
          ),
        ],
      ),
    );
  }
}
