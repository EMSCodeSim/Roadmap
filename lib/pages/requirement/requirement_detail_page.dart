import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class RequirementDetailPage extends StatelessWidget {
  final Object? requirement;
  const RequirementDetailPage({super.key, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final req = requirement is Requirement ? requirement as Requirement : null;
    if (req == null) return const Scaffold(body: Center(child: Text('Requirement not found.')));

    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    final liveReq = roadmap?.all.where((e) => e.requirement.id == req.id).map((e) => e.requirement).firstOrNull ?? req;
    final goalId = roadmap?.goal.id;
    final isCustom = goalId != null && liveReq.id.startsWith('$goalId::');
    final isComplete = roadmap?.all.any((e) => e.requirement.id == liveReq.id && e.isComplete) ?? false;
    final cs = Theme.of(context).colorScheme;

    final sourceLabel = switch (liveReq.requirementSource) {
      RequirementSource.commonlyRequired => 'Commonly Required',
      RequirementSource.recommended => 'Recommended',
      RequirementSource.stateRequirement => 'State Requirement',
      RequirementSource.departmentRequirement => 'Department Requirement',
    };

    return Scaffold(
      appBar: AppBar(title: Text(liveReq.name)),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isComplete ? Icons.check_circle : Icons.circle_outlined, color: isComplete ? FireOpsSemanticColors.completed : cs.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Text(_topLabel(liveReq, sourceLabel), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(liveReq.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55)),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.getStarted, extra: liveReq),
                      icon: Icon(Icons.bolt, color: cs.onPrimary),
                      label: Text('Get Started', style: TextStyle(color: cs.onPrimary)),
                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                    ),
                  ),
                  if (!isComplete && goalId != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _StartThisPanel(goalId: goalId, requirement: liveReq),
                  ],
                  if (!isComplete && goalId != null && state.profile.careerPlan.targetDate != null && state.profile.careerPlan.timelineEnabled) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _TimelineAdjustPanel(goalId: goalId, requirementId: liveReq.id),
                  ],
                  if (liveReq.type == RequirementType.numericProgress) ...[
                    const SizedBox(height: AppSpacing.md),
                    _NumericProgressPanel(goalId: goalId, isCustom: isCustom, requirement: liveReq),
                  ] else if (liveReq.type == RequirementType.taskBook && goalId != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _TaskBookPanel(goalId: goalId, requirement: liveReq),
                  ] else if (liveReq.type != RequirementType.certification) ...[
                    const SizedBox(height: AppSpacing.md),
                    _CompleteToggle(goalId: goalId, isCustom: isCustom, requirementId: liveReq.id, isComplete: isComplete),
                  ] else ...[
                    const SizedBox(height: AppSpacing.md),
                    _CertActionBar(certName: liveReq.name),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoBlock(title: 'WHAT IS IT?', body: _defaultWhatIsIt(liveReq)),
            const SizedBox(height: AppSpacing.md),
            _InfoBlock(title: "WHY IS IT ON MY PATH?", body: _whyOnPath(context, liveReq)),
            const SizedBox(height: AppSpacing.md),
            _InfoBlock(title: 'TYPICAL PREREQUISITES', body: _prereqsBlock(liveReq, state)),
            const SizedBox(height: AppSpacing.md),
            _InfoBlock(title: 'MY STATUS', body: _statusBlock(state, liveReq, isComplete, goalId)),
            const SizedBox(height: AppSpacing.lg),
            const _Notice(),
          ],
        ),
      ),
    );
  }

  static String _topLabel(Requirement r, String sourceLabel) {
    final pill = switch (r.priority) {
      RequirementPriority.core => 'CORE',
      RequirementPriority.recommended => 'RECOMMENDED',
      RequirementPriority.development => 'DEVELOPMENT',
      RequirementPriority.department => 'DEPARTMENT',
      RequirementPriority.state => 'STATE',
    };
    final flags = <String>[];
    if (r.stateDependent && r.priority != RequirementPriority.state) flags.add('STATE');
    if (r.departmentDependent && r.priority != RequirementPriority.department) flags.add('DEPT');
    final suffix = flags.isEmpty ? '' : ' • ${flags.join(' / ')}';
    return '$pill • $sourceLabel$suffix';
  }

  static String _defaultWhatIsIt(Requirement r) {
    return switch (r.type) {
      RequirementType.certification => 'A certification or credential you earn through training and testing.',
      RequirementType.trainingCourse || RequirementType.course => 'A course (often classroom + hands-on) to build competence.',
      RequirementType.taskBook => 'A documented task book demonstrating required skills in the field.',
      RequirementType.experience => 'An experience requirement typically validated by your department.',
      RequirementType.numericProgress => 'A measurable requirement you can track (hours, calls, etc.).',
      RequirementType.promotionalTest => 'A promotional testing requirement used by some departments.',
      RequirementType.practical => 'A practical skills evaluation or scenario assessment.',
      RequirementType.interview => 'An interview / oral board component of a promotional process.',
      RequirementType.education => 'An education requirement (department dependent in many systems).',
      RequirementType.custom => 'A custom requirement you or your department defines.',
    };
  }

  static String _whyOnPath(BuildContext context, Requirement r) {
    final goal = context.read<AppState>().selectedGoal;
    final goalName = goal?.title;
    final base = goalName == null ? 'This helps move you toward your next role.' : 'This is commonly used when preparing for $goalName responsibilities.';
    return switch (r.requirementSource) {
      RequirementSource.commonlyRequired => '$base It’s commonly required in many departments.',
      RequirementSource.recommended => '$base It’s commonly recommended but not universal.',
      RequirementSource.stateRequirement => '$base Requirements can be state dependent.',
      RequirementSource.departmentRequirement => '$base Requirements can be department dependent.',
    };
  }

  static String _prereqsBlock(Requirement r, AppState state) {
    if (r.prerequisiteRequirementIds.isEmpty) {
      return switch (r.type) {
        RequirementType.certification => 'Often requires prerequisite certs, minimum time in role, and department approval.',
        RequirementType.taskBook => 'Typically requires supervisor sign-off and on-the-job evaluation opportunities.',
        _ => 'Varies by agency; check your department and state certification office.',
      };
    }
    final nameSet = state.certifications.map((c) => c.name.trim().toLowerCase()).toSet();
    return r.prerequisiteRequirementIds.map((e) {
      final ok = nameSet.contains(e.trim().toLowerCase());
      return '${ok ? '✓' : '○'} $e';
    }).join('\n');
  }

  static String _statusBlock(AppState state, Requirement r, bool isComplete, String? goalId) {
    final lines = <String>[];
    if (isComplete) {
      lines.add('✓ Complete');
    } else if (goalId != null) {
      final s = state.activityStatusFor(goalId: goalId, requirementId: r.id);
      final label = switch (s) {
        RequirementActivityStatus.notStarted => '○ Not started',
        RequirementActivityStatus.planning => '◐ Planning',
        RequirementActivityStatus.scheduled => '📅 Scheduled',
        RequirementActivityStatus.inProgress => '▶ In progress',
      };
      lines.add(label);
      final schedule = state.scheduleFor(goalId: goalId, requirementId: r.id);
      if (s == RequirementActivityStatus.scheduled && schedule?.startDate != null) {
        lines.add('');
        lines.add('Start: ${_formatDate(schedule!.startDate!)}');
        if ((schedule.provider ?? '').trim().isNotEmpty) lines.add('Provider: ${schedule.provider}');
      }
    } else {
      lines.add('○ Not started');
    }

    if (r.type == RequirementType.experience && r.experienceValue != null) {
      final years = state.profile.yearsOfService;
      final required = r.experienceValue!.toStringAsFixed(0);
      lines.add('');
      lines.add('Experience: ${years ?? 0} / $required ${r.experienceUnit ?? 'years'}');
    }

    if (r.type == RequirementType.numericProgress && r.progressRequired != null) {
      final current = r.progressCurrent ?? 0;
      final unit = r.progressUnit ?? '';
      lines.add('');
      lines.add('Progress: ${current.toStringAsFixed(0)} / ${r.progressRequired!.toStringAsFixed(0)}${unit.isEmpty ? '' : ' $unit'}');
    }

    return lines.join('\n');
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _StartThisPanel extends StatelessWidget {
  final String goalId;
  final Requirement requirement;
  const _StartThisPanel({required this.goalId, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();
    final status = state.activityStatusFor(goalId: goalId, requirementId: requirement.id);
    final label = switch (status) {
      RequirementActivityStatus.notStarted => 'Start this',
      RequirementActivityStatus.planning => 'Planning',
      RequirementActivityStatus.scheduled => 'Scheduled',
      RequirementActivityStatus.inProgress => 'In progress',
    };

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _open(context, initial: status),
        icon: Icon(Icons.play_circle_outline, color: cs.primary),
        label: Text(label),
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
      ),
    );
  }

  Future<void> _open(BuildContext context, {required RequirementActivityStatus initial}) async {
    final selected = await showModalBottomSheet<RequirementActivityStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Start this', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.sm),
              Text('Choose a status to track progress. You can change this anytime.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              _StatusChoiceTile(value: RequirementActivityStatus.planning, title: 'Planning', subtitle: 'I intend to pursue this next.'),
              _StatusChoiceTile(value: RequirementActivityStatus.scheduled, title: 'Scheduled', subtitle: 'I have a course/test scheduled.'),
              _StatusChoiceTile(value: RequirementActivityStatus.inProgress, title: 'In progress', subtitle: 'I’m actively working on it.'),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    final st = context.read<AppState>();
    await st.setRequirementActivityStatus(goalId: goalId, requirementId: requirement.id, status: selected);

    if (!context.mounted) return;
    if (selected == RequirementActivityStatus.scheduled) {
      await _editSchedule(context);
    }
  }

  Future<void> _editSchedule(BuildContext context) async {
    final st = context.read<AppState>();
    final existing = st.scheduleFor(goalId: goalId, requirementId: requirement.id);

    final courseCtrl = TextEditingController(text: existing?.courseName ?? '');
    final providerCtrl = TextEditingController(text: existing?.provider ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    DateTime? start = existing?.startDate;
    DateTime? end = existing?.endDate;

    TrainingSchedule? result;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final insets = MediaQuery.viewInsetsOf(context);
        return StatefulBuilder(
          builder: (context, setModal) {
            Future<void> pickStart() async {
              final now = DateTime.now();
              final picked = await showDatePicker(context: context, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 3), initialDate: start ?? now);
              if (picked == null) return;
              setModal(() => start = picked);
            }

            Future<void> pickEnd() async {
              final now = DateTime.now();
              final picked = await showDatePicker(context: context, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 3), initialDate: end ?? (start ?? now));
              if (picked == null) return;
              setModal(() => end = picked);
            }

            return Padding(
              padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: insets.bottom + AppSpacing.lg, top: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Upcoming training', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: 'Course name (optional)')),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(controller: providerCtrl, decoration: const InputDecoration(labelText: 'Training provider (optional)')),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: _DateButton(label: 'Start date', value: start, onTap: pickStart, onClear: () => setModal(() => start = null))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _DateButton(label: 'End date', value: end, onTap: pickEnd, onClear: () => setModal(() => end = null))),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location (optional)')),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 3, minLines: 2),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        result = TrainingSchedule(
                          courseName: courseCtrl.text.trim().isEmpty ? null : courseCtrl.text.trim(),
                          provider: providerCtrl.text.trim().isEmpty ? null : providerCtrl.text.trim(),
                          startDate: start,
                          endDate: end,
                          location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        );
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    courseCtrl.dispose();
    providerCtrl.dispose();
    locationCtrl.dispose();
    notesCtrl.dispose();

    await st.setRequirementSchedule(goalId: goalId, requirementId: requirement.id, schedule: result);
  }
}

class _TimelineAdjustPanel extends StatelessWidget {
  final String goalId;
  final String requirementId;
  const _TimelineAdjustPanel({required this.goalId, required this.requirementId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();
    final o = state.getOverride(goalId, requirementId);
    final suggested = o?.suggestedStartDate;
    final removed = o?.removedFromTimeline ?? false;

    String? subtitle;
    if (removed) {
      subtitle = 'Removed from timeline (you can add it back anytime).';
    } else if (suggested != null) {
      subtitle = 'Targeted for ${RequirementDetailPage._formatDate(suggested)} (planning estimate).';
    } else {
      subtitle = 'Timeline uses your Next Step + prerequisites + schedules.';
    }

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: cs.onSurfaceVariant, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('TIMELINE', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant))),
              if (removed)
                TextButton(
                  onPressed: () => state.clearTimelineOverride(goalId: goalId, requirementId: requirementId),
                  child: const Text('Add Back'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: removed ? null : () => state.moveTimelineEarlier(goalId: goalId, requirementId: requirementId),
                  icon: Icon(Icons.arrow_upward, color: cs.primary),
                  label: const Text('Move Earlier'),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: removed ? null : () => state.moveTimelineLater(goalId: goalId, requirementId: requirementId),
                  icon: Icon(Icons.arrow_downward, color: cs.primary),
                  label: const Text('Move Later'),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: removed ? null : () => state.removeFromTimeline(goalId: goalId, requirementId: requirementId),
              icon: Icon(Icons.remove_circle_outline, color: cs.onSurfaceVariant),
              label: const Text('Remove From Timeline'),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChoiceTile extends StatelessWidget {
  final RequirementActivityStatus value;
  final String title;
  final String subtitle;
  const _StatusChoiceTile({required this.value, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(value),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
          child: Row(
            children: [
              Icon(Icons.radio_button_checked, color: cs.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _DateButton({required this.label, required this.value, required this.onTap, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = value == null ? '—' : RequirementDetailPage._formatDate(value!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (value != null) IconButton(onPressed: onClear, icon: const Icon(Icons.close), tooltip: 'Clear'),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String body;
  const _InfoBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55)),
        ],
      ),
    );
  }
}

class _CompleteToggle extends StatelessWidget {
  final String? goalId;
  final bool isCustom;
  final String requirementId;
  final bool isComplete;
  const _CompleteToggle({required this.goalId, required this.isCustom, required this.requirementId, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: FireOpsSemanticColors.completed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: FireOpsSemanticColors.completed.withValues(alpha: 0.18))),
      child: Row(
        children: [
          Expanded(child: Text('Mark complete', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
          Switch(
            value: isComplete,
            onChanged: goalId == null
                ? null
                : (v) {
                    final st = context.read<AppState>();
                    if (isCustom) {
                      st.toggleCustomRequirementComplete(requirementId, v);
                    } else {
                      st.setRequirementCompleted(goalId: goalId!, requirementId: requirementId, completed: v);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _NumericProgressPanel extends StatelessWidget {
  final String? goalId;
  final bool isCustom;
  final Requirement requirement;
  const _NumericProgressPanel({required this.goalId, required this.isCustom, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = requirement.progressCurrent ?? 0;
    final required = requirement.progressRequired ?? 0;
    final unit = requirement.progressUnit;
    final progress = required <= 0 ? 0.0 : ((current / required).clamp(0, 1) as num).toDouble();
    final remaining = (((required - current).clamp(0, double.infinity)) as num).toDouble();

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Progress', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
              Text('${current.toStringAsFixed(0)} / ${required.toStringAsFixed(0)}${unit == null ? '' : ' $unit'}', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.8), valueColor: AlwaysStoppedAnimation(cs.primary)),
          ),
          const SizedBox(height: 6),
          Text('${remaining.toStringAsFixed(0)} remaining', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: goalId == null
                  ? null
                  : () => _addProgress(context, goalId: goalId!, requirement: requirement),
              icon: Icon(Icons.add, color: cs.onPrimary),
              label: Text('Add ${unit ?? 'units'}', style: TextStyle(color: cs.onPrimary)),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addProgress(BuildContext context, {required String goalId, required Requirement requirement}) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final insets = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: insets.bottom + AppSpacing.lg, top: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '${requirement.progressUnit ?? 'Units'} to add')),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 3, minLines: 2),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    final v = double.tryParse(amountCtrl.text.trim());
                    if (v == null || v <= 0) {
                      Navigator.of(context).pop();
                      return;
                    }
                    Navigator.of(context).pop(v);
                  },
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        );
      },
    );

    amountCtrl.dispose();
    notesCtrl.dispose();

    if (result == null) return;
    final st = context.read<AppState>();
    final current = (requirement.progressCurrent ?? 0) + result;
    final required = requirement.progressRequired ?? 0;
    if (isCustom) {
      await st.updateNumericProgress(requirement.id, current: current, required: required);
    } else {
      await st.setNumericProgress(goalId: goalId, requirementId: requirement.id, current: current, required: required, unit: requirement.progressUnit);
    }
  }
}

class _CertActionBar extends StatelessWidget {
  final String certName;
  const _CertActionBar({required this.certName});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final existing = state.certifications.where((c) => c.name.trim().toLowerCase() == certName.trim().toLowerCase()).firstOrNull;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('${AppRoutes.certificationDetail}/${existing?.id ?? 'new'}', extra: existing == null ? {'name': certName} : null),
            icon: Icon(Icons.verified, color: cs.primary),
            label: const Text('Certification details'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
          ),
        ),
      ],
    );
  }
}

class _TaskBookPanel extends StatelessWidget {
  final String goalId;
  final Requirement requirement;
  const _TaskBookPanel({required this.goalId, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final st = context.watch<AppState>();
    final progress = st.taskBookProgressFor(goalId: goalId, requirementId: requirement.id);
    final completed = progress?.$1 ?? 0;
    final total = progress?.$2 ?? 0;
    final pct = total <= 0 ? 0.0 : ((completed / total).clamp(0, 1) as num).toDouble();

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Task book progress', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
              Text('$completed / $total', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: pct, minHeight: 10, backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.8), valueColor: AlwaysStoppedAnimation(cs.primary)),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _edit(context, completed: completed, total: total),
              icon: Icon(Icons.edit, color: cs.onPrimary),
              label: Text('Update progress', style: TextStyle(color: cs.onPrimary)),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, {required int completed, required int total}) async {
    final completedCtrl = TextEditingController(text: completed.toString());
    final totalCtrl = TextEditingController(text: total == 0 ? '' : total.toString());
    final result = await showModalBottomSheet<(int, int)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final insets = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: insets.bottom + AppSpacing.lg, top: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Task book progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: TextField(controller: completedCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Completed items'))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: TextField(controller: totalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total items'))),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    final c = int.tryParse(completedCtrl.text.trim()) ?? 0;
                    final t = int.tryParse(totalCtrl.text.trim()) ?? 0;
                    Navigator.of(context).pop((c, t));
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );

    completedCtrl.dispose();
    totalCtrl.dispose();
    if (result == null) return;
    await context.read<AppState>().setTaskBookProgress(goalId: goalId, requirementId: requirement.id, completedItems: result.$1, totalItems: result.$2);
  }
}

class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Text(
        'Fire service certification, promotional, and training requirements vary by state, agency, and department. FireOps Path provides career planning guidance. Always verify requirements with your department and certification authority.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

