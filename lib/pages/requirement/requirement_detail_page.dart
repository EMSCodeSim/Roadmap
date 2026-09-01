import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/services/requirement_source_presenter.dart';
import 'package:firepath/services/task_book_navigation.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/widgets/progress_ring.dart';
import 'package:firepath/widgets/status_pill.dart';

/// Requirement detail view.
///
/// This page is route-targeted by [AppRoutes.requirementDetail] and is opened
/// from Roadmap, Task Book, and Quick Log deep links.
class RequirementDetailPage extends StatelessWidget {
  final Object? requirement;
  const RequirementDetailPage({super.key, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final map = requirement is Map ? requirement as Map : null;
    final reqExtra = map == null ? null : map['requirement'];
    final req = reqExtra is Requirement
        ? reqExtra
        : (requirement is Requirement ? requirement as Requirement : null);
    if (req == null) {
      debugPrint('RequirementDetailPage opened without a Requirement extra.');
      return const Scaffold(body: Center(child: Text('Requirement not found.')));
    }

    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final overrideGoalId = map?['goalId'] as String?;
    final goalId = (overrideGoalId != null && overrideGoalId.trim().isNotEmpty)
        ? overrideGoalId
        : state.roadmap?.goal.id;
    final canMutate = goalId != null && goalId.trim().isNotEmpty;

    final override = goalId == null
        ? null
        : state.taskBookController.getOverride(goalId, req.id);
    final isCompleted = (override?.completed ?? req.completed) == true;

    final progress = _progressFor(req);
    final typeLabel = _typeLabel(req.type);
    final priorityLabel = _priorityLabel(req.priority);

    final profileState = FireOpsCatalog.stateCodeFromLegacyValue(state.profile.state);
    final sourceBadge = RequirementSourcePresenter.badgeText(req, profileStateCode: profileState);
    final sourceColors = RequirementSourcePresenter.badgeColors(context, req);

    final hasTaskBook = TaskBookLibrary.hasTasksForRequirement(req);
    final hasSkillsChecklist = TaskBookNavigation.hasSkillsChecklist(req);
    final hasPreparationTasks = TaskBookNavigation.hasPreparationTasks(req);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toTaskBook(),
        title: const Text('Requirement'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CompleteToggle(
              completed: isCompleted,
              enabled: canMutate,
              onChanged: (next) async {
                if (!canMutate) return;
                await context.read<AppState>().setRequirementCompleted(
                  goalId: goalId!,
                  requirementId: req.id,
                  completed: next,
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            _HeaderCard(
              title: req.name,
              subtitle: req.category,
              typeLabel: typeLabel,
              priorityLabel: priorityLabel,
              sourceLabel: sourceBadge,
              sourceBg: sourceColors.bg,
              sourceFg: sourceColors.fg,
              completed: isCompleted,
              progress: progress,
              progressLabel: _progressLabel(req),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionTitle(
              icon: Icons.playlist_add_check,
              title: 'How to Complete',
              subtitle: 'Turn this requirement into next actions.',
            ),
            const SizedBox(height: AppSpacing.md),
            _StepsCard(
              steps: _stepsForRequirement(
                req,
                hasTaskBook: hasTaskBook,
                hasSkillsChecklist: hasSkillsChecklist,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _PrimaryActionsCard(
              onOpenGetStarted: () => context.push(
                AppRoutes.getStarted,
                extra: req,
              ),
              onOpenChecklist: hasSkillsChecklist
                  ? () => AppRouter.openRequirement(
                        context,
                        req,
                        goalId: goalId,
                      )
                  : null,
              onOpenTaskBook: hasPreparationTasks
                  ? () => AppRouter.openPreparationTasks(context, req)
                  : null,
              onQuickLog: () {
                final tags = <String>['requirement'];
                if (hasTaskBook) tags.add('task-book');
                QuickLogLauncher.open(
                  context,
                  prefill: LogPrefill(
                    title: req.name,
                    category: req.category,
                    relatedGoalId: goalId,
                    relatedRequirementId: req.id,
                    relatedTaskId: null,
                    tags: tags,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            if (req.description.trim().isNotEmpty)
              _BodyCard(
                icon: Icons.info_outline,
                title: 'Notes',
                child: Text(
                  req.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: cs.onSurface,
                      ),
                ),
              ),
            if (req.description.trim().isNotEmpty)
              const SizedBox(height: AppSpacing.md),

            _BodyCard(
              icon: Icons.verified_outlined,
              title: 'Requirement source',
              child: _RequirementSourceCard(requirement: req, profileStateCode: profileState),
            ),

            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'Always verify requirements with your department, state authority, official task book, or certifying organization.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String typeLabel;
  final String priorityLabel;
  final String sourceLabel;
  final Color sourceBg;
  final Color sourceFg;
  final bool completed;
  final double? progress;
  final String? progressLabel;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.priorityLabel,
    required this.sourceLabel,
    required this.sourceBg,
    required this.sourceFg,
    required this.completed,
    required this.progress,
    required this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completedColor = FireOpsSemanticColors.completed;
    final statusText = completed ? 'Completed' : 'In progress';
    final statusBg = completed
        ? completedColor.withValues(alpha: 0.16)
        : cs.surfaceContainerHighest;
    final statusFg = completed ? completedColor : cs.onSurfaceVariant;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (progress != null)
            ProgressRing(
              progress: progress!,
              size: 64,
              strokeWidth: 7,
              centerLabel: progressLabel,
              progressColor: completed ? completedColor : cs.primary,
            )
          else
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.flag_outlined,
                color: completed ? completedColor : cs.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(text: typeLabel, backgroundColor: cs.surfaceContainerHighest, foregroundColor: cs.onSurfaceVariant, maxWidth: 170),
                    StatusPill(text: priorityLabel, backgroundColor: cs.surfaceContainerHighest, foregroundColor: cs.onSurfaceVariant, maxWidth: 170),
                    StatusPill(text: sourceLabel, backgroundColor: sourceBg, foregroundColor: sourceFg, maxWidth: 220),
                    StatusPill(text: statusText, backgroundColor: statusBg, foregroundColor: statusFg, maxWidth: 170),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementSourceCard extends StatelessWidget {
  final Requirement requirement;
  final String? profileStateCode;
  const _RequirementSourceCard({required this.requirement, required this.profileStateCode});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = requirement;
    final sourceLine = RequirementSourcePresenter.shortLine(r, profileStateCode: profileStateCode);

    final hasUrl = (r.sourceUrl ?? '').trim().isNotEmpty;
    final hasTitle = (r.sourceTitle ?? '').trim().isNotEmpty;

    final verifiedDate = r.sourceVerifiedDate;
    final verifiedText = verifiedDate == null
        ? null
        : 'Verified ${verifiedDate.year}-${verifiedDate.month.toString().padLeft(2, '0')}-${verifiedDate.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(sourceLine, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          r.requirementSource == RequirementSource.stateRequirement
              ? 'Shown because your profile state matches a verified state requirement entry. Always confirm final requirements with the official state/department source.'
              : r.requirementSource == RequirementSource.departmentRequirement
                  ? 'Department-specific items are meant to match local SOPs, promotions, and internal task books.'
                  : 'Common items are recommended starting points when verified state-specific data is not available.'
          ,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
        ),
        if ((r.sourceNotes ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Notes: ${r.sourceNotes}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
        ],
        if (hasUrl) ...[
          const SizedBox(height: 12),
          _SourceRow(
            title: hasTitle ? r.sourceTitle! : 'Official source',
            subtitle: verifiedText ?? 'Verified source',
            url: r.sourceUrl!,
          ),
        ] else if (hasTitle || verifiedText != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasTitle ? r.sourceTitle! : 'Verified source', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                if (verifiedText != null) ...[
                  const SizedBox(height: 4),
                  Text(verifiedText, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionTitle({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepsCard extends StatelessWidget {
  final List<String> steps;
  const _StepsCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
            if (i != steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 13),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  height: 18,
                  width: 1,
                  color: cs.outline.withValues(alpha: 0.18),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryActionsCard extends StatelessWidget {
  final VoidCallback onOpenGetStarted;
  final VoidCallback? onOpenChecklist;
  final VoidCallback? onOpenTaskBook;
  final VoidCallback onQuickLog;

  const _PrimaryActionsCard({
    required this.onOpenGetStarted,
    required this.onOpenChecklist,
    required this.onOpenTaskBook,
    required this.onQuickLog,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionButton(
            icon: Icons.rocket_launch,
            label: 'Get Started (recommended)',
            onPressed: onOpenGetStarted,
            filled: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (onOpenChecklist != null) ...[
            _ActionButton(
              icon: Icons.checklist,
              label: 'Open skills checklist',
              onPressed: onOpenChecklist,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (onOpenTaskBook != null) ...[
            _ActionButton(
              icon: Icons.menu_book_outlined,
              label: 'Open preparation tasks',
              onPressed: onOpenTaskBook,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _ActionButton(
            icon: Icons.bolt,
            label: 'Quick Log progress',
            onPressed: onQuickLog,
          ),
          const SizedBox(height: 10),
          Text(
            'Tip: Quick Log entries are automatically connected to this requirement when possible.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _BodyCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  const _ActionButton({required this.icon, required this.label, required this.onPressed, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = filled ? cs.primary : cs.surfaceContainerHighest;
    final fg = filled ? cs.onPrimary : cs.onSurface;
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w800),
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: fg.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}

class _CompleteToggle extends StatelessWidget {
  final bool completed;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _CompleteToggle({required this.completed, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completedColor = FireOpsSemanticColors.completed;
    return FilledButton.tonalIcon(
      onPressed: enabled ? () => onChanged(!completed) : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        backgroundColor: completed
            ? completedColor.withValues(alpha: 0.16)
            : cs.surfaceContainerHighest,
        foregroundColor: completed ? completedColor : cs.onSurface,
      ),
      icon: Icon(completed ? Icons.check_circle : Icons.circle_outlined, color: completed ? completedColor : cs.onSurfaceVariant, size: 18),
      label: Text(
        completed ? 'Done' : 'Mark done',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: completed ? completedColor : cs.onSurface),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String url;
  const _SourceRow({required this.title, required this.subtitle, required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        final uri = Uri.tryParse(url);
        if (uri == null) {
          debugPrint('Invalid requirement source URL: $url');
          return;
        }
        launchUrl(uri, mode: LaunchMode.externalApplication).then((ok) {
          if (!ok) debugPrint('launchUrl failed for $url');
        }).catchError((e) {
          debugPrint('launchUrl error for $url: $e');
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(Icons.link, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

double? _progressFor(Requirement r) {
  final required = r.progressRequired;
  final current = r.progressCurrent;
  if (required == null || current == null || required <= 0) return null;
  return (current / required).clamp(0.0, 1.0);
}

String? _progressLabel(Requirement r) {
  final required = r.progressRequired;
  final current = r.progressCurrent;
  if (required == null || current == null || required <= 0) return null;
  final pct = ((current / required).clamp(0.0, 1.0) * 100).round();
  return '$pct%';
}

String _typeLabel(RequirementType t) => switch (t) {
      RequirementType.certification => 'Certification',
      RequirementType.trainingCourse => 'Training course',
      RequirementType.course => 'Course',
      RequirementType.education => 'Education',
      RequirementType.taskBook => 'Task book',
      RequirementType.experience => 'Experience',
      RequirementType.numericProgress => 'Progress',
      RequirementType.promotionalTest => 'Promotional test',
      RequirementType.practical => 'Practical',
      RequirementType.interview => 'Interview',
      RequirementType.custom => 'Custom',
    };

String _priorityLabel(RequirementPriority p) => switch (p) {
      RequirementPriority.core => 'Core',
      RequirementPriority.recommended => 'Recommended',
      RequirementPriority.development => 'Development',
      RequirementPriority.department => 'Department',
      RequirementPriority.state => 'State',
    };

List<String> _stepsForRequirement(
  Requirement r, {
  required bool hasTaskBook,
  required bool hasSkillsChecklist,
}) {
  final unit = (r.progressUnit ?? r.experienceUnit ?? '').trim();
  final unitSuffix = unit.isEmpty ? '' : ' ($unit)';

  if (hasSkillsChecklist || r.type == RequirementType.certification) {
    return [
      'Open the skills checklist and work the next unfinished JPR / objective.',
      'Add department, state, or academy items on top of the national baseline.',
      'Use Quick Log to record practice, training hours, or sign-offs connected to this credential.',
      'The credential itself is complete only when it is current in Certs — checking skills is preparation, not certification.',
    ];
  }

  if (hasTaskBook || r.type == RequirementType.taskBook) {
    return [
      'Open the Task Book and identify the next incomplete task.',
      'Use Quick Log to record practice, training hours, or task sign-offs connected to this requirement.',
      'Save evidence (photos, certificates, evaluator notes) as you go.',
      'Mark complete once your evaluator/department signs off.',
    ];
  }

  return switch (r.type) {
    RequirementType.certification || RequirementType.trainingCourse || RequirementType.course || RequirementType.education => [
        'Open “Get Started” to see prerequisites and the best official links for your state.',
        'Find training (academy, state, or approved provider) and enroll.',
        'Study with your preferred materials and log study time with Quick Log.',
        'After completion, record the credential and mark this requirement complete.',
      ],
    RequirementType.numericProgress => [
        'Confirm the required target and unit$unitSuffix.',
        'Use Quick Log to capture each session and keep the current total up to date.',
        'Review progress weekly until you hit the target.',
        'Mark complete when your total meets the requirement.',
      ],
    RequirementType.experience => [
        'Confirm the minimum experience needed (time-in-role, years, or months).',
        'Log key milestones (hours, assignments, ride-alongs) using Quick Log.',
        'Track evidence (letters, evaluations, duty assignments) in your Career Vault.',
        'Mark complete when your experience minimum is satisfied.',
      ],
    RequirementType.promotionalTest || RequirementType.practical || RequirementType.interview => [
        'Use “Get Started” to gather official testing / promotional resources.',
        'Create a weekly study plan and log practice reps with Quick Log.',
        'Capture feedback and scoring notes after each mock scenario.',
        'Mark complete once you pass / are cleared by your department.',
      ],
    RequirementType.custom => [
        'Clarify what “done” means (who verifies it and what evidence counts).',
        'Add a department link or reference material in Get Started.',
        'Use Quick Log for each step until you reach completion.',
        'Mark complete when verified.',
      ],
    _ => [
        'Open “Get Started” to gather official info and training resources.',
        'Use Quick Log to capture time and milestones.',
        'Add evidence as you go.',
        'Mark complete once verified.',
      ],
  };
}

String _sourceSubtitle(Requirement r) {
  final parts = <String>[];
  if ((r.sourceStateCode ?? '').trim().isNotEmpty) parts.add(r.sourceStateCode!);
  if (r.sourceVerifiedDate != null) {
    parts.add('Verified ${r.sourceVerifiedDate!.year}-${r.sourceVerifiedDate!.month.toString().padLeft(2, '0')}-${r.sourceVerifiedDate!.day.toString().padLeft(2, '0')}');
  }
  return parts.isEmpty ? 'Tap to view' : parts.join(' • ');
}
