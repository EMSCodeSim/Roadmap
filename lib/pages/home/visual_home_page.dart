import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_inbox.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/needs_attention_engine.dart';
import 'package:firepath/services/smart_next_step.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final department = context.watch<DepartmentInboxController>();
    final roadmap = app.roadmap;
    final hasRoadmap = roadmap != null && roadmap.totalCount > 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _Header(onSettings: () => context.push(AppRoutes.settings)),
            const SizedBox(height: 14),
            _MyStatusCard(app: app, department: department),
            const SizedBox(height: 14),
            _HomeActionCenter(app: app, department: department),
            if (!hasRoadmap) ...[
              const SizedBox(height: 14),
              _ChooseGoalCard(onChooseGoal: () => context.go(AppRoutes.myPath)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MyStatusCard extends StatelessWidget {
  final AppState app;
  final DepartmentInboxController department;

  const _MyStatusCard({required this.app, required this.department});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roadmap = app.roadmap;
    final currentRole = app.profile.currentRoles.isEmpty
        ? 'Not set'
        : app.profile.currentRoles.first;
    final nextTarget = roadmap?.goal.title ?? 'Choose a roadmap';
    final progress =
        roadmap == null ? null : (roadmap.percentComplete * 100).round();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final credentialAttention = app.certifications.where((cert) {
      if (cert.doesNotExpire) return false;
      if (cert.expirationDate == null) return true;
      return cert.expirationDate!.difference(today).inDays <= 60;
    }).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My status',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            _StatusLine(label: 'Current level', value: currentRole),
            _StatusLine(label: 'Next target', value: nextTarget),
            _StatusLine(
              label: 'Credentials needing attention',
              value: '$credentialAttention',
              alert: credentialAttention > 0,
            ),
            _StatusLine(
              label: 'Department actions',
              value: '${department.actionCount}',
              alert: department.actionCount > 0,
            ),
            _StatusLine(
              label: 'Current roadmap progress',
              value: progress == null ? 'Not started' : '$progress%',
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (progress / 100).clamp(0, 1),
                  minHeight: 8,
                  backgroundColor:
                      cs.surfaceContainerHighest.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String label;
  final String value;
  final bool alert;

  const _StatusLine({
    required this.label,
    required this.value,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: alert ? cs.error : cs.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionCenter extends StatefulWidget {
  final AppState app;
  final DepartmentInboxController department;

  const _HomeActionCenter({
    required this.app,
    required this.department,
  });

  @override
  State<_HomeActionCenter> createState() => _HomeActionCenterState();
}

class _HomeActionCenterState extends State<_HomeActionCenter> {
  final CareerRecordStore _recordStore = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final records = await _recordStore.load();
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final app = widget.app;
    final department = widget.department;
    final attention = _buildAttention(app, department);
    final next = _resolveNext(app, attention);

    return Column(
      children: [
        _WhatNextCard(item: next),
        const SizedBox(height: 14),
        _NeedsMyAttentionCard(items: attention),
      ],
    );
  }

  List<_HomeAttentionItem> _buildAttention(
    AppState app,
    DepartmentInboxController department,
  ) {
    final items = <_HomeAttentionItem>[];

    for (final assignment in department.urgentAssignments) {
      final returned = assignment.sections
          .expand((section) => section.requirements)
          .any((requirement) =>
              requirement.correctionNotes.trim().isNotEmpty &&
              !requirement.isFullyApproved);
      items.add(
        _HomeAttentionItem(
          id: 'dept-assignment:${assignment.id}',
          priority: returned ? 0 : 1,
          title: assignment.taskBookTitle,
          detail: returned
              ? 'Returned by your department — correction needed.'
              : 'Department assignment is overdue.',
          icon: returned
              ? Icons.assignment_return_outlined
              : Icons.schedule_rounded,
          actionLabel: 'Open Department',
          onTap: (context) => context.go(AppRoutes.department),
        ),
      );
    }

    for (final action in department.inbox?.needsAction ?? const []) {
      items.add(
        _HomeAttentionItem(
          id: 'dept-action:${action.id}',
          priority: 2,
          title: action.title,
          detail: action.subtitle.isEmpty
              ? 'Department action is waiting for you.'
              : action.subtitle,
          icon: Icons.fact_check_outlined,
          actionLabel: 'Open Department',
          onTap: (context) => context.go(AppRoutes.department),
        ),
      );
    }

    final needs = NeedsAttentionEngine.analyze(app: app, records: _records);
    for (final item in needs) {
      items.add(
        _HomeAttentionItem(
          id: 'needs:${item.id}',
          priority: switch (item.urgency) {
            NeedsAttentionUrgency.now => 3,
            NeedsAttentionUrgency.soon => 5,
            NeedsAttentionUrgency.later => 8,
          },
          title: item.title,
          detail: item.detail,
          icon: item.certificationId != null
              ? Icons.workspace_premium_outlined
              : Icons.route_outlined,
          actionLabel: item.actionLabel,
          onTap: (context) {
            if (item.certificationId != null) {
              context.go(AppRoutes.certifications);
              return;
            }
            final requirementId = item.requirementId;
            final roadmap = app.roadmap;
            if (requirementId != null && roadmap != null) {
              final matches = roadmap.all
                  .where((entry) => entry.requirement.id == requirementId);
              if (matches.isNotEmpty) {
                AppRouter.openRequirement(
                  context,
                  matches.first.requirement,
                  goalId: roadmap.goal.id,
                );
                return;
              }
            }
            context.go(AppRoutes.myPath);
          },
        ),
      );
    }

    final careerInbox = CareerInbox.build(app: app, records: _records);
    for (final item in careerInbox) {
      if (items.any((entry) =>
          entry.title.toLowerCase() == item.title.toLowerCase())) {
        continue;
      }
      items.add(
        _HomeAttentionItem(
          id: 'career:${item.id}',
          priority: 10 + item.priority,
          title: item.title,
          detail: item.detail,
          icon: Icons.inbox_outlined,
          actionLabel: item.actionLabel,
          onTap: (context) {
            if (item.certificationId != null) {
              context.go(AppRoutes.certifications);
            } else if (item.requirementId != null) {
              context.go(AppRoutes.myPath);
            } else {
              context.go(AppRoutes.personalLog);
            }
          },
        ),
      );
    }

    items.sort((a, b) {
      final p = a.priority.compareTo(b.priority);
      if (p != 0) return p;
      return a.title.compareTo(b.title);
    });
    return items.take(8).toList(growable: false);
  }

  _HomeAttentionItem _resolveNext(
    AppState app,
    List<_HomeAttentionItem> attention,
  ) {
    final careerBlocking = attention
        .where((item) => item.priority <= 1)
        .toList(growable: false);
    if (careerBlocking.isNotEmpty) return careerBlocking.first;

    final smart = SmartNextStepEngine.resolve(app);
    final requirement = smart?.requirement;
    if (requirement != null && smart != null) {
      return _HomeAttentionItem(
        id: 'roadmap-next:${requirement.id}',
        priority: 20,
        title: smart.actionTitle,
        detail: smart.actionDetail,
        icon: _todayActionIcon(requirement.type),
        actionLabel: smart.actionLabel,
        onTap: (context) => AppRouter.openRequirement(
          context,
          requirement,
          goalId: app.roadmap?.goal.id,
        ),
      );
    }

    if (app.roadmap == null) {
      return _HomeAttentionItem(
        id: 'build-roadmap',
        priority: 30,
        title: 'Build your roadmap',
        detail: 'Choose what you are working toward so Responder Roadmap can guide the next step.',
        icon: Icons.route_outlined,
        actionLabel: 'Build My Roadmap',
        onTap: (context) => context.go(AppRoutes.myPath),
      );
    }

    return _HomeAttentionItem(
      id: 'caught-up',
      priority: 99,
      title: 'You are caught up',
      detail: 'No urgent department, credential, or roadmap action is waiting right now.',
      icon: Icons.check_circle_outline_rounded,
      actionLabel: 'Open My Roadmap',
      onTap: (context) => context.go(AppRoutes.myPath),
    );
  }
}

IconData _todayActionIcon(RequirementType type) => switch (type) {
      RequirementType.certification => Icons.workspace_premium_outlined,
      RequirementType.trainingCourse || RequirementType.course =>
        Icons.school_outlined,
      RequirementType.promotionalTest => Icons.event_available_outlined,
      RequirementType.practical => Icons.fact_check_outlined,
      RequirementType.interview => Icons.record_voice_over_outlined,
      RequirementType.education => Icons.school_outlined,
      RequirementType.taskBook => Icons.menu_book_outlined,
      RequirementType.experience => Icons.trending_up_rounded,
      RequirementType.numericProgress => Icons.add_task_outlined,
      RequirementType.custom => Icons.route_outlined,
    };

class _WhatNextCard extends StatelessWidget {
  final _HomeAttentionItem item;

  const _WhatNextCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'What should I do next?',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              item.detail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => item.onTap(context),
              icon: Icon(item.icon),
              label: Text(item.actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedsMyAttentionCard extends StatelessWidget {
  final List<_HomeAttentionItem> items;

  const _NeedsMyAttentionCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visible = items.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  visible.isEmpty
                      ? Icons.check_circle_outline_rounded
                      : Icons.notifications_active_outlined,
                  color: visible.isEmpty ? cs.primary : cs.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Needs My Attention',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${items.length}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nothing needs action right now.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...visible.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(item.icon),
                  title: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => item.onTap(context),
                ),
              ),
            if (items.length > visible.length)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '+${items.length - visible.length} more items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeAttentionItem {
  final String id;
  final int priority;
  final String title;
  final String detail;
  final IconData icon;
  final String actionLabel;
  final void Function(BuildContext context) onTap;

  const _HomeAttentionItem({
    required this.id,
    required this.priority,
    required this.title,
    required this.detail,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });
}

class _Header extends StatelessWidget {
  final VoidCallback onSettings;

  const _Header({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FirefighterRoadmapWordmark(),
              const SizedBox(height: 4),
              Text(
                'Know where you are. Know what comes next.',
                style: t.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
          ),
          child: IconButton(
            tooltip: 'Settings and profile',
            onPressed: onSettings,
            icon: Icon(Icons.settings_outlined, color: cs.onSurface),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose what you are working toward',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick a starting point and target. You can skip, replace, or customize stages later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onChooseGoal,
              icon: const Icon(Icons.route_outlined),
              label: const Text('Build My Roadmap'),
            ),
          ],
        ),
      ),
    );
  }
}
