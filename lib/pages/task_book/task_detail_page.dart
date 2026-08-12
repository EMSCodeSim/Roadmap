import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';

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
        goalId: goalId, requirementId: requirementId, taskId: task.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(task.title.toUpperCase()),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            _StatusCard(
              status: status,
              onChanged: (next) => context.read<AppState>().setTaskStatus(
                    goalId: goalId,
                    requirementId: requirementId,
                    taskId: task.id,
                    status: next,
                    completionSource: next == TaskBookTaskStatus.complete
                        ? TaskBookCompletionSource.selfVerified
                        : null,
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
              emptyText: 'No guidance added yet.',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExpandableListCard(
              title: 'PERFORMANCE TASKS',
              items: task.performanceTasks,
              emptyText: 'No performance breakdown added yet.',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExpandableListCard(
              title: 'SAFETY POINTS',
              items: task.safetyPoints,
              emptyText: 'No safety points added yet.',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExpandableListCard(
              title: 'COMMON MISTAKES',
              items: task.commonMistakes,
              emptyText: 'No common mistakes added yet.',
            ),
            const SizedBox(height: AppSpacing.md),
            _PracticeCard(tools: task.practiceTools),
            const SizedBox(height: AppSpacing.md),
            _ResourcesCard(resources: task.resources),
            const SizedBox(height: AppSpacing.md),
            _MyRecordCard(
              onLogPractice: () => QuickLogLauncher.open(
                context,
                prefill: LogPrefill(
                  title: task.title,
                  category: qualificationName,
                  relatedGoalId: goalId,
                  relatedRequirementId: requirementId,
                  relatedTaskId: task.id,
                  tags: ['task-book', 'practice'],
                ),
              ),
              onAddEvidence: () => context.push(AppRoutes.careerEvidence,
                  extra: EvidencePrefill(
                    title: task.title,
                    relatedGoalId: goalId,
                    relatedRequirementId: requirementId,
                    category: qualificationName,
                    tags: ['task-book', 'evidence'],
                  )),
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoCard(
              title: 'NOTICE',
              body:
                  'FireOps preparation tasks are designed to help organize training and professional development. Always verify certification and performance requirements with your department, state authority, official task book, or certifying organization.',
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
              Text('STATUS',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(label(status),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: TaskBookTaskStatus.values
                .map((s) => ChoiceChip(
                      label: Text(label(s)),
                      selected: s == status,
                      onSelected: (_) => onChanged(s),
                      labelStyle: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ))
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
  const _InfoCard(
      {required this.title, required this.body, required this.tone});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg =
        tone == _CardTone.primary ? cs.primaryContainer : cs.surfaceContainerHighest.withValues(alpha: 0.6);
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
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          Text(body,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.55)),
        ],
      ),
    );
  }
}

class _ExpandableListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final String emptyText;
  const _ExpandableListCard(
      {required this.title, required this.items, required this.emptyText});

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
          tilePadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
          childrenPadding:
              const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 14),
          title: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          children: [
            if (items.isEmpty)
              Text(emptyText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant))
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
                            borderRadius: BorderRadius.circular(99)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.5)),
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
          tone: _CardTone.neutral);
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
          Text('PRACTICE',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          ...tools.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.resources,
                        extra: {'tool': t.route, 'title': t.title}),
                    icon: Icon(Icons.build_outlined, color: cs.primary),
                    label: Text(t.title),
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg))),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _ResourcesCard extends StatelessWidget {
  final List<TaskBookResourceLink> resources;
  const _ResourcesCard({required this.resources});

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return _InfoCard(
          title: 'REFERENCES',
          body:
              'No reference links added yet. You can add department SOP links later as Task Book customization expands.',
          tone: _CardTone.neutral);
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
          Text('REFERENCES',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          ...resources.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: r.url == null
                      ? null
                      : () => context.push(AppRoutes.resources, extra: {
                          'url': r.url,
                          'title': r.title,
                        }),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border:
                          Border.all(color: cs.outline.withValues(alpha: 0.10)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link, color: cs.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _MyRecordCard extends StatelessWidget {
  final VoidCallback onLogPractice;
  final VoidCallback onAddEvidence;
  const _MyRecordCard(
      {required this.onLogPractice, required this.onAddEvidence});

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
          Text('MY RECORD',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onLogPractice,
              icon: Icon(Icons.add_task, color: cs.onPrimary),
              label: Text('Log Practice', style: TextStyle(color: cs.onPrimary)),
              style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg))),
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
                      borderRadius: BorderRadius.circular(AppRadius.lg))),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep entries professional and non-identifying. Do not store patient names, addresses, DOBs, or other protected information.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Prefill payload for Personal Log.