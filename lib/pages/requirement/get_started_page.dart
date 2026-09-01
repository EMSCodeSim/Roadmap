import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/resource.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/task_book_resource_composer.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class GetStartedPage extends StatelessWidget {
  final Object? requirement;
  const GetStartedPage({super.key, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final req = requirement is Requirement ? requirement as Requirement : null;
    if (req == null)
      return const Scaffold(
        body: Center(child: Text('Requirement not found.')),
      );

    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final roadmap = state.roadmap;
    final items = roadmap?.all ?? const <RoadmapRequirement>[];

    bool hasCertId(String certId) => state.certifications.any(
      (c) =>
          c.certificationDefinitionId == certId &&
          c.status != CertificationStatus.expired,
    );

    final prereqs = req.prerequisiteRequirementIds;
    final certId = req.certificationDefinitionId;
    final userState = FireOpsCatalog.stateCodeFromLegacyValue(state.profile.state);

    final allResources = FireOpsCatalog.resources();
    final byId = {for (final r in allResources) r.id: r};

    final directResources = req.resourceIds
        .map((id) => byId[id])
        .whereType<Resource>()
        .toList();
    final relatedResources = certId == null
        ? <Resource>[]
        : allResources
              .where(
                (r) => r.relatedCertificationDefinitionIds.contains(certId),
              )
              .toList();
    final combined = {...directResources, ...relatedResources}.toList();

    final composed = certId == null
        ? null
        : TaskBookResourceComposer.buildGetStartedSections(
            certId: certId,
            stateCode: userState,
            catalogCombined: combined,
          );

    final official = composed?.official ?? const <Resource>[];
    final training = composed?.training ?? const <Resource>[];
    final study = composed?.study ?? const <Resource>[];
    final practice = composed?.practice ?? const <Resource>[];

    final road = state.roadmap;
    final goalId = road?.goal.id;
    final userLinks = (goalId == null)
        ? const <ResourceLink>[]
        : state.userResourceLinksFor(goalId: goalId, requirementId: req.id);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toTaskBook(),
        title: const Text('Get Started'),
      ),
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
                  ? Text(
                      'No typical prerequisites are listed for this item. Verify current requirements with your department or certifying authority.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                    )
                  : Column(
                      children: prereqs.map((p) {
                        final prereqId =
                            FireOpsCatalog.matchCertificationDefinitionId(p);
                        final ok = prereqId == null
                            ? false
                            : hasCertId(prereqId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                ok ? Icons.check_circle : Icons.circle_outlined,
                                color: ok
                                    ? FireOpsSemanticColors.completed
                                    : cs.onSurfaceVariant,
                                size: 18,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  p,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 'STEP 2',
              title: 'Official requirements',
              child: _ResourceSection(
                resources: official,
                emptyText: certId == null
                    ? 'No mapped official link is available for this item. Verify current requirements with the appropriate certifying authority.'
                    : 'No mapped official link is available for this item. Check Resources or verify current requirements with your state or certifying authority.',
                onViewAll: certId == null
                    ? null
                    : () => context.go(
                        AppRoutes.resources,
                        extra: {
                          'mode': 'requirement',
                          'requirementKey': certId,
                          'types': [
                            ResourceType.officialStateAgency.name,
                            ResourceType.officialFederalAgency.name,
                            ResourceType.credentialingOrganization.name,
                          ],
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 'STEP 3',
              title: 'Find training',
              child: _ResourceSection(
                resources: training,
                emptyText: certId == null
                    ? 'No mapped training link is available for this item. Use your local academy, department, college, or authorized training provider.'
                    : 'No mapped training link is available for this item. Check Resources or use your local academy, department, college, or authorized training provider.',
                onViewAll: certId == null
                    ? null
                    : () => context.go(
                        AppRoutes.resources,
                        extra: {
                          'mode': 'requirement',
                          'requirementKey': certId,
                          'types': [
                            ResourceType.trainingProvider.name,
                            ResourceType.courseFinder.name,
                            ResourceType.collegeAcademy.name,
                          ],
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 'STEP 4',
              title: 'Study',
              child: _ResourceSection(
                resources: study,
                emptyText: certId == null
                    ? 'No mapped study resource is available for this item. Use the applicable standard, course material, and local training resources.'
                    : 'No mapped study resource is available for this item. Check Resources and use the applicable standard, course material, and local training resources.',
                onViewAll: certId == null
                    ? null
                    : () => context.go(
                        AppRoutes.resources,
                        extra: {
                          'mode': 'requirement',
                          'requirementKey': certId,
                          'types': [ResourceType.studyResource.name],
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 'STEP 5',
              title: 'Practice',
              child: _ResourceSection(
                resources: practice,
                emptyText: certId == null
                    ? 'No mapped practice tool is available for this item. Use your department or training provider’s approved practice process.'
                    : 'No mapped practice tool is available for this item. Check Resources or use your department or training provider’s approved practice process.',
                onViewAll: certId == null
                    ? null
                    : () => context.go(
                        AppRoutes.resources,
                        extra: {
                          'mode': 'requirement',
                          'requirementKey': certId,
                          'types': [
                            ResourceType.practiceResource.name,
                            ResourceType.fireOpsTool.name,
                          ],
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 'STEP 6',
              title: 'Your local resource',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Save a resource you already use, such as an academy portal, LMS, department intranet, or reference page. This stays with your personal Career Road on this device.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (userLinks.isNotEmpty) ...[
                    ...userLinks.map(
                      (l) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ActionButton(
                          label: l.title,
                          icon: Icons.link,
                          onPressed: l.url == null
                              ? null
                              : () => _openUrl(l.url!),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  _ActionButton(
                    label: 'Add Local Resource',
                    icon: Icons.add_link,
                    onPressed: road == null
                        ? null
                        : () => _addDepartmentResource(
                            context,
                            goalId: road.goal.id,
                            requirementId: req.id,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 'STEP 7',
              title: 'Update your progress',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'When you complete it, add it to your certifications or mark the requirement complete.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionButton(
                    label: 'Add to My Certifications',
                    icon: Icons.add,
                    onPressed: () => context.push(
                      AppRoutes.certificationAdd,
                      extra: {
                        'prefillDefinitionId': certId,
                        'prefillName': req.name,
                        'completedFromGoalId': road?.goal.id,
                        'completedFromRequirementId': req.id,
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (road != null)
                    _ActionButton(
                      label: 'Mark Complete',
                      icon: Icons.check_circle,
                      onPressed: req.type == RequirementType.certification
                          ? null
                          : () => context
                                .read<AppState>()
                                .setRequirementCompleted(
                                  goalId: road.goal.id,
                                  requirementId: req.id,
                                  completed: true,
                                ),
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
    final base = goalName == null
        ? 'This is a common step on many career paths.'
        : 'This is commonly used when preparing for $goalName responsibilities.';
    if (r.type == RequirementType.numericProgress &&
        r.progressRequired != null) {
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

  static Future<void> _addDepartmentResource(
    BuildContext context, {
    required String goalId,
    required String requirementId,
  }) async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Local Resource',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Save a link you already use for this requirement. It stays with your personal Career Road on this device.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (ok != true) return;
      final name = nameCtrl.text.trim();
      if (name.isEmpty) return;
      final url = urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim();
      await context.read<AppState>().addUserResourceLink(
        goalId: goalId,
        requirementId: requirementId,
        link: ResourceLink(title: name, url: url),
      );
    } finally {
      nameCtrl.dispose();
      urlCtrl.dispose();
    }
  }
}

class _ResourceSection extends StatelessWidget {
  final List<Resource> resources;
  final String emptyText;
  final VoidCallback? onViewAll;

  const _ResourceSection({
    required this.resources,
    required this.emptyText,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final available = resources.where((resource) {
      final url = resource.url?.trim();
      return url != null && url.isNotEmpty;
    }).toList();

    if (available.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            emptyText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (onViewAll != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ActionButton(
              label: 'Open Resources',
              icon: Icons.search,
              onPressed: onViewAll,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...available
            .take(3)
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ActionButton(
                  label: r.verified ? r.title : '${r.title} (unverified)',
                  icon: Icons.open_in_new,
                  onPressed: () => GetStartedPage._openUrl(r.url!),
                ),
              ),
            ),
        if (available.length > 3 && onViewAll != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _ActionButton(
            label: 'View all',
            icon: Icons.chevron_right,
            onPressed: onViewAll,
          ),
        ],
      ],
    );
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
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final Widget child;
  const _StepCard({
    required this.step,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
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
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: cs.onPrimary),
        label: Text(label, style: TextStyle(color: cs.onPrimary)),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
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
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        'Requirements vary by state and department. Use this as planning help—verify with your department and cert authority.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.45,
        ),
      ),
    );
  }
}
