import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/department/department_classes_page.dart';
import 'package:firepath/pages/department/department_training_home_page.dart';
import 'package:firepath/pages/department/department_review_page.dart';
import 'package:firepath/pages/department/my_department_page.dart';
import 'package:firepath/services/career_inbox.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/needs_attention_engine.dart';
import 'package:firepath/services/task_book_setup_store.dart';
import 'package:firepath/services/readiness_action_plan.dart';
import 'package:firepath/services/readiness_snapshot.dart';
import 'package:firepath/services/smart_next_step.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/career_inbox_preview.dart';
import 'package:firepath/widgets/career_readiness_panel.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';
import 'package:firepath/widgets/needs_attention_preview.dart';
import 'package:firepath/widgets/app_mode_switcher.dart';
import 'package:firepath/widgets/status_pill.dart';

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
            const AppModeSwitcher(),
            const SizedBox(height: 14),
            _TodayRail(
              hasRoadmap: hasRoadmap,
              goalTitle: goal?.title,
              nextTitle: smartNext?.focusTitle ?? next?.name,
              nextReason: smartNext?.reason,
              onDailyFocus: () => context.push(AppRoutes.dailyFocus),
              onQuickLog: () => context.go(AppRoutes.personalLog),
              onMyPath: () => context.go(AppRoutes.myPath),
            ),
            const SizedBox(height: 14),
            const _GettingStartedCard(),
            const SizedBox(height: 14),
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
                  AppRouter.openRequirement(context, item.requirement);
                },
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

class _TodayRail extends StatelessWidget {
  final bool hasRoadmap;
  final String? goalTitle;
  final String? nextTitle;
  final String? nextReason;
  final VoidCallback onDailyFocus;
  final VoidCallback onQuickLog;
  final VoidCallback onMyPath;

  const _TodayRail({
    required this.hasRoadmap,
    required this.goalTitle,
    required this.nextTitle,
    required this.nextReason,
    required this.onDailyFocus,
    required this.onQuickLog,
    required this.onMyPath,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final headline = hasRoadmap
        ? (nextTitle?.trim().isNotEmpty == true ? nextTitle!.trim() : 'Pick one win for today')
        : 'Set up your Task Book in a few taps';
    final sub = hasRoadmap
        ? (nextReason?.trim().isNotEmpty == true
            ? nextReason!.trim()
            : 'Do one small step — the plan updates automatically.')
        : 'Start with a goal, then log progress and follow next steps.';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) {
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.secondaryContainer.withValues(alpha: 0.55),
              cs.surfaceContainerHighest.withValues(alpha: 0.70),
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
                    color: cs.surface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
                  ),
                  child: Icon(Icons.today_rounded, color: cs.onSurface),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if ((goalTitle ?? '').trim().isNotEmpty)
                        Text(
                          goalTitle!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              headline,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.15),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 12),
            _TodayPrimaryActions(
              onDailyFocus: onDailyFocus,
              onQuickLog: onQuickLog,
              onMyPath: onMyPath,
            ),
            const SizedBox(height: 12),
            const _HomeStatusStrip(),
          ],
        ),
      ),
    );
  }
}

class _TodayPrimaryActions extends StatelessWidget {
  final VoidCallback onDailyFocus;
  final VoidCallback onQuickLog;
  final VoidCallback onMyPath;

  const _TodayPrimaryActions({
    required this.onDailyFocus,
    required this.onQuickLog,
    required this.onMyPath,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: onDailyFocus,
                  icon: Icon(Icons.track_changes, color: cs.onPrimary),
                  label: Text('Daily Focus', style: TextStyle(color: cs.onPrimary)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onQuickLog,
                  icon: Icon(Icons.note_alt_outlined, color: cs.primary),
                  label: Text('Quick Log', style: TextStyle(color: cs.primary)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onMyPath,
            icon: Icon(Icons.route_outlined, size: 18, color: cs.primary),
            label: Text('My Path', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _HomeStatusStrip extends StatefulWidget {
  const _HomeStatusStrip();

  @override
  State<_HomeStatusStrip> createState() => _HomeStatusStripState();
}

class _HomeStatusStripState extends State<_HomeStatusStrip> {
  final CareerRecordStore _store = CareerRecordStore();
  bool _loading = true;
  List<CareerRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final records = await _store.load();
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 26,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    final app = context.watch<AppState>();
    final inboxItems = CareerInbox.build(app: app, records: _records);
    final needsItems = NeedsAttentionEngine.analyze(app: app, records: _records);
    final needsNow = needsItems.where((e) => e.urgency == NeedsAttentionUrgency.now).length;

    // If nothing exists, keep the rail clean.
    if (inboxItems.isEmpty && needsItems.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (inboxItems.isNotEmpty)
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => context.push(AppRoutes.careerInbox),
            child: StatusPill(
              icon: Icons.inbox_outlined,
              text: 'Inbox ${inboxItems.length}',
              backgroundColor: cs.secondaryContainer.withValues(alpha: 0.55),
              foregroundColor: cs.onSecondaryContainer,
              maxWidth: 140,
            ),
          ),
        if (needsItems.isNotEmpty)
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => context.push(AppRoutes.needsAttention),
            child: StatusPill(
              icon: needsNow > 0 ? Icons.notifications_active_outlined : Icons.notifications_none_rounded,
              text: needsNow > 0 ? 'Now $needsNow' : 'Needs ${needsItems.length}',
              backgroundColor: cs.errorContainer.withValues(alpha: 0.38),
              foregroundColor: cs.error,
              maxWidth: 150,
            ),
          ),
      ],
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
            'Build your Task Book first. Responder Roadmap will then turn the next requirement into one clear focus for today.',
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
