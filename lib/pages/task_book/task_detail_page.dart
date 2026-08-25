import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/models/resource.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/fireopssim_links.dart';
import 'package:firepath/services/task_book_resource_composer.dart';

Future<void> _openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    debugPrint('Invalid URL: $url');
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) debugPrint('launchUrl failed for $url');
}

Future<void> _setTaskStatusWithCareerHandoff({
  required BuildContext context,
  required TaskBookTaskStatus previous,
  required TaskBookTaskStatus next,
  required String goalId,
  required String requirementId,
  required TaskBookTaskDefinition task,
  required String? qualificationName,
}) async {
  await context.read<AppState>().setTaskStatus(
    goalId: goalId,
    requirementId: requirementId,
    taskId: task.id,
    status: next,
    completionSource: next == TaskBookTaskStatus.complete
        ? TaskBookCompletionSource.selfVerified
        : null,
  );

  if (!context.mounted ||
      next != TaskBookTaskStatus.complete ||
      previous == TaskBookTaskStatus.complete) {
    return;
  }

  final addToRecord = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => _CompletionHandoffSheet(
      taskTitle: task.title,
      qualificationName: qualificationName,
    ),
  );

  if (addToRecord != true || !context.mounted) return;

  await QuickLogLauncher.open(
    context,
    prefill: LogPrefill(
      title: task.title,
      category: qualificationName,
      relatedGoalId: goalId,
      relatedRequirementId: requirementId,
      relatedTaskId: task.id,
      tags: const ['task-book', 'completed'],
    ),
  );
}

class TaskDetailPage extends StatelessWidget {
  final Object? extra;
  const TaskDetailPage({super.key, required this.extra});

  @override
  Widget build(BuildContext context) {
    if (extra is! Map) {
      return const Scaffold(body: Center(child: Text('Task not found.')));
    }
    final m = Map<String, dynamic>.from(extra as Map);
    final goalId = (m['goalId'] as String?) ?? '';
    final requirementId = (m['requirementId'] as String?) ?? '';
    final qualificationName = (m['qualificationName'] as String?)?.trim();
    final task = m['task'] is TaskBookTaskDefinition
        ? (m['task'] as TaskBookTaskDefinition)
        : null;
    if (goalId.isEmpty || requirementId.isEmpty || task == null) {
      return const Scaffold(body: Center(child: Text('Task not found.')));
    }

    final state = context.watch<AppState>();
    final status = state.taskStatusFor(
      goalId: goalId,
      requirementId: requirementId,
      taskId: task.id,
    );

    String? certificationDefinitionId;
    final roadmap = state.roadmap;
    if (roadmap != null) {
      for (final item in roadmap.included) {
        if (item.requirement.id == requirementId) {
          certificationDefinitionId =
              item.requirement.certificationDefinitionId;
          break;
        }
      }
    }

    final catalog = FireOpsCatalog.resources();
    final combinedRefs = TaskBookResourceComposer.buildTaskDetailReferences(
      certId: certificationDefinitionId,
      taskId: task.id,
      stateCode: FireOpsCatalog.stateCodeFromLegacyValue(state.profile.state),
      catalogCombined: catalog,
    );

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toTaskBook(),
        title: Text(task.title.toUpperCase()),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            _StatusCard(
              status: status,
              onChanged: (next) => _setTaskStatusWithCareerHandoff(
                context: context,
                previous: status,
                next: next,
                goalId: goalId,
                requirementId: requirementId,
                task: task,
                qualificationName: qualificationName,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if ((task.fireOpsObjective ?? '').trim().isNotEmpty)
              _InfoCard(
                title: 'OBJECTIVE',
                body: task.fireOpsObjective!,
                tone: _CardTone.primary,
              ),
            if ((task.fireOpsObjective ?? '').trim().isNotEmpty)
              const SizedBox(height: AppSpacing.md),
            _ExpandableListCard(
              title: 'WHAT TO KNOW',
              items: task.whatToKnow,
              emptyText: 'No notes yet. Add what your crew expects on this skill.',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExpandableListCard(
              title: 'PERFORMANCE TASKS',
              items: task.performanceTasks,
              emptyText: 'No steps listed yet. Add the checklist you get signed off on.',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExpandableListCard(
              title: 'SAFETY POINTS',
              items: task.safetyPoints,
              emptyText: 'No safety notes yet. Add your must-not-miss items.',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExpandableListCard(
              title: 'COMMON MISTAKES',
              items: task.commonMistakes,
              emptyText: 'No watch-outs yet. Add the mistakes you see most.',
            ),
            const SizedBox(height: AppSpacing.md),
            _CompanionCard(
              certificationDefinitionId: certificationDefinitionId,
              taskId: task.id,
              stateCode: FireOpsCatalog.stateCodeFromLegacyValue(state.profile.state),
            ),
            const SizedBox(height: AppSpacing.md),
            _PracticeCard(tools: task.practiceTools),
            const SizedBox(height: AppSpacing.md),
            _ResourcesCard(
              resources: task.resources,
              extraResources: combinedRefs,
            ),
            const SizedBox(height: AppSpacing.md),
            _MyRecordCard(
              onLogPractice: () {
                if (status == TaskBookTaskStatus.notStarted) {
                  context.read<AppState>().setTaskStatus(
                    goalId: goalId,
                    requirementId: requirementId,
                    taskId: task.id,
                    status: TaskBookTaskStatus.practicing,
                    completionSource: null,
                  );
                }
                QuickLogLauncher.open(
                  context,
                  prefill: LogPrefill(
                    title: task.title,
                    category: qualificationName,
                    relatedGoalId: goalId,
                    relatedRequirementId: requirementId,
                    relatedTaskId: task.id,
                    tags: ['task-book', 'practice'],
                  ),
                );
              },
              onAddEvidence: () => context.push(
                AppRoutes.careerEvidence,
                extra: EvidencePrefill(
                  title: task.title,
                  relatedGoalId: goalId,
                  relatedRequirementId: requirementId,
                  category: qualificationName,
                  tags: ['task-book', 'evidence'],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoCard(
              title: 'NOTICE',
              body:
                  'This is planning help. Verify requirements with your department, state authority, and official Task Book.',
              tone: _CardTone.neutral,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final TaskBookTaskStatus status;
  final ValueChanged<TaskBookTaskStatus> onChanged;
  const _StatusCard({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String label(TaskBookTaskStatus s) => switch (s) {
      TaskBookTaskStatus.notStarted => 'Not Started',
      TaskBookTaskStatus.practicing => 'Practicing',
      TaskBookTaskStatus.readyForEvaluation => 'Ready for Evaluation',
      TaskBookTaskStatus.complete => 'Complete',
    };

    Color tone(TaskBookTaskStatus s) => switch (s) {
      TaskBookTaskStatus.complete => FireOpsSemanticColors.completed,
      TaskBookTaskStatus.readyForEvaluation => cs.primary,
      TaskBookTaskStatus.practicing => cs.secondary,
      TaskBookTaskStatus.notStarted => cs.onSurfaceVariant,
    };

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: tone(status), size: 20),
              const SizedBox(width: 8),
              Text(
                'STATUS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                label(status),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: TaskBookTaskStatus.values
                .map(
                  (s) => ChoiceChip(
                    label: Text(label(s)),
                    selected: s == status,
                    onSelected: (_) => onChanged(s),
                    labelStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

enum _CardTone { primary, neutral }

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  final _CardTone tone;
  const _InfoCard({
    required this.title,
    required this.body,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = tone == _CardTone.primary
        ? cs.primaryContainer
        : cs.surfaceContainerHighest.withValues(alpha: 0.6);
    final border = tone == _CardTone.primary
        ? cs.primary.withValues(alpha: 0.18)
        : cs.outline.withValues(alpha: 0.10);
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _ExpandableListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final String emptyText;
  const _ExpandableListCard({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            14,
          ),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          children: [
            if (items.isEmpty)
              Text(
                emptyText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              )
            else
              ...items.asMap().entries.map((e) {
                final i = e.key;
                final text = e.value;
                return Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  final String? certificationDefinitionId;
  final String taskId;
  final String? stateCode;

  const _CompanionCard({
    required this.certificationDefinitionId,
    required this.taskId,
    required this.stateCode,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cert = certificationDefinitionId?.trim();
    final state = stateCode?.trim().toUpperCase();

    final taskUri = FireOpsSimLinks.taskbookResources(
      cert: cert,
      task: taskId,
      state: state,
    );
    final studyUri = (cert == null || cert.isEmpty)
        ? taskUri
        : FireOpsSimLinks.studyGuides(cert: cert);
    const emsCerts = {'emt', 'aemt', 'paramedic', 'bls', 'acls', 'pals'};
    final finderUri = FireOpsSimLinks.schoolFinder(
      cert: cert,
      state: state,
      path: emsCerts.contains(cert) ? 'ems' : 'fire',
    );
    final focusUri = FireOpsSimLinks.focusDrills(
      cert: cert,
      task: taskId,
      topic: taskId,
    );
    final pathwayId = FireOpsSimLinks.pathwayIdFor(cert);
    final pathwayUri = pathwayId == null
        ? null
        : FireOpsSimLinks.pathwayRoadmap(pathwayId: pathwayId, state: state);

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'FIREOPSSIM COMPANION',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Free study, focus drills, full pathway roadmaps, class-finder links, and official sources for this Task Book item.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => _openExternalUrl(studyUri.toString()),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Study this task'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _openExternalUrl(taskUri.toString()),
              icon: const Icon(Icons.fitness_center_outlined),
              label: const Text('Practice / tools'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _openExternalUrl(focusUri.toString()),
              icon: const Icon(Icons.sports_martial_arts_outlined),
              label: const Text('Open focus drills'),
            ),
          ),
          if (pathwayUri != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _openExternalUrl(pathwayUri.toString()),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Full pathway roadmap'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _openExternalUrl(finderUri.toString()),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Find a class'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final List<TaskBookPracticeToolLink> tools;
  const _PracticeCard({required this.tools});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (tools.isEmpty) {
      return _InfoCard(
        title: 'PRACTICE',
        body:
            'No practice tools linked yet. You can still log practice and add evidence below.',
        tone: _CardTone.neutral,
      );
    }
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRACTICE',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...tools.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final String? externalUrl = switch (t.route) {
                      '/resources?tool=firepumpsim' =>
                        'https://fireopssim.com/fire-pump-training-scenarios.html',
                      '/resources?tool=fireops_calc' =>
                        'https://fireopssim.com/fire-pump-calculator.html',
                      '/resources?tool=hydrant_flow' =>
                        'https://fireopssim.com/hydrant-flow-calculator.html',
                      _ => null,
                    };
                    if (externalUrl != null) {
                      _openExternalUrl(externalUrl);
                      return;
                    }
                    context.push(
                      AppRoutes.resources,
                      extra: {'tool': t.route, 'title': t.title},
                    );
                  },
                  icon: Icon(Icons.build_outlined, color: cs.primary),
                  label: Text(t.title),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcesCard extends StatelessWidget {
  final List<TaskBookResourceLink> resources;
  final List<Resource> extraResources;
  const _ResourcesCard({required this.resources, required this.extraResources});

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty && extraResources.isEmpty) {
      return _InfoCard(
        title: 'REFERENCES',
        body:
            'No reference links yet. Use the Companion card above for skill sheets and references.',
        tone: _CardTone.neutral,
      );
    }
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REFERENCES',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (extraResources.isNotEmpty) ...[
            ...extraResources.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: r.url == null ? null : () => _openExternalUrl(r.url!),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_outlined, color: cs.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            r.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Icon(Icons.open_in_new, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (resources.isNotEmpty) const SizedBox(height: 4),
          ],
          ...resources.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: r.url == null ? null : () => _openExternalUrl(r.url!),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRecordCard extends StatelessWidget {
  final VoidCallback onLogPractice;
  final VoidCallback onAddEvidence;
  const _MyRecordCard({
    required this.onLogPractice,
    required this.onAddEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MY RECORD',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onLogPractice,
              icon: Icon(Icons.add_task, color: cs.onPrimary),
              label: Text(
                'Log Practice',
                style: TextStyle(color: cs.onPrimary),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddEvidence,
              icon: Icon(Icons.fact_check_outlined, color: cs.primary),
              label: const Text('Add Evidence'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep entries professional and non-identifying. Do not store patient names, addresses, DOBs, or other protected information.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionHandoffSheet extends StatelessWidget {
  final String taskTitle;
  final String? qualificationName;

  const _CompletionHandoffSheet({
    required this.taskTitle,
    required this.qualificationName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: FireOpsSemanticColors.completed.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: FireOpsSemanticColors.completed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task complete',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    if ((qualificationName ?? '').isNotEmpty)
                      Text(
                        qualificationName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            taskTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Preserve this accomplishment in your career history while it is fresh. The task, qualification, date, and Task Book links will already be filled in.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Add to Career Record'),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          Text(
            'Task completion is already saved. Adding a career record is optional.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Prefill payload for Personal Log.
