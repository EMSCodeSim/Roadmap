import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_inbox.dart';
import 'package:firepath/services/advancement_analyzer.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/needs_attention_engine.dart';
import 'package:firepath/services/smart_next_step.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/career_inbox_preview.dart';
import 'package:firepath/widgets/career_pulse_card.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';
import 'package:firepath/widgets/needs_attention_preview.dart';
import 'package:firepath/widgets/status_pill.dart';

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
            _CredentialAttentionCard(app: app),
            const SizedBox(height: 14),
            if (!hasRoadmap)
              _ChooseGoalCard(
                onChooseGoal: () => context.go(AppRoutes.myPath),
              )
            else ...[
              _AnimatedAppear(
                delay: const Duration(milliseconds: 110),
                child: CareerPulseCard(
                  app: app,
                  onOpenAdvance: () => context.go(AppRoutes.growth),
                  onOpenCompetencyMap: () =>
                      context.push(AppRoutes.competencyMap),
                  onOpenDepartment: () => context.go(AppRoutes.department),
                  onOpenRequirement: (item) {
                    AppRouter.openRequirement(
                      context,
                      item.requirement,
                      goalId: roadmap.goal.id,
                    );
                  },
                  onGapAction: (gap) {
                    final requirement = gap.item.requirement;
                    if (gap.mastery?.status == 'NEEDS_IMPROVEMENT' ||
                        gap.mastery?.status == 'REASSESS') {
                      context.go(AppRoutes.department);
                      return;
                    }
                    if (requirement.type == RequirementType.experience ||
                        requirement.type == RequirementType.numericProgress) {
                      context.go(AppRoutes.personalLog);
                      return;
                    }
                    if (requirement.type == RequirementType.certification) {
                      context.go(AppRoutes.certifications);
                      return;
                    }
                    AppRouter.openRequirement(
                      context,
                      requirement,
                      goalId: roadmap.goal.id,
                    );
                  },
                  onPrimaryAction: (analysis) {
                    final recommendation = analysis.recommendation;
                    if (recommendation.kind ==
                        AdvancementActionKind.chooseGoal) {
                      context.push(AppRoutes.goalSetup);
                      return;
                    }
                    if (recommendation.kind ==
                        AdvancementActionKind.workRoadmap) {
                      final requirementId = recommendation.requirementId;
                      if (requirementId != null) {
                        final matches = roadmap.included.where(
                          (item) => item.requirement.id == requirementId,
                        );
                        if (matches.isNotEmpty) {
                          AppRouter.openRequirement(
                            context,
                            matches.first.requirement,
                          );
                          return;
                        }
                      }
                      context.go(AppRoutes.myPath);
                      return;
                    }
                    if (recommendation.kind ==
                        AdvancementActionKind.documentRequirement) {
                      context.push(AppRoutes.growthDetails);
                      return;
                    }
                    context.go(AppRoutes.personalLog);
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),
            const _AnimatedAppear(delay: Duration(milliseconds: 140), child: _HomeUpdatesSection()),
          ],
        ),
      ),
    );
  }
}

class _CredentialAttentionCard extends StatelessWidget {
  final AppState app;

  const _CredentialAttentionCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final flagged = app.certifications.where((cert) {
      if (cert.doesNotExpire) return false;
      final expiration = cert.expirationDate;
      if (expiration == null) return true;
      return expiration.difference(today).inDays <= 60;
    }).toList()
      ..sort((a, b) {
        int priority(dynamic cert) {
          if (!cert.doesNotExpire && cert.expirationDate == null) return 0;
          final days = cert.expirationDate!.difference(today).inDays;
          if (days < 0) return 1;
          return 2;
        }

        final byPriority = priority(a).compareTo(priority(b));
        if (byPriority != 0) return byPriority;
        final aDate = a.expirationDate ?? DateTime(1900);
        final bDate = b.expirationDate ?? DateTime(1900);
        return aDate.compareTo(bDate);
      });

    if (flagged.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final shown = flagged.take(3).toList();

    String detail(dynamic cert) {
      if (!cert.doesNotExpire && cert.expirationDate == null) {
        return 'No expiration date listed';
      }
      final days = cert.expirationDate!.difference(today).inDays;
      if (days < 0) return 'Expired ${-days} day${days == -1 ? '' : 's'} ago';
      if (days == 0) return 'Expires today';
      return 'Expires in $days day${days == 1 ? '' : 's'}';
    }

    IconData iconFor(dynamic cert) {
      if (!cert.doesNotExpire && cert.expirationDate == null) {
        return Icons.event_busy_outlined;
      }
      final days = cert.expirationDate!.difference(today).inDays;
      return days < 0 ? Icons.error_outline_rounded : Icons.schedule_rounded;
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.go(AppRoutes.certifications),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium_outlined, color: cs.error),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Credentials need attention',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Text(
                    '${flagged.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.error,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Add missing dates or review credentials that are expired or expiring within 60 days.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ...shown.map(
                (cert) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(iconFor(cert), size: 18, color: cs.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          app.certificationDisplayName(cert),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        detail(cert),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              if (flagged.length > shown.length)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${flagged.length - shown.length} more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedAppear extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedAppear({required this.child, this.delay = Duration.zero});

  @override
  State<_AnimatedAppear> createState() => _AnimatedAppearState();
}

class _AnimatedAppearState extends State<_AnimatedAppear> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _show = true;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (!mounted) return;
        setState(() => _show = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: anim.drive(Tween(begin: const Offset(0, 0.06), end: Offset.zero)),
            child: child,
          ),
        );
      },
      child: _show ? widget.child : const SizedBox.shrink(),
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
          color: cs.surface,
          border: Border.all(color: cs.outline.withValues(alpha: 0.9)),
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
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.9)),
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
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if ((goalTitle ?? '').trim().isNotEmpty)
                        Text(
                          goalTitle!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
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
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
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
