import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class GetStartedPage extends StatelessWidget {
  final Object? requirement;
  const GetStartedPage({super.key, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final req = requirement is Requirement ? requirement as Requirement : null;
    if (req == null) return const Scaffold(body: Center(child: Text('Requirement not found.')));

    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final roadmap = state.roadmap;
    final items = roadmap?.all ?? const <RoadmapRequirement>[];

    bool hasKey(String key) {
      final lower = key.trim().toLowerCase();
      return state.certifications.any((c) => c.name.trim().toLowerCase() == lower);
    }

    final prereqs = req.prerequisiteRequirementIds;

    final relatedResources = FireOpsCatalog.resources().where((r) => req.resourceIds.contains(r.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Get Started')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            _Header(title: req.name, subtitle: _whyThis(context, req)),
            const SizedBox(height: AppSpacing.lg),
            _StepCard(
              step: 'STEP 1',
              title: 'Review prerequisites',
              child: prereqs.isEmpty
                  ? Text('No typical prerequisites listed. Verify with your department and authority.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5))
                  : Column(
                      children: prereqs.map((p) {
                        final ok = hasKey(p) || items.any((e) => (e.requirement.certificationReference ?? e.requirement.name).trim().toLowerCase() == p.trim().toLowerCase() && e.isComplete);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(ok ? Icons.check_circle : Icons.circle_outlined, color: ok ? FireOpsSemanticColors.completed : cs.onSurfaceVariant, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: Text(p, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 'STEP 2',
              title: 'Find training',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Look for an approved course provider (state, academy, or department).', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
                  const SizedBox(height: AppSpacing.md),
                  _ActionButton(
                    label: 'Find Training',
                    icon: Icons.school,
                    onPressed: () => context.go(
                      AppRoutes.resources,
                      extra: {
                        'mode': 'requirement',
                        'requirementKey': req.name,
                        'types': ['courseProvider'],
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionButton(
                    label: 'Official Requirements',
                    icon: Icons.verified_outlined,
                    onPressed: () => context.go(
                      AppRoutes.resources,
                      extra: {
                        'mode': 'requirement',
                        'requirementKey': req.name,
                        'types': ['officialAgency'],
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 'STEP 3',
              title: 'Start preparing',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ActionButton(
                    label: 'Study Resources',
                    icon: Icons.menu_book,
                    onPressed: () => context.go(
                      AppRoutes.resources,
                      extra: {
                        'mode': 'requirement',
                        'requirementKey': req.name,
                        'types': ['studyGuide'],
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionButton(
                    label: 'Practice',
                    icon: Icons.fitness_center,
                    onPressed: () => context.go(
                      AppRoutes.resources,
                      extra: {
                        'mode': 'requirement',
                        'requirementKey': req.name,
                        'types': ['practice', 'fireOpsTool'],
                      },
                    ),
                  ),
                  if (relatedResources.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('FireOps tools', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: AppSpacing.sm),
                    ...relatedResources.map((res) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ActionButton(
                          label: res.title,
                          icon: Icons.open_in_new,
                          onPressed: res.url == null ? null : () => _openUrl(res.url!),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 'STEP 4',
              title: 'Update your progress',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('When you complete it, add it to your certifications or mark the requirement complete.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
                  const SizedBox(height: AppSpacing.md),
                  _ActionButton(
                    label: 'Add to My Certifications',
                    icon: Icons.add,
                    onPressed: () => context.push('${AppRoutes.certificationDetail}/new', extra: {'name': req.name, 'completedFromGoalId': roadmap?.goal.id, 'completedFromRequirementId': req.id}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (roadmap != null)
                    _ActionButton(
                      label: 'Mark Complete',
                      icon: Icons.check_circle,
                      onPressed: req.type == RequirementType.certification
                          ? null
                          : () => context.read<AppState>().setRequirementCompleted(goalId: roadmap.goal.id, requirementId: req.id, completed: true),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Notice(),
          ],
        ),
      ),
    );
  }

  static String _whyThis(BuildContext context, Requirement r) {
    final goal = context.read<AppState>().selectedGoal;
    final goalName = goal?.title;
    final base = goalName == null ? 'This is a common step on many career paths.' : 'This is commonly used when preparing for $goalName responsibilities.';
    if (r.type == RequirementType.numericProgress && r.progressRequired != null) {
      final unit = r.progressUnit ?? 'units';
      return '$base Your department may require you to document ${r.progressRequired!.toStringAsFixed(0)} $unit.';
    }
    return base;
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      debugPrint('Invalid URL: $url');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) debugPrint('launchUrl failed for $url');
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final Widget child;
  const _StepCard({required this.step, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const _ActionButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: cs.onPrimary),
        label: Text(label, style: TextStyle(color: cs.onPrimary)),
        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Text(
        'Fire service certification, promotional, and training requirements vary by state, agency, and department. FireOps Path provides career planning guidance. Always verify requirements with your department and certification authority.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
      ),
    );
  }
}
