import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/career_inbox.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';

class CareerInboxPage extends StatefulWidget {
  const CareerInboxPage({super.key});

  @override
  State<CareerInboxPage> createState() => _CareerInboxPageState();
}

class _CareerInboxPageState extends State<CareerInboxPage> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _store.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = CareerInbox.build(app: app, records: _records);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toHome(),
        title: const Text('Career Inbox'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                children: [
                  Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      color: items.isEmpty
                          ? cs.primaryContainer
                          : cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items.isEmpty
                              ? 'You are caught up.'
                              : '${items.length} thing${items.length == 1 ? '' : 's'} need attention',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          items.isEmpty
                              ? 'No urgent credential, Task Book, or career-record gaps were found right now.'
                              : 'Roadmap only surfaces items with a clear next action. Fix the important ones first and keep moving.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    _AllClearCard(
                      onFocus: () => context.push(AppRoutes.dailyFocus),
                    )
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _InboxCard(
                          item: item,
                          onAction: () => _handle(item),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Career Inbox is a planning aid. Verify official certification, promotional, evaluation, and department requirements with the appropriate authority.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _handle(CareerInboxItem item) async {
    switch (item.kind) {
      case CareerInboxKind.chooseGoal:
        context.go(AppRoutes.myPath);
        return;
      case CareerInboxKind.certification:
        final id = item.certificationId;
        if (id != null) {
          await context.push('${AppRoutes.certificationDetail}/$id');
        }
        break;
      case CareerInboxKind.undocumentedCompletion:
        final task = item.task;
        if (task == null || item.goalId == null || item.requirementId == null) {
          return;
        }
        await QuickLogLauncher.open(
          context,
          prefill: LogPrefill(
            title: task.title,
            category: item.qualificationName,
            relatedGoalId: item.goalId,
            relatedRequirementId: item.requirementId,
            relatedTaskId: task.id,
            tags: const ['task-book', 'completed', 'career-inbox'],
          ),
        );
        break;
      case CareerInboxKind.stalledTask:
        final task = item.task;
        if (task == null || item.goalId == null || item.requirementId == null) {
          return;
        }
        await context.push(
          AppRoutes.taskDetail,
          extra: {
            'goalId': item.goalId,
            'requirementId': item.requirementId,
            'qualificationName': item.qualificationName,
            'task': task,
          },
        );
        break;
    }
    if (mounted) await _load();
  }
}

class _InboxCard extends StatelessWidget {
  final CareerInboxItem item;
  final VoidCallback onAction;

  const _InboxCard({required this.item, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final urgent = item.priority <= 1;
    final icon = switch (item.kind) {
      CareerInboxKind.chooseGoal => Icons.route_outlined,
      CareerInboxKind.certification => Icons.verified_outlined,
      CareerInboxKind.undocumentedCompletion => Icons.inventory_2_outlined,
      CareerInboxKind.stalledTask => Icons.schedule_outlined,
    };

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: urgent
              ? cs.error.withValues(alpha: .34)
              : cs.outline.withValues(alpha: .14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: urgent
                      ? cs.errorContainer.withValues(alpha: .65)
                      : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: urgent ? cs.error : cs.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(item.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllClearCard extends StatelessWidget {
  final VoidCallback onFocus;
  const _AllClearCard({required this.onFocus});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_outline, size: 42),
          const SizedBox(height: 10),
          Text(
            'Nothing is blocking your progress.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Use Today’s Focus to keep building the next requirement.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onFocus,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text("Start Today's Focus"),
          ),
        ],
      ),
    );
  }
}
