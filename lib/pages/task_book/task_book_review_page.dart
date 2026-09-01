import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/requirement_source_presenter.dart';
import 'package:firepath/services/task_book_setup_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/widgets/progress_ring.dart';
import 'package:firepath/widgets/status_pill.dart';

/// “Your Task Book is Ready” summary screen.
///
/// This is shown immediately after onboarding and also after a rebuild.
class TaskBookReviewPage extends StatefulWidget {
  const TaskBookReviewPage({super.key});

  @override
  State<TaskBookReviewPage> createState() => _TaskBookReviewPageState();
}

class _TaskBookReviewPageState extends State<TaskBookReviewPage> {
  final TaskBookSetupStore _setupStore = TaskBookSetupStore();
  bool _finishing = false;
  bool _rebuilding = false;
  bool _showAllSatisfied = false;
  bool _showAllRemaining = false;

  @override
  void initState() {
    super.initState();
    // Ensure bootstrap will route here after onboarding.
    _setupStore.setReviewPending(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    if (roadmap == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton.toTaskBook(),
          title: const Text('Your Task Book'),
        ),
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Choose your Next Level before building a Task Book.'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () => context.go(AppRoutes.goalSetup),
                    child: const Text('Choose Next Level'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentRole = state.profile.currentRoles.isEmpty
        ? 'Current role not set'
        : state.profile.currentRoles.join(' / ');
    final stateName = FireOpsCatalog.stateNameForCode(state.profile.state);

    final included = roadmap.included.length;
    final excluded = roadmap.all.length - included;
    final satisfied = roadmap.included.where((e) => e.isComplete).toList();
    final remaining = roadmap.included.where((e) => !e.isComplete).toList();

    final satisfiedCertItems = satisfied
        .where((e) => e.requirement.type == RequirementType.certification)
        .toList();
    final satisfiedOtherItems = satisfied
        .where((e) => e.requirement.type != RequirementType.certification)
        .toList();

    final percent = (roadmap.percentComplete * 100).round();
    final estimate = _WorkEstimate.estimateFor(
      remaining.map((e) => e.requirement).toList(),
    );
    final groupedRemaining = _RequirementGrouper.groupRemaining(remaining);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toTaskBook(),
        title: const Text('Your Task Book'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            _HeroCard(
              goalTitle: roadmap.goal.title,
              currentRoleLabel: currentRole,
              stateLabel: stateName,
              percent: percent,
              remainingCount: remaining.length,
              estimateLabel: estimate.label,
            ),
            const SizedBox(height: 16),
            _MetricsStrip(
              included: included,
              excluded: excluded,
              satisfied: satisfied.length,
              remaining: remaining.length,
            ),
            const SizedBox(height: 18),
            Text(
              'Auto-satisfied (from your profile)',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _SatisfiedCard(
              certItems: satisfiedCertItems,
              otherItems: satisfiedOtherItems,
              certifications: state.certifications,
              profileStateCode: FireOpsCatalog.stateCodeFromLegacyValue(state.profile.state),
              expanded: _showAllSatisfied,
              onToggleExpanded: () => setState(
                () => _showAllSatisfied = !_showAllSatisfied,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Remaining requirements',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _RemainingCard(
              groups: groupedRemaining,
              expanded: _showAllRemaining,
              onToggleExpanded: () => setState(
                () => _showAllRemaining = !_showAllRemaining,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'This plan is designed to help organize training and advancement. Always verify requirements with your department, state authority, official task book, or certifying organization.',
                style: t.bodySmall?.copyWith(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 58,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _finishing ? null : _acceptAndStart,
                  icon: const Icon(Icons.rocket_launch_outlined),
                  label: Text(
                    _finishing ? 'Saving…' : 'Accept & Start Task Book',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _finishing
                            ? null
                            : () async {
                                await _setupStore.setReviewPending(false);
                                if (!context.mounted) return;
                                context.push(AppRoutes.taskBookRequirementsSetup);
                              },
                        icon: const Icon(Icons.tune),
                        label: const Text('Customize'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _finishing
                            ? null
                            : () async {
                                await _setupStore.setReviewPending(false);
                                if (!context.mounted) return;
                                context.go(AppRoutes.goalSetup);
                              },
                        icon: const Icon(Icons.swap_calls),
                        label: const Text('Change goal'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _rebuilding ? null : _rebuildFromProfile,
                  icon: const Icon(Icons.autorenew),
                  label: Text(
                    _rebuilding
                        ? 'Rebuilding…'
                        : 'Rebuild Task Book from current info',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rebuildFromProfile() async {
    setState(() => _rebuilding = true);
    try {
      await context.read<AppState>().rebuildTaskBookForCurrentState();
      if (!mounted) return;
      final label = FireOpsCatalog.stateNameForCode(
        context.read<AppState>().profile.state,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            label == null ? 'Task Book refreshed.' : 'Task Book refreshed for $label.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('TaskBookReviewPage rebuild failed: $e');
    } finally {
      if (mounted) setState(() => _rebuilding = false);
    }
  }

  Future<void> _acceptAndStart() async {
    setState(() => _finishing = true);
    try {
      await _setupStore.setReviewPending(false);
      if (!mounted) return;
      // This summary is explicitly for the generated Career Road task book.
      await context.read<AppState>().taskBookController.setActiveTaskBook(null);
      if (!mounted) return;
      context.go(AppRoutes.myPath);
    } catch (e) {
      debugPrint('TaskBookReviewPage accept failed: $e');
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.goalTitle,
    required this.currentRoleLabel,
    required this.stateLabel,
    required this.percent,
    required this.remainingCount,
    required this.estimateLabel,
  });

  final String goalTitle;
  final String currentRoleLabel;
  final String? stateLabel;
  final int percent;
  final int remainingCount;
  final String? estimateLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final sub = [
      currentRoleLabel,
      if (stateLabel != null && stateLabel!.trim().isNotEmpty) stateLabel!,
    ].join(' • ');

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer.withValues(alpha: 0.90),
            cs.secondaryContainer.withValues(alpha: 0.62),
          ],
        ),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Career Road is ready',
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      goalTitle,
                      style: t.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ProgressRing(
                progress: percent / 100,
                size: 64,
                strokeWidth: 7,
                centerLabel: '$percent%',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Based on your role and the certs you already have, we built a Task Book for this Next Level. Review what’s already satisfied, then accept or customize before you start logging progress.',
            style: t.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(text: sub, maxWidth: 260),
              StatusPill(
                text: remainingCount == 1
                    ? '1 item remaining'
                    : '$remainingCount items remaining',
              ),
              if (estimateLabel != null) StatusPill(text: estimateLabel!),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip({
    required this.included,
    required this.excluded,
    required this.satisfied,
    required this.remaining,
  });
  final int included;
  final int excluded;
  final int satisfied;
  final int remaining;

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
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Metric(label: 'Included', value: '$included'),
          _Metric(label: 'Removed', value: '$excluded'),
          _Metric(label: 'Satisfied', value: '$satisfied'),
          _Metric(label: 'Remaining', value: '$remaining'),
        ],
      ),
    );
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

class _SatisfiedCard extends StatelessWidget {
  const _SatisfiedCard({
    required this.certItems,
    required this.otherItems,
    required this.certifications,
    required this.profileStateCode,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final List<RoadmapRequirement> certItems;
  final List<RoadmapRequirement> otherItems;
  final List<Certification> certifications;
  final String? profileStateCode;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  static const int _previewLimit = 6;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final all = [...certItems, ...otherItems];

    if (all.isEmpty) {
      return Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Text(
          'Nothing is automatically satisfied yet. That’s okay — you’ll start making progress right away.',
          style: t.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      );
    }

    final visible = expanded ? all : all.take(_previewLimit).toList();
    final hiddenCount = all.length - visible.length;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.verified_outlined, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${all.length} satisfied',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                StatusPill(text: 'Auto-detected'),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Column(
              children: [
                for (final item in visible)
                  _SatisfiedRow(
                    req: item.requirement,
                    certifications: certifications,
                    profileStateCode: profileStateCode,
                  ),
              ],
            ),
          ),
          if (all.length > _previewLimit)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: OutlinedButton.icon(
                onPressed: onToggleExpanded,
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(expanded ? 'Show less' : 'Show $hiddenCount more'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SatisfiedRow extends StatelessWidget {
  const _SatisfiedRow({
    required this.req,
    required this.certifications,
    required this.profileStateCode,
  });
  final Requirement req;
  final List<Certification> certifications;
  final String? profileStateCode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final subtitle = _SatisfiedSubtitleBuilder.subtitleFor(
      req: req,
      certifications: certifications,
    );
    final badgeText = RequirementSourcePresenter.badgeText(
      req,
      profileStateCode: profileStateCode,
    );
    final badgeColors = RequirementSourcePresenter.badgeColors(context, req);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle_outline, color: cs.onSecondaryContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: t.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                StatusPill(
                  text: badgeText,
                  backgroundColor: badgeColors.bg,
                  foregroundColor: badgeColors.fg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainingCard extends StatelessWidget {
  const _RemainingCard({
    required this.groups,
    required this.expanded,
    required this.onToggleExpanded,
  });
  final List<_RequirementGroup> groups;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  static const int _previewGroups = 3;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    if (groups.isEmpty) {
      return Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Text(
          'Everything is satisfied. If something looks off, rebuild from your profile or customize your requirements.',
          style: t.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      );
    }

    final visible = expanded ? groups : groups.take(_previewGroups).toList();
    final hiddenCount = groups.length - visible.length;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.playlist_add_check_outlined,
                    color: cs.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Next steps, grouped',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                StatusPill(
                  text: '${groups.fold<int>(0, (p, g) => p + g.items.length)} items',
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Column(
              children: [
                for (final g in visible) _RemainingGroupTile(group: g),
              ],
            ),
          ),
          if (groups.length > _previewGroups)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: OutlinedButton.icon(
                onPressed: onToggleExpanded,
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(
                  expanded ? 'Show fewer groups' : 'Show $hiddenCount more groups',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RemainingGroupTile extends StatelessWidget {
  const _RemainingGroupTile({required this.group});
  final _RequirementGroup group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final reqs = group.items;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.10))),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        collapsedIconColor: cs.onSurfaceVariant,
        iconColor: cs.onSurfaceVariant,
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.title,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            StatusPill(text: '${reqs.length}'),
          ],
        ),
        subtitle: group.subtitle == null
            ? null
            : Text(
                group.subtitle!,
                style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
        children: [
          for (final r in reqs)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _RequirementIcon.iconFor(r.type),
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.name,
                      style: t.bodyMedium?.copyWith(height: 1.25),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RequirementGrouper {
  static List<_RequirementGroup> groupRemaining(
    List<RoadmapRequirement> remaining,
  ) {
    final items = remaining.map((e) => e.requirement).toList();
    final by = <String, List<Requirement>>{};

    String keyFor(Requirement r) {
      final cat = r.timelineCategory;
      if (cat != null) {
        return switch (cat) {
          TimelineCategory.certification => 'Certifications',
          TimelineCategory.course => 'Courses',
          TimelineCategory.experience => 'Experience',
          TimelineCategory.taskBook => 'Task Book items',
          TimelineCategory.renewal => 'Renewals',
          TimelineCategory.promotionalPreparation => 'Promotional prep',
          TimelineCategory.development => 'Development',
          TimelineCategory.departmentRequirement => 'Department items',
        };
      }
      return switch (r.type) {
        RequirementType.certification => 'Certifications',
        RequirementType.trainingCourse || RequirementType.course => 'Courses',
        RequirementType.experience => 'Experience',
        RequirementType.taskBook => 'Task Book items',
        RequirementType.numericProgress => 'Progress goals',
        RequirementType.promotionalTest => 'Promotional prep',
        RequirementType.practical => 'Practicals',
        RequirementType.interview => 'Interviews',
        RequirementType.education => 'Education',
        RequirementType.custom => 'Other',
      };
    }

    for (final r in items) {
      final key = keyFor(r);
      by.putIfAbsent(key, () => <Requirement>[]).add(r);
    }

    final groups = by.entries
        .map((e) {
          e.value.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return _RequirementGroup(title: e.key, items: e.value);
        })
        .toList();
    groups.sort((a, b) => b.items.length.compareTo(a.items.length));
    return groups;
  }
}

class _RequirementGroup {
  final String title;
  final String? subtitle;
  final List<Requirement> items;
  const _RequirementGroup({required this.title, required this.items, this.subtitle});
}

class _WorkEstimate {
  final String? label;
  const _WorkEstimate({required this.label});

  static _WorkEstimate estimateFor(List<Requirement> remaining) {
    final knownDays = remaining
        .map((r) => r.estimatedDurationDays)
        .whereType<int>()
        .where((d) => d > 0)
        .toList();
    if (knownDays.isEmpty) return const _WorkEstimate(label: null);
    final totalDays = knownDays.fold<int>(0, (p, d) => p + d);
    final weeks = (totalDays / 7).round();
    if (weeks <= 0) return const _WorkEstimate(label: null);
    if (weeks == 1) return const _WorkEstimate(label: 'Est. ~1 week');
    if (weeks < 12) return _WorkEstimate(label: 'Est. ~$weeks weeks');
    final months = (weeks / 4).round();
    return _WorkEstimate(label: 'Est. ~$months months');
  }
}

class _RequirementIcon {
  static IconData iconFor(RequirementType type) {
    return switch (type) {
      RequirementType.certification => Icons.workspace_premium_outlined,
      RequirementType.trainingCourse || RequirementType.course =>
        Icons.school_outlined,
      RequirementType.experience => Icons.timer_outlined,
      RequirementType.taskBook => Icons.checklist_outlined,
      RequirementType.numericProgress => Icons.trending_up,
      RequirementType.promotionalTest => Icons.quiz_outlined,
      RequirementType.practical => Icons.construction_outlined,
      RequirementType.interview => Icons.record_voice_over_outlined,
      RequirementType.education => Icons.menu_book_outlined,
      RequirementType.custom => Icons.tune,
    };
  }
}

class _SatisfiedSubtitleBuilder {
  static String? subtitleFor({
    required Requirement req,
    required List<Certification> certifications,
  }) {
    if (req.type == RequirementType.certification) {
      final defId = req.certificationDefinitionId;
      if (defId == null || defId.trim().isEmpty) {
        return 'Certification requirement satisfied';
      }
      final matches = certifications
          .where((c) => (c.certificationDefinitionId ?? '').trim() == defId.trim())
          .toList();
      if (matches.isEmpty) return 'Certification requirement satisfied';

      int rank(CertificationStatus s) => switch (s) {
            CertificationStatus.current => 0,
            CertificationStatus.expiringSoon => 1,
            CertificationStatus.expired => 2,
          };
      matches.sort((a, b) {
        final byStatus = rank(a.status).compareTo(rank(b.status));
        if (byStatus != 0) return byStatus;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      final best = matches.first;
      final statusLabel = switch (best.status) {
        CertificationStatus.current => 'Current',
        CertificationStatus.expiringSoon => 'Expiring soon',
        CertificationStatus.expired => 'Expired',
      };
      return 'Matched cert: ${best.name} ($statusLabel)';
    }

    if (req.type == RequirementType.experience && req.experienceValue != null) {
      final unit = req.experienceUnit == null || req.experienceUnit!.trim().isEmpty
          ? 'years'
          : req.experienceUnit!;
      return 'Requirement met: ${req.experienceValue} $unit';
    }

    if (req.type == RequirementType.numericProgress &&
        req.progressCurrent != null &&
        req.progressRequired != null) {
      final unit = req.progressUnit == null ? '' : ' ${req.progressUnit}';
      return 'Progress: ${req.progressCurrent}/${req.progressRequired}$unit';
    }

    return null;
  }
}
