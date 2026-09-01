import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/resource.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/pages/profile/us_state_picker_sheet.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

enum _ResourcesMode { personalized, requirementFilter }

class ResourcesPage extends StatefulWidget {
  final Object? extra;
  const ResourcesPage({super.key, required this.extra});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  final TextEditingController _search = TextEditingController();

  _ResourcesMode _mode = _ResourcesMode.personalized;
  String? _requirementKey;
  Set<ResourceType> _typeFilter = {};
  Set<String> _chipFilter = {'Task Book'};

  @override
  void initState() {
    super.initState();
    _hydrateExtra();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _hydrateExtra() {
    final extra = widget.extra;
    if (extra is Map) {
      final mode = extra['mode'];
      if (mode == 'requirement') {
        _mode = _ResourcesMode.requirementFilter;
        _requirementKey = (extra['requirementKey'] as String?)?.trim();
        final t = extra['types'];
        if (t is List) {
          _typeFilter = t
              .whereType<String>()
              .map((e) {
                try {
                  return ResourceType.values.byName(e);
                } catch (_) {
                  return null;
                }
              })
              .whereType<ResourceType>()
              .toSet();
        }
        final preset = extra['search'] as String?;
        if (preset != null && preset.trim().isNotEmpty) {
          _search.text = preset.trim();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      _ResourcesMode.requirementFilter => _RequirementResourcesView(
        requirementKey: _requirementKey,
        typeFilter: _typeFilter,
        searchController: _search,
      ),
      _ResourcesMode.personalized => _PersonalizedResourcesView(
        searchController: _search,
        chipFilter: _chipFilter,
        onToggleChip: (c) => setState(() {
          if (_chipFilter.contains(c)) {
            _chipFilter.remove(c);
          } else {
            _chipFilter.add(c);
          }
          if (_chipFilter.isEmpty) _chipFilter.add('Task Book');
        }),
      ),
    };
  }
}

class _PersonalizedResourcesView extends StatelessWidget {
  final TextEditingController searchController;
  final Set<String> chipFilter;
  final ValueChanged<String> onToggleChip;

  const _PersonalizedResourcesView({
    required this.searchController,
    required this.chipFilter,
    required this.onToggleChip,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ValueListenableBuilder(
      valueListenable: searchController,
      builder: (context, value, _) {
        final cs = Theme.of(context).colorScheme;

        final items = FireOpsCatalog.resources();
        final road = state.roadmap;
        final goalId = road?.goal.id;
        final nextCertId =
            road?.nextStep?.requirement.certificationDefinitionId;
        final userState =
            FireOpsCatalog.stateCodeFromLegacyValue(state.profile.state);

        final activeRequirementIds = <String>{};
        if (road != null) {
          for (final r in road.included) {
            final st = state.activityStatusFor(
              goalId: road.goal.id,
              requirementId: r.requirement.id,
            );
            if (st == RequirementActivityStatus.planning ||
                st == RequirementActivityStatus.scheduled ||
                st == RequirementActivityStatus.inProgress) {
              activeRequirementIds.add(r.requirement.id);
            }
          }
        }

        bool matchText(Resource r, String q) {
          final query = q.trim().toLowerCase();
          if (query.isEmpty) return true;
          final defs = FireOpsCatalog.certificationById();
          final relatedNames = r.relatedCertificationDefinitionIds
              .map((id) => defs[id]?.displayName ?? id)
              .join(' ');
          final blob = '${r.title} ${r.description} $relatedNames'
              .toLowerCase();
          return blob.contains(query);
        }

        bool matchChips(Resource r) {
          final chips = chipFilter;
          if (chips.isEmpty) return true;

          bool onMyPath() {
            if (goalId == null &&
                nextCertId == null &&
                activeRequirementIds.isEmpty) {
              return true;
            }
            final matchesGoal =
                goalId != null && r.relatedCareerGoalIds.contains(goalId);
            final matchesNext =
                nextCertId != null &&
                r.relatedCertificationDefinitionIds.contains(nextCertId);
            final matchesActive = activeRequirementIds.isNotEmpty;
            return matchesGoal || matchesNext || matchesActive;
          }

          bool ok = true;
          for (final c in chips) {
            ok =
                ok &&
                switch (c) {
                  'Task Book' => onMyPath(),
                  'Official' =>
                    r.type == ResourceType.officialStateAgency ||
                        r.type == ResourceType.officialFederalAgency,
                  'Training' =>
                    r.type == ResourceType.trainingProvider ||
                        r.type == ResourceType.courseFinder ||
                        r.type == ResourceType.collegeAcademy,
                  'Study' => r.type == ResourceType.studyResource,
                  'Practice' =>
                    r.type == ResourceType.practiceResource ||
                        r.type == ResourceType.fireOpsTool,
                  'Fire' => r.relatedCertificationDefinitionIds.any(
                    (e) =>
                        e.contains('fire') ||
                        e.contains('haz') ||
                        e.contains('driver_operator'),
                  ),
                  'EMS' => r.relatedCertificationDefinitionIds.any(
                    (e) =>
                        e == 'emt' ||
                        e == 'aemt' ||
                        e == 'paramedic' ||
                        e == 'bls' ||
                        e == 'acls' ||
                        e == 'pals',
                  ),
                  _ => true,
                };
          }
          return ok;
        }

        final filtered = items
            .where(
              (r) =>
                  r.url?.trim().isNotEmpty == true &&
                  matchText(r, value.text) &&
                  matchChips(r),
            )
            .toList();
        filtered.sort((a, b) {
          int score(Resource r) {
            int s = 0;
            if (userState != null && r.state != null && r.state == userState) {
              s += 100;
            }
            if (nextCertId != null &&
                r.relatedCertificationDefinitionIds.contains(nextCertId)) {
              s += 60;
            }
            if (goalId != null && r.relatedCareerGoalIds.contains(goalId)) {
              s += 30;
            }
            if (r.type == ResourceType.fireOpsTool) s += 10;
            return -s;
          }

          return score(a).compareTo(score(b));
        });

        final stateSpecific = userState == null
            ? <Resource>[]
            : filtered.where((r) => r.state == userState).toList();
        // Never mix other states into the national feed; if we don't have the
        // user's state yet, show only state-neutral resources.
        final national = filtered.where((r) => r.state == null).toList();

        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton.toHome(),
            title: const Text('Resources'),
          ),
          body: SafeArea(
            child: ListView(
              padding: AppSpacing.paddingLg,
              children: [
                Text(
                  'For your path',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Links and tools prioritized by your current role, goal, and next step.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SearchBar(controller: searchController),
                const SizedBox(height: AppSpacing.md),
                _FilterChips(selected: chipFilter, onToggle: onToggleChip),
                const SizedBox(height: AppSpacing.lg),
                if (nextCertId != null) ...[
                  _SectionHeader(
                    title: 'YOUR NEXT STEP',
                    subtitle:
                        FireOpsCatalog.certificationById()[nextCertId]
                            ?.displayName ??
                        '',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._buildCards(
                    context,
                    filtered
                        .where(
                          (r) => r.relatedCertificationDefinitionIds.contains(
                            nextCertId,
                          ),
                        )
                        .toList(),
                    limit: 6,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (stateSpecific.isNotEmpty) ...[
                  _SectionHeader(
                    title: '${userState!} RESOURCES',
                    subtitle: 'State-specific links for your profile',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._buildCards(context, stateSpecific, limit: 8),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (userState == null) ...[
                  _SectionHeader(
                    title: 'STATE-SPECIFIC LINKS',
                    subtitle:
                        'Select your state to prioritize official requirements and training links.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PickStateCard(
                    onPick: () async {
                      final picked = await UsStatePickerSheet.pick(
                        context,
                        selectedCode: null,
                      );
                      if (picked == null) return;
                      final profile = state.profile;
                      await context
                          .read<AppState>()
                          .profileController
                          .updateProfile(
                            profile.copyWith(
                              state: picked,
                              updatedAt: DateTime.now(),
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _SectionHeader(
                  title: 'NATIONAL RESOURCES',
                  subtitle: 'Common national organizations and tools',
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._buildCards(context, national, limit: 16),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCards(
    BuildContext context,
    List<Resource> list, {
    required int limit,
  }) {
    final trimmed = list.take(limit).toList();
    if (trimmed.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return [
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Text(
            'No resources match the current filters. Adjust the filters or verify this requirement with the appropriate certifying authority or training provider.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ];
    }

    return trimmed
        .map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ResourceCard(resource: r),
          ),
        )
        .toList();
  }
}

class _RequirementResourcesView extends StatelessWidget {
  final String? requirementKey;
  final Set<ResourceType> typeFilter;
  final TextEditingController searchController;

  const _RequirementResourcesView({
    required this.requirementKey,
    required this.typeFilter,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final userState = FireOpsCatalog.stateCodeFromLegacyValue(
      context.watch<AppState>().profile.state,
    );
    return ValueListenableBuilder(
      valueListenable: searchController,
      builder: (context, value, _) {
        final cs = Theme.of(context).colorScheme;
        final key = requirementKey?.trim();
        final items = FireOpsCatalog.resources();

        bool match(Resource r) {
          final q = value.text.trim().toLowerCase();
          final defs = FireOpsCatalog.certificationById();
          final relatedNames = r.relatedCertificationDefinitionIds
              .map((id) => defs[id]?.displayName ?? id)
              .join(' ');
          final blob = '${r.title} ${r.description} $relatedNames'
              .toLowerCase();
          final keyOk = key == null || key.isEmpty
              ? true
              : r.relatedCertificationDefinitionIds.contains(key) ||
                    blob.contains(key.toLowerCase());
          final qOk = q.isEmpty ? true : blob.contains(q);
          final typeOk = typeFilter.isEmpty
              ? true
              : typeFilter.contains(r.type);
          return keyOk && qOk && typeOk;
        }

        final filtered = items
            .where(
              (r) => r.url?.trim().isNotEmpty == true && match(r),
            )
            .where((r) {
              if (userState == null || userState.trim().isEmpty) {
                return r.state == null;
              }
              return r.state == null || r.state == userState;
            })
            .toList();
        filtered.sort((a, b) {
          if (a.type != b.type) return a.type.index.compareTo(b.type.index);
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });

        final title = key == null || key.isEmpty ? 'Resources' : key;
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton.toHome(),
            title: Text(title),
          ),
          body: SafeArea(
            child: ListView(
              padding: AppSpacing.paddingLg,
              children: [
                Text(
                  'Filtered resources',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Training, official requirements, study, and practice links for this requirement.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SearchBar(controller: searchController),
                const SizedBox(height: AppSpacing.lg),
                if (filtered.isEmpty)
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      'No mapped resources match this requirement and filter. Verify current information with the appropriate certifying authority or training provider.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ResourceCard(resource: r),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search resources…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  FocusScope.of(context).unfocus();
                  // Trigger rebuild in parent via inherited listeners (controller notifies).
                },
                icon: const Icon(Icons.close),
              ),
      ),
      onChanged: (_) {},
    );
  }
}

class _FilterChips extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const _FilterChips({required this.selected, required this.onToggle});

  static const _chips = [
    'Task Book',
    'Official',
    'Training',
    'Study',
    'Practice',
    'Fire',
    'EMS',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final label = _chips[index];
          final isOn = selected.contains(label);
          return FilterChip(
            selected: isOn,
            label: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isOn ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            onSelected: (_) => onToggle(label),
            showCheckmark: false,
            selectedColor: cs.primaryContainer,
            backgroundColor: cs.surface,
            side: BorderSide(color: cs.outline.withValues(alpha: 0.14)),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class ResourceCard extends StatelessWidget {
  final Resource resource;
  const ResourceCard({super.key, required this.resource});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = resource.url;
    final profileState = FireOpsCatalog.stateCodeFromLegacyValue(
      context.read<AppState>().profile.state,
    );
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(_iconFor(resource.type), color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  resource.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: url == null
                ? null
                : () => _openResourceUrl(
                    context,
                    resource,
                    profileStateCode: profileState,
                  ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(ResourceType t) {
    return switch (t) {
      ResourceType.officialStateAgency ||
      ResourceType.officialFederalAgency => Icons.verified_outlined,
      ResourceType.credentialingOrganization => Icons.badge_outlined,
      ResourceType.trainingProvider ||
      ResourceType.courseFinder => Icons.school,
      ResourceType.collegeAcademy => Icons.account_balance_outlined,
      ResourceType.professionalOrganization => Icons.groups_2_outlined,
      ResourceType.studyResource => Icons.menu_book,
      ResourceType.practiceResource => Icons.fitness_center,
      ResourceType.fireOpsTool => Icons.bolt,
      ResourceType.departmentResource => Icons.apartment,
    };
  }

  static Future<void> _openResourceUrl(
    BuildContext context,
    Resource resource, {
    required String? profileStateCode,
  }) async {
    final url = resource.url;
    if (url == null || url.trim().isEmpty) return;

    final stateOnly = resource.state?.trim().toUpperCase();
    final profileState = profileStateCode?.trim().toUpperCase();
    if (stateOnly != null && stateOnly.isNotEmpty) {
      if (profileState == null || profileState.isEmpty) {
        final picked = await UsStatePickerSheet.pick(context, selectedCode: null);
        if (picked == null) return;
        try {
          final app = context.read<AppState>();
          await app.profileController.updateProfile(
            app.profile.copyWith(state: picked, updatedAt: DateTime.now()),
          );
        } catch (e) {
          debugPrint('Failed to save picked state before opening resource: $e');
        }
      } else if (profileState != stateOnly) {
        // Avoid surprising mismatched state links.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This link is for $stateOnly. Your profile is set to $profileState.',
            ),
          ),
        );
      }
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      debugPrint('Invalid URL: $url');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) debugPrint('launchUrl failed for $url');
  }
}

class _PickStateCard extends StatelessWidget {
  final Future<void> Function() onPick;
  const _PickStateCard({required this.onPick});

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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.public, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select your state',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'We’ll prioritize the correct official requirements and training links for your area.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: () => onPick(),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: const Text('Pick'),
          ),
        ],
      ),
    );
  }
}
