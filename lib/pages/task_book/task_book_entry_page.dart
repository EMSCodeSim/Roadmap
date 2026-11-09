import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/progress_ring.dart';
import 'package:firepath/widgets/status_pill.dart';

/// Personal growth is the primary experience; department task books remain
/// accessible from the separate Department workspace.
class TaskBookEntryPage extends StatefulWidget {
  const TaskBookEntryPage({super.key});

  @override
  State<TaskBookEntryPage> createState() => _TaskBookEntryPageState();
}

class _TaskBookEntryPageState extends State<TaskBookEntryPage> {
  final Set<String> _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roadmap = app.roadmap;
    final cs = Theme.of(context).colorScheme;
    final percent = roadmap == null ? 0 : (roadmap.percentComplete * 100).round().clamp(0, 100);
    final completed = roadmap?.completedCount ?? 0;
    final total = roadmap?.totalCount ?? 0;
    final goal = roadmap?.goal.title ?? 'Choose your career goal';
    final sections = roadmap == null ? const <_RoadmapCatalogSection>[] : _RoadmapCatalogSection.group(roadmap);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Roadmap'),
        actions: [
          IconButton(
            tooltip: 'Edit career goal',
            onPressed: () => context.push(AppRoutes.goalSetup),
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Career growth, organized into simple catalogs.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          _RoadmapHeroCard(
            goal: goal,
            percent: percent,
            completed: completed,
            total: total,
            nextStep: roadmap?.nextStep?.requirement.name,
            onContinue: () => context.push(roadmap == null ? AppRoutes.goalSetup : AppRoutes.myPathLegacy),
          ),
          const SizedBox(height: 18),
          if (roadmap == null) ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose your goal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pick a target role to generate your roadmap.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.goalSetup),
                      icon: const Icon(Icons.flag_rounded, color: Colors.white),
                      label: const Text('Select a career goal', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Catalogs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                StatusPill(
                  text: '$completed/$total complete',
                  icon: Icons.check_circle_outline_rounded,
                  backgroundColor: FireOpsSemanticColors.green.withValues(alpha: 0.10),
                  foregroundColor: FireOpsSemanticColors.green,
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final section in sections) ...[
              _RoadmapCatalogCard(
                section: section,
                expanded: _expanded.contains(section.category),
                onToggle: () {
                  setState(() {
                    if (_expanded.contains(section.category)) {
                      _expanded.remove(section.category);
                    } else {
                      _expanded.add(section.category);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 8),
          Text(
            'Personal growth tools',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _GrowthToolTile(
            icon: Icons.insights_outlined,
            title: 'Career intelligence',
            subtitle: 'Readiness, strengths, and areas to build',
            onTap: () => context.push(AppRoutes.careerIntelligence),
          ),
          _GrowthToolTile(
            icon: Icons.hub_outlined,
            title: 'Competency map',
            subtitle: 'See evidence and competency progress',
            onTap: () => context.push(AppRoutes.competencyMap),
          ),
          _GrowthToolTile(
            icon: Icons.trending_up_rounded,
            title: 'Growth planning',
            subtitle: 'Development, experience, and longer-term goals',
            onTap: () => context.push(AppRoutes.growthDetails),
          ),
          _GrowthToolTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Certifications',
            subtitle: 'Track the credentials needed for your next role',
            onTap: () => context.push(AppRoutes.certifications),
          ),
          _GrowthToolTile(
            icon: Icons.history_rounded,
            title: 'Career record',
            subtitle: 'Recall experience, training, achievements, and evidence',
            onTap: () => context.push(AppRoutes.personalLog),
          ),
        ],
      ),
    );
  }
}

class _GrowthToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GrowthToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}

class _RoadmapHeroCard extends StatelessWidget {
  final String goal;
  final int percent;
  final int completed;
  final int total;
  final String? nextStep;
  final VoidCallback onContinue;

  const _RoadmapHeroCard({
    required this.goal,
    required this.percent,
    required this.completed,
    required this.total,
    required this.nextStep,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = (percent / 100).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ProgressRing(
              progress: progress,
              size: 60,
              strokeWidth: 7,
              centerLabel: '$percent%',
              progressColor: FireOpsFeatureColors.roadmap,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal',
                    style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.15),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(
                        text: '$completed / $total',
                        icon: Icons.check_circle_outline_rounded,
                        backgroundColor: FireOpsSemanticColors.green.withValues(alpha: 0.10),
                        foregroundColor: FireOpsSemanticColors.green,
                      ),
                      if ((nextStep ?? '').trim().isNotEmpty)
                        StatusPill(
                          text: 'Next step',
                          icon: Icons.arrow_forward_rounded,
                          backgroundColor: FireOpsFeatureColors.training.withValues(alpha: 0.10),
                          foregroundColor: FireOpsFeatureColors.training,
                          tooltip: nextStep,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onContinue,
              child: const Text('Continue', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapCatalogSection {
  final String category;
  final List<RoadmapRequirement> items;
  final int completed;
  final int total;

  const _RoadmapCatalogSection({
    required this.category,
    required this.items,
    required this.completed,
    required this.total,
  });

  static List<_RoadmapCatalogSection> group(Roadmap roadmap) {
    final by = <String, List<RoadmapRequirement>>{};
    final order = <String>[];
    for (final item in roadmap.all) {
      final raw = item.requirement.category.trim();
      final cat = raw.isEmpty ? 'Other' : raw;
      if (!by.containsKey(cat)) order.add(cat);
      by.putIfAbsent(cat, () => <RoadmapRequirement>[]).add(item);
    }
    return order.map((cat) {
      final items = by[cat] ?? <RoadmapRequirement>[];
      final completed = items.where((e) => e.isComplete && !e.isExcluded).length;
      final total = items.where((e) => !e.isExcluded).length;
      return _RoadmapCatalogSection(category: cat, items: items, completed: completed, total: total);
    }).toList();
  }
}

class _RoadmapCatalogCard extends StatelessWidget {
  final _RoadmapCatalogSection section;
  final bool expanded;
  final VoidCallback onToggle;

  const _RoadmapCatalogCard({
    required this.section,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = section.total == 0 ? 0.0 : (section.completed / section.total).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: FireOpsFeatureColors.roadmap.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: FireOpsFeatureColors.roadmap),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.category,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    color: FireOpsSemanticColors.green,
                                    backgroundColor: cs.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${section.completed}/${section.total}',
                                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
              for (final item in section.items.where((e) => !e.isExcluded))
                _RoadmapRequirementRow(item: item),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoadmapRequirementRow extends StatelessWidget {
  final RoadmapRequirement item;
  const _RoadmapRequirementRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final req = item.requirement;

    final (icon, color) = switch (req.type) {
      RequirementType.certification => (Icons.workspace_premium_rounded, FireOpsFeatureColors.certificates),
      RequirementType.experience => (Icons.timelapse_rounded, FireOpsFeatureColors.training),
      RequirementType.numericProgress => (Icons.stacked_bar_chart_rounded, FireOpsFeatureColors.training),
      _ => (Icons.checklist_rounded, FireOpsFeatureColors.roadmap),
    };

    final statusText = item.isComplete ? 'Complete' : 'In progress';
    final statusColor = item.isComplete ? FireOpsSemanticColors.green : FireOpsSemanticColors.amber;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        req.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            StatusPill(
              text: statusText,
              icon: item.isComplete ? Icons.check_circle_rounded : Icons.hourglass_bottom_rounded,
              backgroundColor: statusColor.withValues(alpha: 0.10),
              foregroundColor: statusColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                req.type.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => AppRouter.openRequirement(context, req),
    );
  }
}
