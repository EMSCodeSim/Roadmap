import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/pages/task_book/qualification_task_book_page.dart'
    as legacy;
import 'package:firepath/pages/task_book/requirement_checklist_page.dart';
import 'package:firepath/services/national_task_book_baseline.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

/// Keeps the existing qualification-prep screen intact while making the
/// standards checklist visible from the exact qualification page the user
/// opens from the Task Book.
class QualificationTaskBookChecklistShell extends StatelessWidget {
  final Object? requirement;

  const QualificationTaskBookChecklistShell({
    super.key,
    required this.requirement,
  });

  @override
  Widget build(BuildContext context) {
    final req = requirement is Requirement ? requirement as Requirement : null;
    final state = context.watch<AppState>();
    final goalId = state.roadmap?.goal.id;
    final standard = req == null
        ? null
        : NationalTaskBookBaseline.standardFor(req);

    if (req == null || goalId == null || standard == null) {
      return legacy.QualificationTaskBookPage(requirement: requirement);
    }

    final subTasks = NationalTaskBookBaseline.effectiveSubTasks(
      req,
      state.subTasksFor(goalId: goalId, requirementId: req.id),
    );
    final completed = subTasks.where((item) => item.isDone).length;
    final total = subTasks.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      body: legacy.QualificationTaskBookPage(requirement: req),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.16),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'SKILLS CHECKLIST',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Text(
                    '$completed of $total',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${standard.citation} national baseline • tap below to view and check off each objective.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  key: const Key('qualification-open-national-checklist'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RequirementChecklistPage(
                        goalId: goalId,
                        requirement: req,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.checklist_outlined),
                  label: Text('Open ${req.name} Skills Checklist'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
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
