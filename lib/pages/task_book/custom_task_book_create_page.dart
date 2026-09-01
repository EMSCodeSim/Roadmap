import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';

enum _StartingPoint { blank, copyCareerRoad, copyGoalTemplate }

class CustomTaskBookCreatePage extends StatefulWidget {
  const CustomTaskBookCreatePage({super.key});

  @override
  State<CustomTaskBookCreatePage> createState() => _CustomTaskBookCreatePageState();
}

class _CustomTaskBookCreatePageState extends State<CustomTaskBookCreatePage> {
  final _nameCtrl = TextEditingController();
  bool _departmentSpecific = true;
  _StartingPoint _startingPoint = _StartingPoint.blank;
  String? _linkedGoalId;
  String? _templateGoalId;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final roadmap = state.roadmap;
    final goals = state.availableGoals;

    final canCopyCareerRoad = roadmap != null;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toTaskBook(),
        title: const Text('Create Task Book'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEPARTMENT / CUSTOM',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Build the Task Book your department actually uses.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture local SOP sign-offs, quarterly skills, promo steps, and required hours — while keeping your Career Road Task Book intact.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Panel(
              title: 'Name it so it’s obvious on shift',
              child: TextField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Task Book name',
                  hintText: 'Promo Captain Task Book — Station 7',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Panel(
              title: 'What is this for?',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _PurposeChoiceTile(
                          selected: _departmentSpecific,
                          title: 'Department',
                          subtitle: 'Local SOPs + internal sign-offs',
                          icon: Icons.apartment_outlined,
                          onTap: () => setState(() => _departmentSpecific = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PurposeChoiceTile(
                          selected: !_departmentSpecific,
                          title: 'Personal',
                          subtitle: 'Your own structure & checklist',
                          icon: Icons.book_outlined,
                          onTap: () => setState(() => _departmentSpecific = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _GoalLinkRow(
                    goals: goals,
                    linkedGoalId: _linkedGoalId,
                    onChanged: (v) => setState(() => _linkedGoalId = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Panel(
              title: 'Starting point',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StartChoiceTile(
                    selected: _startingPoint == _StartingPoint.blank,
                    title: 'Blank Task Book',
                    subtitle: 'Fastest. Add your first 5–10 department items and refine later.',
                    icon: Icons.note_add_outlined,
                    onTap: () => setState(() => _startingPoint = _StartingPoint.blank),
                  ),
                  const SizedBox(height: 10),
                  _StartChoiceTile(
                    selected: _startingPoint == _StartingPoint.copyCareerRoad,
                    enabled: canCopyCareerRoad,
                    title: 'Copy from My Career Road',
                    subtitle: canCopyCareerRoad
                        ? 'Start with your generated requirements, then add department specifics.'
                        : 'Choose a career goal first to generate your Career Road Task Book.',
                    icon: Icons.alt_route,
                    onTap: () => setState(() => _startingPoint = _StartingPoint.copyCareerRoad),
                  ),
                  const SizedBox(height: 10),
                  _StartChoiceTile(
                    selected: _startingPoint == _StartingPoint.copyGoalTemplate,
                    title: 'Start from a standard goal template',
                    subtitle: 'Pick a goal template, then tailor it to your department.',
                    icon: Icons.auto_awesome,
                    onTap: () => setState(() => _startingPoint = _StartingPoint.copyGoalTemplate),
                  ),
                  if (_startingPoint == _StartingPoint.copyGoalTemplate) ...[
                    const SizedBox(height: 12),
                    _GoalTemplatePicker(
                      goals: goals,
                      value: _templateGoalId,
                      onChanged: (v) => setState(() => _templateGoalId = v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _saving ? null : () => _create(context, state),
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                      )
                    : const Icon(Icons.build_circle_outlined),
                label: Text(_departmentSpecific ? 'Build My Department Task Book' : 'Create Custom Task Book'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You can switch between your Career Road and custom books anytime.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, AppState state) async {
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final requirements = await _buildStartingRequirements(state);
      final book = await state.taskBookController.createCustomTaskBook(
        name: name,
        departmentSpecific: _departmentSpecific,
        linkedGoalId: _linkedGoalId,
        requirements: requirements,
      );
      if (!mounted) return;
      context.go(AppRoutes.customTaskBookBuilder, extra: {'taskBookId': book.id});
    } catch (e) {
      debugPrint('CustomTaskBookCreatePage._create failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create Task Book. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<List<Requirement>> _buildStartingRequirements(AppState state) async {
    switch (_startingPoint) {
      case _StartingPoint.blank:
        return <Requirement>[];
      case _StartingPoint.copyCareerRoad:
        final roadmap = state.roadmap;
        if (roadmap == null) return <Requirement>[];
        return roadmap.included.map((e) => e.requirement).toList();
      case _StartingPoint.copyGoalTemplate:
        final goal = _findGoal(state.availableGoals, _templateGoalId) ?? state.selectedGoal;
        if (goal == null) return <Requirement>[];
        return [...goal.requirements];
    }
  }

  static CareerGoal? _findGoal(List<CareerGoal> goals, String? id) {
    if (id == null) return null;
    return goals.where((g) => g.id == id).firstOrNull;
  }
}

class _PurposeChoiceTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PurposeChoiceTile({required this.selected, required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = selected ? cs.primary.withValues(alpha: 0.30) : cs.outline.withValues(alpha: 0.14);
    final bg = selected ? cs.primaryContainer.withValues(alpha: 0.55) : cs.surfaceContainerHighest.withValues(alpha: 0.25);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: border)),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StartChoiceTile extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _StartChoiceTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = selected ? cs.primary.withValues(alpha: 0.30) : cs.outline.withValues(alpha: 0.14);
    final bg = selected ? cs.primaryContainer.withValues(alpha: 0.55) : cs.surfaceContainerHighest.withValues(alpha: 0.25);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: enabled ? bg : cs.surfaceContainerHighest.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: enabled ? borderColor : cs.outline.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (selected) Icon(Icons.check_circle, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _GoalLinkRow extends StatelessWidget {
  final List<CareerGoal> goals;
  final String? linkedGoalId;
  final ValueChanged<String?> onChanged;

  const _GoalLinkRow({
    required this.goals,
    required this.linkedGoalId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Link to a Career Goal (optional)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                'Helpful when you want this book to align with a specific next level.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String?>(
          value: linkedGoalId,
          onChanged: onChanged,
          items: [
            const DropdownMenuItem(value: null, child: Text('None')),
            ...goals.map((g) => DropdownMenuItem(value: g.id, child: Text(g.title))),
          ],
        ),
      ],
    );
  }
}

class _GoalTemplatePicker extends StatelessWidget {
  final List<CareerGoal> goals;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _GoalTemplatePicker({
    required this.goals,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: goals.map((g) => DropdownMenuItem(value: g.id, child: Text(g.title))).toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(labelText: 'Choose a goal template'),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
