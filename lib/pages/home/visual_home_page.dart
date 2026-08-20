import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/home_quick_action.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/career_stats.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/certification_urgency.dart';
import 'package:firepath/services/home_quick_actions_store.dart';
import 'package:firepath/services/timeline_planner.dart';
import 'package:firepath/services/task_book_setup_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/quick_log_tracker.dart';
import 'package:firepath/services/quick_log_preferences_store.dart';
import 'package:firepath/pages/profile/us_state_picker_sheet.dart';
import 'package:firepath/widgets/progress_ring.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';

class VisualHomePage extends StatefulWidget {
  const VisualHomePage({super.key});

  @override
  State<VisualHomePage> createState() => _VisualHomePageState();
}

class _VisualHomePageState extends State<VisualHomePage> {
  bool _promptQueued = false;
  final HomeQuickActionsStore _quickActionsStore = HomeQuickActionsStore();
  Future<List<HomeQuickAction>>? _quickActionsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_promptQueued) return;
    _promptQueued = true;
    _quickActionsFuture ??= _quickActionsStore.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybePromptForMissingState();
    });
  }

  void _refreshQuickActions() => setState(() => _quickActionsFuture = _quickActionsStore.load());

  Future<void> _maybePromptForMissingState() async {
    final state = context.read<AppState>();
    if (!state.onboardingComplete) return;
    if ((state.profile.state ?? '').trim().isNotEmpty) return;

    final store = TaskBookSetupStore();
    final dismissed = await store.missingStatePromptDismissed();
    if (dismissed) return;
    if (!mounted) return;

    final cs = Theme.of(context).colorScheme;
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Help us improve your Task Book',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'What state do you primarily work in?',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: () async {
                    final value = await UsStatePickerSheet.pick(
                      sheetContext,
                      selectedCode: null,
                    );
                    if (sheetContext.mounted) sheetContext.pop(value);
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('Select State'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => sheetContext.pop(null),
                  child: const Text('Skip for Now'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    await store.setMissingStatePromptDismissed(true);
    if (picked == null) return;
    await state.updateProfile(state.profile.copyWith(state: picked));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roadmap = state.roadmap;
    final profile = state.profile;
    final timelinePlan = roadmap == null
        ? null
        : CareerTimelinePlanner.build(state);

    final urgentCerts = CertificationUrgency.urgent(
      state.certifications,
      withinDays: 90,
    );
    final hasCertUrgency = urgentCerts.isNotEmpty;

    final nextStepLabel = roadmap?.nextStep?.requirement.name;
    final hasNextActions = (nextStepLabel ?? '').trim().isNotEmpty ||
        urgentCerts.take(2).isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 690;
            final edge = AppSpacing.md;
            final sectionGap = compact ? AppSpacing.md : AppSpacing.lg;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    edge,
                    compact ? AppSpacing.sm : AppSpacing.md,
                    edge,
                    AppSpacing.md,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _GraphicHeader(
                          compact: compact,
                          onSettings: () => context.push(AppRoutes.settings),
                        ),
                        SizedBox(height: sectionGap),

                        // 1) Next level / readiness hero
                        _NextLevelHeroCard(
                          goalTitle: roadmap?.goal.title,
                          targetDate: profile.careerPlan.targetDate,
                          completed: roadmap?.completedCount ?? 0,
                          total: roadmap?.totalCount ?? 0,
                          nextStep: nextStepLabel,
                          timelineStatus: timelinePlan?.status,
                          onOpenTaskBook: () => context.go(AppRoutes.myPath),
                        ),

                        // 2) What needs attention now
                        if (hasCertUrgency || hasNextActions) ...[
                          SizedBox(height: sectionGap),
                          _HomeSectionHeader(
                            title: 'Needs attention',
                            subtitle: 'Fast actions that keep your path valid.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (hasCertUrgency)
                            _ExpiringCertsMiniPanel(
                              items: urgentCerts.take(3).toList(),
                              compact: true,
                            ),
                          if (hasCertUrgency && hasNextActions)
                            const SizedBox(height: AppSpacing.sm),
                          if (hasNextActions)
                            _NextThreeActionsPanel(
                              nextStepLabel: nextStepLabel,
                              urgentCerts: urgentCerts,
                              onOpenTaskBook: () => context.go(AppRoutes.myPath),
                              compact: true,
                            ),
                        ],

                        // 3) Quick tools
                        SizedBox(height: sectionGap),
                        _HomeSectionHeader(
                          title: 'Quick tools',
                          subtitle: 'Log progress and keep momentum.',
                          trailing: TextButton.icon(
                            onPressed: () async {
                              final current = await (_quickActionsFuture ?? _quickActionsStore.load());
                              if (!context.mounted) return;
                              await _showEditQuickActionsSheet(context, current);
                              if (!mounted) return;
                              _refreshQuickActions();
                            },
                            icon: const Icon(Icons.tune_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FutureBuilder<List<HomeQuickAction>>(
                          future: _quickActionsFuture,
                          builder: (context, snapshot) {
                            final actions = snapshot.data ?? HomeQuickActionsStore.defaults;
                            return _HomeQuickActionsGrid(
                              compact: compact,
                              actions: actions,
                              onRunAction: (action) => _runQuickAction(context, action),
                            );
                          },
                        ),
                        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Future<void> _showEditCurrentLevelSheet(
    BuildContext context,
    AppState state,
  ) async {
    final profile = state.profile;
    final commonRoles = FireOpsCatalog.commonRoles
        .where((role) => role != 'Other / Custom')
        .toList();
    final selectedRoles = profile.currentRoles.toSet();
    var serviceType = profile.serviceType;
    var stateCode = profile.state;
    final yearsController = TextEditingController(
      text: profile.yearsOfService?.toString() ?? '',
    );
    final customRoleController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final customRoles = selectedRoles
                .where((role) => !commonRoles.contains(role))
                .toList();

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.88,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit current level',
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep this current as your role or assignment changes.',
                        style: Theme.of(sheetContext).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            Text(
                              'Current role',
                              style: Theme.of(sheetContext).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...commonRoles.map(
                                  (role) => FilterChip(
                                    label: Text(role),
                                    selected: selectedRoles.contains(role),
                                    onSelected: (selected) {
                                      setSheetState(() {
                                        if (selected) {
                                          selectedRoles.add(role);
                                        } else {
                                          selectedRoles.remove(role);
                                        }
                                      });
                                    },
                                  ),
                                ),
                                ...customRoles.map(
                                  (role) => FilterChip(
                                    label: Text(role),
                                    selected: true,
                                    onSelected: (selected) {
                                      if (!selected) {
                                        setSheetState(
                                          () => selectedRoles.remove(role),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: customRoleController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Custom role',
                                      hintText: 'Example: Acting Engineer',
                                    ),
                                    onSubmitted: (_) => _addCustomRole(
                                      customRoleController,
                                      selectedRoles,
                                      setSheetState,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: IconButton.filledTonal(
                                    tooltip: 'Add custom role',
                                    onPressed: () => _addCustomRole(
                                      customRoleController,
                                      selectedRoles,
                                      setSheetState,
                                    ),
                                    icon: const Icon(Icons.add),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            DropdownButtonFormField<String?>(
                              value: serviceType,
                              decoration: const InputDecoration(
                                labelText: 'Service type',
                              ),
                              items: const [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Not set'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'Volunteer',
                                  child: Text('Volunteer'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'Career',
                                  child: Text('Career'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'Combination',
                                  child: Text('Combination'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'Paid-on-Call',
                                  child: Text('Paid-on-Call'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'Seasonal',
                                  child: Text('Seasonal'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],
                              onChanged: (value) {
                                setSheetState(() => serviceType = value);
                              },
                            ),
                            const SizedBox(height: 14),
                            _StatePickerRow(
                              code: stateCode,
                              onTap: () async {
                                final picked = await UsStatePickerSheet.pick(
                                  sheetContext,
                                  selectedCode: stateCode,
                                );
                                if (picked == null) return;
                                if (picked != stateCode) {
                                  ScaffoldMessenger.of(
                                    sheetContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Changing your state can update Task Book recommendations and cert requirements.',
                                      ),
                                    ),
                                  );
                                }
                                setSheetState(() => stateCode = picked);
                              },
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: yearsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Years of service',
                                hintText: 'Optional',
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: selectedRoles.isEmpty
                              ? null
                              : () async {
                                  final rawYears = yearsController.text.trim();
                                  final years = rawYears.isEmpty
                                      ? null
                                      : int.tryParse(rawYears);
                                  if (rawYears.isNotEmpty &&
                                      (years == null ||
                                          years < 0 ||
                                          years > 80)) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Enter years of service from 0 to 80.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final updated = UserProfile(
                                    currentRoles: selectedRoles.toList(),
                                    primaryGoalId: profile.primaryGoalId,
                                    targetDate: profile.targetDate,
                                    careerPlan: profile.careerPlan,
                                    yearsOfService: years,
                                    serviceType: serviceType,
                                    departmentName: profile.departmentName,
                                    state: stateCode,
                                    createdAt: profile.createdAt,
                                    updatedAt: DateTime.now(),
                                  );
                                  await state.updateProfile(updated);
                                  if (sheetContext.mounted) {
                                    sheetContext.pop();
                                  }
                                },
                          child: const Text('Save current level'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    yearsController.dispose();
    customRoleController.dispose();
  }

  static void _addCustomRole(
    TextEditingController controller,
    Set<String> selectedRoles,
    StateSetter setSheetState,
  ) {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    setSheetState(() {
      selectedRoles.add(value);
      controller.clear();
    });
  }

  static Future<void> _showCertMatchSheet(
    BuildContext context,
    AppState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final matches = state.pendingCertMatches;
        final defs = FireOpsCatalog.certificationById();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Review certification matches',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Confirm these so your certifications count correctly toward your career goal.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ...matches.map((match) {
                  final suggested = defs[match.suggestedDefinitionId];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.userText,
                            style: Theme.of(sheetContext).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Match to: ${suggested?.displayName ?? match.suggestedDefinitionId}',
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await state.confirmCertificationMatch(
                                      userText: match.userText,
                                      suggestedDefinitionId:
                                          match.suggestedDefinitionId,
                                      accepted: false,
                                    );
                                    if (sheetContext.mounted) {
                                      sheetContext.pop();
                                    }
                                  },
                                  child: const Text('Not a match'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () async {
                                    await state.confirmCertificationMatch(
                                      userText: match.userText,
                                      suggestedDefinitionId:
                                          match.suggestedDefinitionId,
                                      accepted: true,
                                    );
                                    if (sheetContext.mounted) {
                                      sheetContext.pop();
                                    }
                                  },
                                  child: const Text('Confirm'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditQuickActionsSheet(
    BuildContext context,
    List<HomeQuickAction> current,
  ) async {
    final cs = Theme.of(context).colorScheme;
    var working = current.toList(growable: true);

    final result = await showModalBottomSheet<List<HomeQuickAction>?> (
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> addAction() async {
              final picked = await _showAddQuickActionSheet(sheetContext, working);
              if (picked == null) return;
              setSheetState(() => working.add(picked));
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Quick actions',
                      style: Theme.of(sheetContext)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    'Pin the buttons you actually use. Drag to reorder.',
                    style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      itemCount: working.length,
                      onReorder: (oldIndex, newIndex) {
                        setSheetState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = working.removeAt(oldIndex);
                          working.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final action = working[index];
                        final title = _quickActionTitle(action);
                        final subtitle = _quickActionSubtitle(action);
                        final icon = _quickActionIcon(action);
                        return ListTile(
                          key: ValueKey('qa_${action.type.name}_${action.trackerKey ?? index}'),
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(icon, color: cs.onSurfaceVariant),
                          ),
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: () => setSheetState(() => working.removeAt(index)),
                                icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(Icons.drag_handle, color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: addAction,
                      icon: const Icon(Icons.add),
                      label: const Text('Add quick action'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () => sheetContext.pop(working),
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) return;
    await _quickActionsStore.save(result);
  }

  Future<HomeQuickAction?> _showAddQuickActionSheet(
    BuildContext context,
    List<HomeQuickAction> current,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final prefs = await QuickLogPreferencesStore().load();
    final pinnedKeys = prefs.pinnedIds;

    final baseOptions = <HomeQuickAction>[
      if (!current.any((a) => a.type == HomeQuickActionType.quickLog))
        const HomeQuickAction(type: HomeQuickActionType.quickLog),
      if (!current.any((a) => a.type == HomeQuickActionType.dailyFocus))
        const HomeQuickAction(type: HomeQuickActionType.dailyFocus),
      if (!current.any((a) => a.type == HomeQuickActionType.openTaskBook))
        const HomeQuickAction(type: HomeQuickActionType.openTaskBook),
      if (!current.any((a) => a.type == HomeQuickActionType.openCerts))
        const HomeQuickAction(type: HomeQuickActionType.openCerts),
      if (!current.any((a) => a.type == HomeQuickActionType.openResources))
        const HomeQuickAction(type: HomeQuickActionType.openResources),
    ];

    final templateOptions = pinnedKeys
        .where((key) => current.every((a) => a.type != HomeQuickActionType.quickLogTemplate || a.trackerKey != key))
        .map((key) {
          final builtIn = QuickLogCatalog.byKey(key);
          final fromCustom = prefs.customTemplates.where((t) => t.id == key).map((t) => t.title).firstOrNull;
          return HomeQuickAction(
            type: HomeQuickActionType.quickLogTemplate,
            trackerKey: key,
            titleOverride: builtIn?.title ?? fromCustom,
          );
        })
        .toList();

    return showModalBottomSheet<HomeQuickAction?>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add quick action',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                'Choose what to pin on Home.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              ...baseOptions.map((action) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_quickActionIcon(action), color: cs.primary),
                    title: Text(_quickActionTitle(action)),
                    subtitle: Text(_quickActionSubtitle(action)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => sheetContext.pop(action),
                  )),
              if (templateOptions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Quick Log templates',
                    style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 6),
                ...templateOptions.take(8).map((action) {
                  final title = _quickActionTitle(action);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.bookmark_add_outlined, color: cs.primary),
                    title: Text(title),
                    subtitle: const Text('One-tap log'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => sheetContext.pop(action),
                  );
                }),
              ],
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  static IconData _quickActionIcon(HomeQuickAction action) => switch (action.type) {
        HomeQuickActionType.quickLogTemplate => Icons.bookmark_add_outlined,
        _ => action.type.icon,
      };

  static String _quickActionTitle(HomeQuickAction action) {
    if (action.type != HomeQuickActionType.quickLogTemplate) return action.type.label;
    return action.titleOverride?.trim().isNotEmpty == true
        ? action.titleOverride!.trim()
        : (QuickLogCatalog.byKey(action.trackerKey ?? '')?.title ?? 'Quick Log');
  }

  static String _quickActionSubtitle(HomeQuickAction action) {
    if (action.type != HomeQuickActionType.quickLogTemplate) return action.type.detail;
    return 'One-tap log';
  }

  static Future<void> _runQuickAction(BuildContext context, HomeQuickAction action) async {
    switch (action.type) {
      case HomeQuickActionType.quickLog:
        // Home entry point: always land on categories (no task-book prefill).
        await QuickLogLauncher.open(context);
        return;
      case HomeQuickActionType.dailyFocus:
        context.push(AppRoutes.dailyFocus);
        return;
      case HomeQuickActionType.openTaskBook:
        context.go(AppRoutes.myPath);
        return;
      case HomeQuickActionType.openCerts:
        context.push(AppRoutes.certifications);
        return;
      case HomeQuickActionType.openResources:
        context.push(AppRoutes.resources);
        return;
      case HomeQuickActionType.quickLogTemplate:
        final trackerKey = (action.trackerKey ?? '').trim();
        if (trackerKey.isEmpty) {
          await QuickLogLauncher.open(context);
          return;
        }
        await QuickLogLauncher.open(
          context,
          prefill: LogPrefill(
            title: action.titleOverride?.trim().isNotEmpty == true
                ? action.titleOverride!.trim()
                : (QuickLogCatalog.byKey(trackerKey)?.title ?? 'Quick Log'),
            category: null,
            relatedGoalId: null,
            relatedRequirementId: null,
            relatedTaskId: null,
            tags: const <String>[],
            trackerKey: trackerKey,
          ),
        );
        return;
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _StatePickerRow extends StatelessWidget {
  final String? code;
  final VoidCallback onTap;
  const _StatePickerRow({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = FireOpsCatalog.stateNameForCode(code) ?? 'Select state';
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Icon(Icons.public, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'State',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.expand_more, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraphicHeader extends StatelessWidget {
  final bool compact;
  final VoidCallback onSettings;
  const _GraphicHeader({required this.compact, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: compact ? 86 : 106,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [FireOpsSemanticColors.headerDark, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(right: -28, top: -40, child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: cs.onSecondary.withValues(alpha: .07)),
            )),
            Positioned(right: 48, bottom: -52, child: Container(
              width: 105, height: 105,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: .18)),
            )),
            Padding(
              padding: EdgeInsets.fromLTRB(18, compact ? 12 : 16, 12, compact ? 12 : 16),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.onSecondary.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('YOUR FIRE SERVICE CAREER',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSecondary, fontWeight: FontWeight.w900,
                          letterSpacing: .65)),
                    ),
                    const SizedBox(height: 5),
                    FirefighterRoadmapWordmark(
                      foregroundColor: cs.onSecondary,
                      iconSize: 20,
                      gap: 10,
                      textStyle: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(
                        color: cs.onSecondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 4),
                      Text('PLAN  •  WORK  •  RECORD  •  ADVANCE',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSecondary.withValues(alpha: .82),
                          fontWeight: FontWeight.w800, letterSpacing: .35)),
                    ],
                  ],
                )),
                IconButton(
                  onPressed: onSettings,
                  tooltip: 'Settings',
                  style: IconButton.styleFrom(
                    foregroundColor: cs.onSecondary,
                    backgroundColor: cs.onSecondary.withValues(alpha: .10),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                ),
                const SizedBox(width: 8),
                Container(
                  width: compact ? 64 : 78,
                  height: compact ? 64 : 78,
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.onSecondary.withValues(alpha: 0.20),
                      width: 1,
                    ),
                  ),
                  child: const _RoadmapBannerIcon(),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapBannerIcon extends StatelessWidget {
  const _RoadmapBannerIcon();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Center(
        child: FirefighterRoadmapHeaderIcon(size: 34, tint: cs.onSecondary),
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const _HomeSectionHeader({required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _HomeQuickActionsGrid extends StatelessWidget {
  final bool compact;
  final List<HomeQuickAction> actions;
  final ValueChanged<HomeQuickAction> onRunAction;

  const _HomeQuickActionsGrid({required this.compact, required this.actions, required this.onRunAction});

  @override
  Widget build(BuildContext context) {
    final visible = actions.where((a) => a.isValid).toList();
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    // Keep the Home layout calm: a small 2-column grid that grows as needed.
    final crossAxisCount = 2;
    final tileHeight = compact ? 74.0 : 88.0;
    final rowCount = (visible.length / crossAxisCount).ceil().clamp(1, 3);
    final height = rowCount * tileHeight + (rowCount - 1) * 10;

    return SizedBox(
      height: height,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: compact ? 2.55 : 2.25,
        ),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final action = visible[index];
          final isPrimary = action.type == HomeQuickActionType.quickLog;
          return _HomeActionTile(
            icon: _VisualHomePageState._quickActionIcon(action),
            label: _VisualHomePageState._quickActionTitle(action).toUpperCase(),
            detail: _VisualHomePageState._quickActionSubtitle(action),
            onTap: () => onRunAction(action),
            emphasized: isPrimary,
          );
        },
      ),
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool emphasized;

  const _HomeActionTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: emphasized ? cs.primaryContainer : cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: emphasized
                  ? cs.primary.withValues(alpha: .25)
                  : cs.outline.withValues(alpha: .14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: emphasized
                      ? cs.primary.withValues(alpha: .12)
                      : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w900,
                            )),
                    const SizedBox(height: 2),
                    Text(detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyFocusCard extends StatelessWidget {
  const _DailyFocusCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: () => context.push(AppRoutes.dailyFocus),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(Icons.bolt_outlined, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHAT CAN I WORK ON TODAY?',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick 15 min, 30 min, 1 hour, or a crew drill. Career Road builds a Learn → Practice → Record session around your Next Best Step.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentLevelCard extends StatelessWidget {
  final String level;
  final String? serviceType;
  final int? yearsOfService;
  final String? stateCode;
  final VoidCallback onTap;

  const _CurrentLevelCard({
    required this.level,
    required this.serviceType,
    required this.yearsOfService,
    required this.stateCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stateName = FireOpsCatalog.stateNameForCode(stateCode);
    final detailParts = <String>[
      if (stateName != null && stateName.trim().isNotEmpty) stateName,
      if (serviceType != null && serviceType!.trim().isNotEmpty) serviceType!,
      if (yearsOfService != null)
        '$yearsOfService ${yearsOfService == 1 ? 'year' : 'years'}',
    ];

    return _HomeCard(
      icon: Icons.badge_outlined,
      eyebrow: 'CURRENT LEVEL',
      title: level,
      subtitle: detailParts.isEmpty
          ? 'Add your service type and years of experience.'
          : detailParts.join(' • '),
      trailingLabel: 'Edit',
      onTap: onTap,
    );
  }
}

class _NextLevelHeroCard extends StatelessWidget {
  final String? goalTitle;
  final DateTime? targetDate;
  final int completed;
  final int total;
  final String? nextStep;
  final TimelineStatus? timelineStatus;
  final VoidCallback onOpenTaskBook;

  const _NextLevelHeroCard({
    required this.goalTitle,
    required this.targetDate,
    required this.completed,
    required this.total,
    required this.nextStep,
    required this.timelineStatus,
    required this.onOpenTaskBook,
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
      _ when hasGoal && total > 0 && completed >= total =>
        'Ready for the next goal',
      _ when hasGoal => 'On your Firefighter Roadmap',
      _ => 'Build your Firefighter Roadmap',
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
        'Choose your Next Level and Firefighter Roadmap will build your Task Book.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.primary.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: cs.shadow.withValues(alpha: 0.06),
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
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.explore_outlined,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT LEVEL',
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
                ProgressRing(
                  progress: progress,
                  size: 52,
                  strokeWidth: 5,
                  centerLabel: '$readiness%',
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
              color: cs.primaryContainer.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
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
                      : 'Choose Next Level',
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
              Icon(
                Icons.insights_outlined,
                size: 17,
                color: cs.onSurfaceVariant,
              ),
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
          FilledButton.icon(
            onPressed: onOpenTaskBook,
            icon: Icon(hasGoal ? Icons.menu_book_outlined : Icons.flag_outlined),
            label: Text(hasGoal ? 'Open Task Book' : 'Choose Next Level'),
          ),
        ],
      ),
    );
  }
}

class _ExpiringCertsMiniPanel extends StatelessWidget {
  final List<CertificationUrgencyItem> items;
  final bool compact;
  const _ExpiringCertsMiniPanel({required this.items, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final expired = items.where((e) => e.status == CertificationStatus.expired).toList();
    final expiring = items.where((e) => e.status == CertificationStatus.expiringSoon).toList();

    final headline = expired.isNotEmpty
        ? 'Credential check — action required'
        : 'Credential check — expiring soon';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: (expired.isNotEmpty ? cs.errorContainer : cs.secondaryContainer)
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: (expired.isNotEmpty
                  ? FireOpsSemanticColors.expired
                  : FireOpsSemanticColors.warning)
              .withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                expired.isNotEmpty
                    ? Icons.cancel
                    : Icons.warning_amber_rounded,
                color: expired.isNotEmpty
                    ? FireOpsSemanticColors.expired
                    : FireOpsSemanticColors.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => context.push(AppRoutes.certifications),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.take(3).map((e) {
            final name = app.certificationDisplayName(e.cert);
            final days = e.daysRemaining;
            final line = e.status == CertificationStatus.expired
                ? 'Expired'
                : days == null
                    ? 'Expiring soon'
                    : 'Expires in $days ${days == 1 ? 'day' : 'days'}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$name — $line',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => context.push(
                      '${AppRoutes.certificationDetail}/${e.cert.id}',
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    child: const Text('Renew'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NextThreeActionsPanel extends StatelessWidget {
  final String? nextStepLabel;
  final List<CertificationUrgencyItem> urgentCerts;
  final VoidCallback onOpenTaskBook;
  final bool compact;

  const _NextThreeActionsPanel({
    required this.nextStepLabel,
    required this.urgentCerts,
    required this.onOpenTaskBook,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final actions = <_NextAction>[];

    for (final item in urgentCerts.take(2)) {
      final name = app.certificationDisplayName(item.cert);
      final days = item.daysRemaining;
      final subtitle = item.status == CertificationStatus.expired
          ? 'Expired — renew to keep your Task Book accurate.'
          : days == null
              ? 'Expiring soon — renew and confirm your dates.'
              : 'Expires in $days ${days == 1 ? 'day' : 'days'} — renew and confirm.';
      actions.add(
        _NextAction(
          icon: item.status == CertificationStatus.expired
              ? Icons.cancel
              : Icons.warning_amber_rounded,
          tone: item.status == CertificationStatus.expired
              ? _NextActionTone.critical
              : _NextActionTone.warning,
          title: 'Renew $name',
          subtitle: subtitle,
          onTap: () => context.push(
            '${AppRoutes.certificationDetail}/${item.cert.id}',
          ),
        ),
      );
    }

    if ((nextStepLabel ?? '').trim().isNotEmpty && actions.length < 3) {
      actions.add(
        _NextAction(
          icon: Icons.menu_book_outlined,
          tone: _NextActionTone.neutral,
          title: 'Next step: ${nextStepLabel!.trim()}',
          subtitle: 'Start the highest-priority incomplete requirement.',
          onTap: onOpenTaskBook,
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT ACTIONS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          ...actions.take(3).map((a) => Padding(
                padding: EdgeInsets.only(bottom: compact ? 6 : 8),
                child: _NextActionTile(action: a),
              )),
        ],
      ),
    );
  }
}

enum _NextActionTone { critical, warning, neutral }

class _NextAction {
  final IconData icon;
  final _NextActionTone tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NextAction({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _NextActionTile extends StatelessWidget {
  final _NextAction action;
  const _NextActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final (tone, bg) = switch (action.tone) {
      _NextActionTone.critical => (
          FireOpsSemanticColors.expired,
          cs.errorContainer.withValues(alpha: 0.45)
        ),
      _NextActionTone.warning => (
          FireOpsSemanticColors.warning,
          cs.secondaryContainer.withValues(alpha: 0.35)
        ),
      _NextActionTone.neutral => (cs.primary, cs.surface),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(action.icon, color: tone, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String? goalTitle;
  final DateTime? targetDate;
  final int completed;
  final int total;
  final String? nextStep;
  final TimelineStatus? timelineStatus;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goalTitle,
    required this.targetDate,
    required this.completed,
    required this.total,
    required this.nextStep,
    required this.timelineStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasGoal = goalTitle != null;
    final progress = total == 0 ? 0.0 : completed / total;

    final status = switch (timelineStatus) {
      TimelineStatus.atRisk => const _CardStatus(
        text: 'At risk',
        tone: _StatusTone.critical,
      ),
      TimelineStatus.needsAttention => const _CardStatus(
        text: 'Needs attention',
        tone: _StatusTone.warning,
      ),
      TimelineStatus.noTargetDate when hasGoal => const _CardStatus(
        text: 'No target date',
        tone: _StatusTone.neutral,
      ),
      _ => null,
    };

    return _HomeCard(
      icon: Icons.flag_outlined,
      eyebrow: 'GOAL',
      title: hasGoal ? goalTitle! : 'Where do you want to go next?',
      subtitle: hasGoal
          ? [
              '${(progress * 100).round()}% complete',
              if (targetDate != null)
                'Target: ${_formatMonthYear(targetDate!)}',
            ].join(' • ')
          : 'Choose your Next Level and Firefighter Roadmap will build your path.',
      emphasisText: hasGoal && nextStep != null ? 'Next: $nextStep' : null,
      progress: hasGoal ? progress : null,
      status: status,
      actionLabel: hasGoal ? 'Open Task Book' : 'Choose Next Level',
      onTap: onTap,
    );
  }
}

class _CertificationsCard extends StatelessWidget {
  final int total;
  final int current;
  final int expiring;
  final int expired;
  final String? nextExpirationName;
  final DateTime? nextExpirationDate;
  final int? nextExpirationDays;
  final VoidCallback onTap;

  const _CertificationsCard({
    required this.total,
    required this.current,
    required this.expiring,
    required this.expired,
    required this.nextExpirationName,
    required this.nextExpirationDate,
    required this.nextExpirationDays,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final _CardStatus? status;
    if (expired > 0) {
      status = _CardStatus(
        text: '$expired expired',
        tone: _StatusTone.critical,
      );
    } else if (expiring > 0) {
      status = _CardStatus(
        text: '$expiring expiring',
        tone: _StatusTone.warning,
      );
    } else {
      status = null;
    }

    String detail;
    if (expired > 0) {
      detail = expired == 1
          ? '1 certification expired'
          : '$expired certifications expired';
    } else if (nextExpirationName != null &&
        nextExpirationDate != null &&
        nextExpirationDays != null &&
        nextExpirationDays! <= 90) {
      final dayLabel = nextExpirationDays == 1 ? 'day' : 'days';
      detail =
          '$nextExpirationName expires in $nextExpirationDays $dayLabel • '
          '${_formatDate(nextExpirationDate!)}';
    } else if (total == 0) {
      detail = 'Add the certifications you already hold.';
    } else {
      detail = 'All tracked certifications are current';
    }

    return _HomeCard(
      icon: Icons.verified_outlined,
      eyebrow: 'CERTS',
      title: total == 0 ? 'Start your credential record' : '$total tracked',
      subtitle: total == 0
          ? 'Add certifications to track renewals.'
          : '$current Current • $expiring Expiring',
      detail: detail,
      status: status,
      actionLabel: total == 0 ? 'Add Certification' : 'Open Certifications',
      onTap: onTap,
    );
  }
}

class _QuickLogCard extends StatelessWidget {
  const _QuickLogCard();

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return FutureBuilder<_CareerYearSummary>(
      future: _loadCareerYearSummary(year),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            summary == null;

        final subtitle = 'Log progress from today.';
        final mini = isLoading
            ? null
            : summary == null || summary.total == 0
            ? null
            : summary.displayLine;

        return _HomeCard(
          icon: Icons.add_task_outlined,
          eyebrow: 'QUICK LOG',
          title: 'Quick Log',
          subtitle: subtitle,
          detail: mini == null
              ? 'Calls • Skills • Training • Drive Time • Leadership • Achievements'
              : '$year  •  $mini',
          actionLabel: '+ Log Activity',
          onTap: () => QuickLogLauncher.open(context),
        );
      },
    );
  }
}

class _CareerYearSummary {
  final int calls;
  final int skills;
  final int trainings;
  final int achievements;

  const _CareerYearSummary({
    required this.calls,
    required this.skills,
    required this.trainings,
    required this.achievements,
  });

  int get total => calls + skills + trainings + achievements;

  String get displayLine => [
    '$calls ${calls == 1 ? 'call' : 'calls'}',
    '$skills ${skills == 1 ? 'skill' : 'skills'}',
    '$trainings ${trainings == 1 ? 'training hr' : 'training hrs'}',
    '$achievements ${achievements == 1 ? 'achievement' : 'achievements'}',
  ].join(' • ');
}

Future<_CareerYearSummary> _loadCareerYearSummary(int year) async {
  final records = await CareerRecordStore().load();
  final yearRecords = records.where((e) => e.date.year == year).toList();
  final stats = CareerStats.fromRecords(yearRecords);

  return _CareerYearSummary(
    calls: stats.calls,
    skills: stats.skillRepetitions,
    trainings: stats.trainingHours.round(),
    achievements: stats.achievements,
  );
}

enum _StatusTone { warning, critical, neutral }

class _CardStatus {
  final String text;
  final _StatusTone tone;

  const _CardStatus({required this.text, required this.tone});
}

class _StatusBadge extends StatelessWidget {
  final _CardStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status.tone) {
      _StatusTone.critical => (cs.errorContainer, cs.onErrorContainer),
      _StatusTone.warning => (cs.secondaryContainer, cs.onSecondaryContainer),
      _StatusTone.neutral => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? detail;
  final String? emphasisText;
  final double? progress;
  final _CardStatus? status;
  final String? trailingLabel;
  final String? actionLabel;
  final VoidCallback? onTap;
  final Widget? footer;

  const _HomeCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.detail,
    this.emphasisText,
    this.progress,
    this.status,
    this.trailingLabel,
    this.actionLabel,
    this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
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
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            eyebrow,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        if (status != null) _StatusBadge(status: status!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailingLabel!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (emphasisText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      emphasisText!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (detail != null) ...[
            const SizedBox(height: 7),
            Text(
              detail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
          ],
          if (footer != null) footer!,
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            Text(
              actionLabel!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: card,
    );
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _formatMonthYear(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
