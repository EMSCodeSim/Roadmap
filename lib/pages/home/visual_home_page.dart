import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_path.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/department/department_training_home_page.dart';
import 'package:firepath/pages/department/department_classes_page.dart';
import 'package:firepath/pages/department/department_review_page.dart';
import 'package:firepath/services/task_book_setup_store.dart';
import 'package:firepath/services/readiness_action_plan.dart';
import 'package:firepath/services/readiness_snapshot.dart';
import 'package:firepath/services/smart_next_step.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/career_inbox_preview.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';
import 'package:firepath/widgets/needs_attention_preview.dart';
import 'package:firepath/widgets/app_mode_switcher.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppModeController>();
    if (mode.isDepartment) {
      if (mode.isInstructor) return const DepartmentClassesPage();
      if (mode.isEvaluator) return const DepartmentReviewPage();
      return const DepartmentTrainingHomePage();
    }

    final app = context.watch<AppState>();
    final profile = app.profile;
    final path = profile.effectiveCareerPath;
    final roadmap = app.roadmap;
    final goal = roadmap?.goal;
    final smartNext = SmartNextStepEngine.resolve(app);
    final next = smartNext?.requirement;
    final hasRoadmap = roadmap != null && roadmap.totalCount > 0;
    final currentPosition = profile.currentRoles.isEmpty
        ? 'Not set'
        : profile.currentRoles.first;
    final trackLabel = path == CareerPath.both
        ? CareerPathCopy.trackLabelForGoalCategory(goal?.category)
        : '';
    final snapshot =
        hasRoadmap ? CareerReadinessSnapshot.fromRoadmap(roadmap) : null;
    final actionPlan =
        hasRoadmap ? CareerReadinessActionPlan.fromState(app) : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _Header(
              path: path,
              onSettings: () => context.push(AppRoutes.settings),
            ),
            const SizedBox(height: 8),
            Text(
              CareerPathCopy.homeProductLine(path),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 10),
            const AppModeSwitcher(),
            if (profile.needsCareerPathConfirmation) ...[
              const SizedBox(height: 14),
              const _CareerPathConfirmBanner(),
            ],
            const SizedBox(height: 14),
            const _GettingStartedCard(),
            const SizedBox(height: 14),
            if (!hasRoadmap)
              _ChooseGoalCard(
                path: path,
                onChooseGoal: () => context.go(AppRoutes.myPath),
              )
            else ...[
              _MyRoadmapCard(
                currentPosition: currentPosition,
                goalTitle: goal?.title ?? 'Career Goal',
                trackLabel: trackLabel,
                nextTitle: smartNext?.focusTitle ?? next?.name,
                nextReason: smartNext?.reason,
                progressLabel: snapshot == null
                    ? null
                    : '${snapshot.completedCount}/${snapshot.totalCount} complete',
                onOpenNext: () {
                  if (next != null) {
                    AppRouter.openRequirement(context, next);
                  } else {
                    context.push(AppRoutes.dailyFocus);
                  }
                },
                onStartFocus: () => context.push(AppRoutes.dailyFocus),
                onViewPath: () => context.go(AppRoutes.myPath),
              ),
              const SizedBox(height: 14),
              _SecondaryLinks(
                progressPercent: snapshot?.percentComplete,
                topActionTitle: actionPlan?.items.isNotEmpty == true
                    ? actionPlan!.items.first.requirement.name
                    : null,
                onProgress: () => context.go(AppRoutes.myPath),
                onCerts: () => context.go(AppRoutes.certifications),
                onActivity: () => context.go(AppRoutes.personalLog),
              ),
            ],
            const SizedBox(height: 14),
            const _HomeUpdatesSection(),
          ],
        ),
      ),
    );
  }
}

class _GettingStartedCard extends StatefulWidget {
  const _GettingStartedCard();

  @override
  State<_GettingStartedCard> createState() => _GettingStartedCardState();
}

class _GettingStartedCardState extends State<_GettingStartedCard> {
  final TaskBookSetupStore _store = TaskBookSetupStore();
  bool _loading = true;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pending = await _store.isGettingStartedPending();
      if (!mounted) return;
      setState(() {
        _show = pending;
        _loading = false;
      });
    } catch (e) {
      // Never block home if prefs fail.
      if (!mounted) return;
      setState(() {
        _show = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_show) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer.withValues(alpha: 0.85),
              cs.surfaceContainerHighest.withValues(alpha: 0.55),
            ],
          ),
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
                  ),
                  child: Icon(Icons.flag_outlined, color: cs.onSurface),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Start here (2 minutes)',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  onPressed: () async {
                    await _store.setGettingStartedPending(false);
                    if (!mounted) return;
                    setState(() => _show = false);
                  },
                  icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This app builds your Task Book + “what’s next” focus. The fastest way to feel it: do one small log, then follow the next suggestion.',
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StartChip(
                  icon: Icons.track_changes,
                  label: 'Daily Focus',
                  onTap: () => context.push(AppRoutes.dailyFocus),
                ),
                _StartChip(
                  icon: Icons.playlist_add_check_circle_outlined,
                  label: 'My Task Book',
                  onTap: () => context.go(AppRoutes.myPath),
                ),
                _StartChip(
                  icon: Icons.note_alt_outlined,
                  label: 'Quick Log',
                  onTap: () => context.go(AppRoutes.personalLog),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StartChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StartChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeUpdatesSection extends StatefulWidget {
  const _HomeUpdatesSection();

  @override
  State<_HomeUpdatesSection> createState() => _HomeUpdatesSectionState();
}

class _HomeUpdatesSectionState extends State<_HomeUpdatesSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UpdatesHeader(
              expanded: _expanded,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    NeedsAttentionPreview(),
                    SizedBox(height: 12),
                    CareerInboxPreview(),
                  ],
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    CareerInboxPreview(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpdatesHeader extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _UpdatesHeader({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: expanded ? 'Collapse updates' : 'Expand updates',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(
            children: [
              Icon(Icons.notifications_none_rounded, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Updates',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expanded ? 'Tap to hide' : 'Tap to view details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Icon(Icons.keyboard_arrow_down_rounded, color: cs.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CareerPath path;
  final VoidCallback onSettings;

  const _Header({required this.path, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: FirefighterRoadmapWordmark(),
        ),
        if (path != CareerPath.fire)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _TrackChip(label: path.shortLabel),
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

class _TrackChip extends StatelessWidget {
  final String label;
  const _TrackChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _CareerPathConfirmBanner extends StatelessWidget {
  const _CareerPathConfirmBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppState>();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Roadmap is currently set to Fire.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep Fire, add EMS, or switch to EMS. Your logs, certifications, and progress stay intact.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => app.setCareerPath(careerPath: CareerPath.fire),
                child: const Text('Keep Fire'),
              ),
              OutlinedButton(
                onPressed: () => app.setCareerPath(
                  careerPath: CareerPath.both,
                  primaryTrack: CareerPath.fire,
                ),
                child: const Text('Add EMS'),
              ),
              TextButton(
                onPressed: () => app.setCareerPath(careerPath: CareerPath.ems),
                child: const Text('Switch to EMS'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChooseGoalCard extends StatelessWidget {
  final CareerPath path;
  final VoidCallback onChooseGoal;

  const _ChooseGoalCard({required this.path, required this.onChooseGoal});

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
            'Choose where you want to go.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            path == CareerPath.ems
                ? 'Pick an EMS career goal. Responder Roadmap will build your personal Task Book and show what to work on next.'
                : path == CareerPath.both
                    ? 'Pick a Fire or EMS goal. You can manage both sides of your career in one personal roadmap.'
                    : 'Pick a career goal. Responder Roadmap will build your personal Task Book and show what to work on next.',
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
              label: const Text('Build My Roadmap'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRoadmapCard extends StatelessWidget {
  final String currentPosition;
  final String goalTitle;
  final String trackLabel;
  final String? nextTitle;
  final String? nextReason;
  final String? progressLabel;
  final VoidCallback onOpenNext;
  final VoidCallback onStartFocus;
  final VoidCallback onViewPath;

  const _MyRoadmapCard({
    required this.currentPosition,
    required this.goalTitle,
    required this.trackLabel,
    required this.nextTitle,
    required this.nextReason,
    required this.progressLabel,
    required this.onOpenNext,
    required this.onStartFocus,
    required this.onViewPath,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
              Expanded(
                child: Text(
                  'MY ROADMAP',
                  style: t.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: cs.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewPath,
                child: const Text('Task Book'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MetaRow(label: 'Current position', value: currentPosition),
          const SizedBox(height: 6),
          _MetaRow(
            label: 'Goal',
            value: goalTitle,
            badge: trackLabel.isEmpty ? null : trackLabel,
          ),
          if (progressLabel != null) ...[
            const SizedBox(height: 6),
            _MetaRow(label: 'My Progress', value: progressLabel!),
          ],
          const SizedBox(height: 16),
          Text(
            'NEXT STEP',
            style: t.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nextTitle ?? 'Continue your Task Book',
            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (trackLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: _TrackChip(label: trackLabel),
            ),
          ],
          if ((nextReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              nextReason!,
              style: t.bodySmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: onOpenNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Do next step'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onStartFocus,
              icon: const Icon(Icons.bolt_rounded),
              label: const Text("Start today's focus"),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;

  const _MetaRow({required this.label, required this.value, this.badge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if ((badge ?? '').isNotEmpty) ...[
          const SizedBox(width: 8),
          _TrackChip(label: badge!),
        ],
      ],
    );
  }
}

class _SecondaryLinks extends StatelessWidget {
  final double? progressPercent;
  final String? topActionTitle;
  final VoidCallback onProgress;
  final VoidCallback onCerts;
  final VoidCallback onActivity;

  const _SecondaryLinks({
    required this.progressPercent,
    required this.topActionTitle,
    required this.onProgress,
    required this.onCerts,
    required this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    final percent = progressPercent;
    final progressSubtitle = percent == null
        ? 'Open your Task Book'
        : '${percent.round()}% of mapped requirements';

    return Column(
      children: [
        _LinkTile(
          icon: Icons.playlist_add_check_circle_outlined,
          title: 'My Progress',
          subtitle: topActionTitle == null
              ? progressSubtitle
              : 'Next up: $topActionTitle',
          onTap: onProgress,
        ),
        const SizedBox(height: 8),
        _LinkTile(
          icon: Icons.verified_outlined,
          title: 'Certifications',
          subtitle: 'Credentials and renewals',
          onTap: onCerts,
        ),
        const SizedBox(height: 8),
        _LinkTile(
          icon: Icons.history_edu_outlined,
          title: 'Recent Activity',
          subtitle: 'Personal logs and Quick Log history',
          onTap: onActivity,
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
