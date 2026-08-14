from pathlib import Path

path = Path('lib/pages/home/visual_home_page.dart')
text = path.read_text()

old = """            _CurrentLevelCard(\n              level: currentLevel,\n              serviceType: profile.serviceType,\n              yearsOfService: profile.yearsOfService,\n              stateCode: profile.state,\n              onTap: () => _showEditCurrentLevelSheet(context, state),\n            ),\n            const SizedBox(height: 12),\n            _GoalCard(\n              goalTitle: roadmap?.goal.title,\n              targetDate: profile.careerPlan.targetDate,\n              completed: roadmap?.completedCount ?? 0,\n              total: roadmap?.totalCount ?? 0,\n              nextStep: roadmap?.nextStep?.requirement.name,\n              timelineStatus: timelinePlan?.status,\n              onTap: () => context.go(AppRoutes.myPath),\n            ),\n"""

new = """            _CareerCommandCard(\n              goalTitle: roadmap?.goal.title,\n              targetDate: profile.careerPlan.targetDate,\n              completed: roadmap?.completedCount ?? 0,\n              total: roadmap?.totalCount ?? 0,\n              nextStep: roadmap?.nextStep?.requirement.name,\n              timelineStatus: timelinePlan?.status,\n              onOpenTaskBook: () => context.go(AppRoutes.myPath),\n              onQuickLog: () => QuickLogLauncher.open(context),\n            ),\n            const SizedBox(height: 12),\n            _CurrentLevelCard(\n              level: currentLevel,\n              serviceType: profile.serviceType,\n              yearsOfService: profile.yearsOfService,\n              stateCode: profile.state,\n              onTap: () => _showEditCurrentLevelSheet(context, state),\n            ),\n"""

if old not in text:
    raise SystemExit('Home card block not found; refusing to patch an unexpected file.')
text = text.replace(old, new, 1)

anchor = "class _GoalCard extends StatelessWidget {"
if anchor not in text:
    raise SystemExit('Goal card anchor not found; refusing to patch an unexpected file.')

career_card = r'''class _CareerCommandCard extends StatelessWidget {
  final String? goalTitle;
  final DateTime? targetDate;
  final int completed;
  final int total;
  final String? nextStep;
  final TimelineStatus? timelineStatus;
  final VoidCallback onOpenTaskBook;
  final VoidCallback onQuickLog;

  const _CareerCommandCard({
    required this.goalTitle,
    required this.targetDate,
    required this.completed,
    required this.total,
    required this.nextStep,
    required this.timelineStatus,
    required this.onOpenTaskBook,
    required this.onQuickLog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasGoal = goalTitle != null;
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final readiness = (progress * 100).round();

    final statusText = switch (timelineStatus) {
      TimelineStatus.atRisk => 'Timeline at risk',
      TimelineStatus.needsAttention => 'Needs attention',
      TimelineStatus.noTargetDate when hasGoal => 'Add a target date',
      _ when hasGoal && total > 0 && completed >= total => 'Ready for the next goal',
      _ when hasGoal => 'On your career road',
      _ => 'Build your career road',
    };

    final guidance = switch (timelineStatus) {
      TimelineStatus.atRisk =>
        'Your target date is getting tight. Focus on the next requirement before adding lower-priority work.',
      TimelineStatus.needsAttention =>
        'Your plan is still reachable, but completing the next requirement will keep your timeline healthy.',
      _ when hasGoal && nextStep != null =>
        'This is the highest-priority incomplete requirement on your current career road.',
      _ when hasGoal && total > 0 && completed >= total =>
        'You have completed the requirements currently mapped to this goal. Review your record and choose what comes next.',
      _ when hasGoal =>
        'Open your Task Book to review requirements and choose the best next action.',
      _ =>
        'Choose where you want to go next and FireOps will turn that goal into an actionable Task Book.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 8),
            color: cs.shadow.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.explore_outlined, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAREER READINESS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasGoal ? goalTitle! : 'Choose your next destination',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasGoal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$readiness%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          if (hasGoal) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$completed of $total mapped requirements complete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (targetDate != null)
                  Text(
                    'Target ${_formatMonthYear(targetDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasGoal ? 'YOUR NEXT BEST STEP' : 'START HERE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasGoal
                      ? (nextStep ?? 'Review your completed Task Book')
                      : 'Choose a career goal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  guidance,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.insights_outlined, size: 17, color: cs.onSurfaceVariant),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: onOpenTaskBook,
                  icon: Icon(hasGoal ? Icons.menu_book_outlined : Icons.flag_outlined),
                  label: Text(hasGoal ? 'Open Task Book' : 'Choose Goal'),
                ),
              ),
              if (hasGoal) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: onQuickLog,
                    icon: const Icon(Icons.add_task_outlined),
                    label: const Text('Log Progress'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

'''

text = text.replace(anchor, career_card + anchor, 1)
path.write_text(text)
print('Applied Career Readiness + Next Best Step home update.')
