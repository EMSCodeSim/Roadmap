import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/task_book_setup_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class GoalPickerPage extends StatefulWidget {
  const GoalPickerPage({super.key});

  @override
  State<GoalPickerPage> createState() => _GoalPickerPageState();
}

class _GoalPickerPageState extends State<GoalPickerPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedGoalId;
  String? _customGoalTitle;
  DateTime? _targetDate;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initialize(AppState state) {
    if (_initialized) return;
    _initialized = true;
    _selectedGoalId = state.profile.primaryGoalId;
    _targetDate = state.profile.careerPlan.targetDate;
    final id = _selectedGoalId;
    if (id != null && id.startsWith('custom:')) {
      final title = id.substring('custom:'.length).trim();
      _customGoalTitle = title.isEmpty ? 'Custom Goal' : title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _initialize(state);

    final cs = Theme.of(context).colorScheme;
    final query = _searchController.text.trim().toLowerCase();
    final goals = state.availableGoals.where((goal) {
      if (query.isEmpty) return true;
      return goal.title.toLowerCase().contains(query) ||
          goal.category.toLowerCase().contains(query) ||
          (goal.subtitle ?? '').toLowerCase().contains(query);
    }).toList();

    final grouped = <String, List<CareerGoal>>{};
    for (final goal in goals) {
      (grouped[goal.category] ??= <CareerGoal>[]).add(goal);
    }
    final categories = grouped.keys.toList()..sort();

    final hadGoal = state.profile.primaryGoalId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(hadGoal ? 'Change Career Goal' : 'Choose Career Goal'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.paddingLg,
                children: [
                  Text(
                    hadGoal
                        ? 'Where do you want to go next?'
                        : 'Build your career path',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pick the position or specialty you want to work toward. You can change this later without changing your certifications or career log.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search Engineer, Captain, Instructor…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                  if (_customGoalTitle != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _GoalChoiceCard(
                      title: _customGoalTitle!,
                      subtitle: 'Custom career goal',
                      category: 'Custom',
                      selected: _selectedGoalId?.startsWith('custom:') ?? false,
                      onTap: () {
                        setState(() {
                          _selectedGoalId = 'custom:${_customGoalTitle!}';
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _createCustomGoal,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Custom Goal'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (categories.isEmpty)
                    _NoGoalResults(query: _searchController.text.trim())
                  else
                    ...categories.expand((category) {
                      final items = grouped[category]!;
                      return [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                        ...items.map(
                          (goal) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _GoalChoiceCard(
                              title: goal.title,
                              subtitle: goal.subtitle ?? goal.description,
                              category: goal.category,
                              selected: _selectedGoalId == goal.id,
                              onTap: () {
                                setState(() {
                                  _selectedGoalId = goal.id;
                                  _customGoalTitle = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ];
                    }),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Optional target date',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Use a target date if you want the Timeline to help pace your plan. Leave it blank if you are exploring.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TargetDateCard(
                    date: _targetDate,
                    onPick: _pickTargetDate,
                    onClear: _targetDate == null
                        ? null
                        : () => setState(() => _targetDate = null),
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                    color: cs.outline.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _selectedGoalId == null || _saving
                      ? null
                      : () => _save(state),
                  child: Text(
                    _saving
                        ? 'Saving…'
                        : hadGoal
                            ? 'Build & Review New Task Book'
                            : 'Build & Review My Task Book',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCustomGoal() async {
    final controller = TextEditingController(text: _customGoalTitle ?? '');
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Custom Goal'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Goal title',
              hintText: 'Example: EMS Captain',
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                dialogContext.pop(trimmed);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => dialogContext.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) dialogContext.pop(value);
              },
              child: const Text('Use Goal'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || title == null || title.trim().isEmpty) return;
    final cleanTitle = title.trim();
    setState(() {
      _customGoalTitle = cleanTitle;
      _selectedGoalId = 'custom:$cleanTitle';
      _searchController.clear();
    });
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final initial = _targetDate ?? DateTime(now.year + 1, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 15, 12, 31),
      helpText: 'Target ready date',
    );
    if (picked != null && mounted) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save(AppState state) async {
    final goalId = _selectedGoalId;
    if (goalId == null) return;

    setState(() => _saving = true);
    try {
      await state.setPrimaryGoal(goalId);
      await state.setTargetReadyDate(_targetDate);
      await TaskBookSetupStore().setReviewPending(true);
      if (!mounted) return;
      context.go(AppRoutes.taskBookReview);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _GoalChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String category;
  final bool selected;
  final VoidCallback onTap;

  const _GoalChoiceCard({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.65)
          : cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.45)
                  : cs.outline.withValues(alpha: 0.14),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
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

class _TargetDateCard extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _TargetDateCard({
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_outlined, color: cs.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date == null ? 'No target date' : _formatDate(date!),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  date == null
                      ? 'Timeline pacing will stay optional.'
                      : 'Use this as a planning target, not a promise of promotion.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'Clear target date',
              onPressed: onClear,
              icon: const Icon(Icons.clear),
            ),
          TextButton(
            onPressed: onPick,
            child: Text(date == null ? 'Set' : 'Change'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
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
}

class _NoGoalResults extends StatelessWidget {
  final String query;

  const _NoGoalResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        children: [
          Icon(Icons.search_off_outlined, size: 42, color: cs.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(
            query.isEmpty ? 'No goals available' : 'No goals match “$query”',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Create a custom goal if your next position or specialty is unique to your department.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
