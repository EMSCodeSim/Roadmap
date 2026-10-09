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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.go(AppRoutes.myPath),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(roadmap == null ? 'Build My Roadmap' : 'View My Roadmap'),
              ),
            ),
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
    final smartOptions = SmartNextStepEngine.alternatives(app, limit: 3);
    final next = _resolveNext(app, attention, smartOptions);
    final blocking = attention.any((item) => item.priority <= 1);
    final alternatives = <_HomeAttentionItem>[];
    if (!blocking && smartOptions.isNotEmpty) {
      final primary = smartOptions.first;
      final secondary = primary.secondaryFocusTitle;
      if (secondary != null && secondary.trim().isNotEmpty) {
        alternatives.add(_secondaryTaskItem(app, primary, secondary));
      }
      for (final decision in smartOptions.skip(1)) {
        if (alternatives.length >= 2) break;
        alternatives.add(_smartDecisionItem(app, decision));
      }
      if (alternatives.length < 2) {
        alternatives.add(_maintenanceItem(app));
      }
    }

    return Column(
      children: [
        _WhatNextCard(item: next, alternatives: alternatives),
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
    List<SmartNextStepDecision> smartOptions,
  ) {
    final careerBlocking = attention
        .where((item) => item.priority <= 1)
        .toList(growable: false);
    if (careerBlocking.isNotEmpty) return careerBlocking.first;

    if (smartOptions.isNotEmpty) {
      return _smartDecisionItem(app, smartOptions.first);
    }

    if (app.roadmap == null) {
      return _HomeAttentionItem(
        id: 'build-roadmap',
        priority: 30,
        title: 'Build My Next Steps',
        detail: 'Choose where you are now and where you want to go. We’ll build an editable starting roadmap you can add to as you confirm official requirements.',
        icon: Icons.route_outlined,
        actionLabel: 'Build My Next Steps',
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
  _HomeAttentionItem _secondaryTaskItem(
    AppState app,
    SmartNextStepDecision decision,
    String title,
  ) {
    final requirement = decision.requirement;
    return _HomeAttentionItem(
      id: 'roadmap-secondary:${requirement.id}:$title',
      priority: 21,
      title: title,
      detail:
          'Another useful suggested step for ${requirement.name}. Do this if the primary step is not practical today.',
      icon: Icons.checklist_rounded,
      actionLabel: 'Open My Roadmap',
      onTap: (context) => AppRouter.openRequirement(
        context,
        requirement,
        goalId: app.roadmap?.goal.id,
      ),
    );
  }

  _HomeAttentionItem _maintenanceItem(AppState app) {
    final goalId = app.roadmap?.goal.id ?? '';
    final ems = goalId.startsWith('ems_');
    return _HomeAttentionItem(
      id: ems ? 'maintenance-ems-protocols' : 'maintenance-fire-sops',
      priority: 40,
      title: ems
          ? 'Review one local EMS protocol'
          : 'Review one department SOP / SOG',
      detail: ems
          ? 'Pick a protocol you use on calls, review the current local version, and note one decision point, medication, or change you want to remember.'
          : 'Pick an operational SOP/SOG you use on shift, review the current local version, and note one action, limitation, or change you want to remember.',
      icon: Icons.menu_book_outlined,
      actionLabel: 'Open resources',
      onTap: (context) => context.push(AppRoutes.resources),
    );
  }

  _HomeAttentionItem _smartDecisionItem(
    AppState app,
    SmartNextStepDecision decision,
  ) {
    final requirement = decision.requirement;
    return _HomeAttentionItem(
      id: 'roadmap-next:${requirement.id}',
      priority: 20,
      title: decision.actionTitle,
      detail: decision.actionDetail,
      icon: _todayActionIcon(requirement.type),
      actionLabel: decision.actionLabel,
      onTap: (context) => AppRouter.openRequirement(
        context,
        requirement,
        goalId: app.roadmap?.goal.id,
      ),
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
  final List<_HomeAttentionItem> alternatives;

  const _WhatNextCard({
    required this.item,
    this.alternatives = const [],
  });

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.bolt_rounded, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR NEXT STEP',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'What should I work on next?',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
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
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Also useful today',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              ...alternatives.take(2).map(
                    (alternative) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(alternative.icon, size: 20),
                      title: Text(
                        alternative.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        alternative.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => alternative.onTap(context),
                    ),
                  ),
            ],
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
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 19),
                  ),
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
              'Choose where you are and where you want to go. We’ll create an editable starting roadmap you can build on as you confirm official requirements.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onChooseGoal,
              icon: const Icon(Icons.route_outlined),
              label: const Text('Build My Next Steps'),
            ),
          ],
        ),
      ),
    );
  }
}
