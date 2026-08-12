import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/career_stats.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/timeline_planner.dart';
import 'package:firepath/services/task_book_setup_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/pages/profile/us_state_picker_sheet.dart';

class VisualHomePage extends StatefulWidget {
  const VisualHomePage({super.key});

  @override
  State<VisualHomePage> createState() => _VisualHomePageState();
}

class _VisualHomePageState extends State<VisualHomePage> {
  bool _promptQueued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_promptQueued) return;
    _promptQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybePromptForMissingState();
    });
  }

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
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'What state do you primarily work in?',
                style: Theme.of(sheetContext)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
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
    final certs = state.certifications;
    final timelinePlan = roadmap == null ? null : CareerTimelinePlanner.build(state);

    final currentLevel = profile.currentRoles.isEmpty
        ? 'Set your current level'
        : profile.currentRoles.join(' / ');

    final currentCount = certs
        .where((cert) => cert.status == CertificationStatus.current)
        .length;
    final expiringCount = certs
        .where((cert) => cert.status == CertificationStatus.expiringSoon)
        .length;
    final expiredCount = certs
        .where((cert) => cert.status == CertificationStatus.expired)
        .length;

    final datedCerts = certs
        .where((cert) => !cert.doesNotExpire && cert.expirationDate != null)
        .toList()
      ..sort((a, b) => a.expirationDate!.compareTo(b.expirationDate!));
    final nextExpiration = datedCerts
        .where((cert) => !cert.expirationDate!.isBefore(_today()))
        .firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            const _GraphicHeader(),
            const SizedBox(height: 14),
            _CurrentLevelCard(
              level: currentLevel,
              serviceType: profile.serviceType,
              yearsOfService: profile.yearsOfService,
              stateCode: profile.state,
              onTap: () => _showEditCurrentLevelSheet(context, state),
            ),
            const SizedBox(height: 12),
            _GoalCard(
              goalTitle: roadmap?.goal.title,
              targetDate: profile.careerPlan.targetDate,
              completed: roadmap?.completedCount ?? 0,
              total: roadmap?.totalCount ?? 0,
              nextStep: roadmap?.nextStep?.requirement.name,
              timelineStatus: timelinePlan?.status,
              onTap: () => context.go(AppRoutes.myPath),
            ),
            const SizedBox(height: 12),
            _CertificationsCard(
              total: certs.length,
              current: currentCount,
              expiring: expiringCount,
              expired: expiredCount,
              nextExpirationName: nextExpiration == null
                  ? null
                  : state.certificationDisplayName(nextExpiration),
              nextExpirationDate: nextExpiration?.expirationDate,
              nextExpirationDays: nextExpiration?.daysRemaining,
              onTap: () => context.go(AppRoutes.certifications),
            ),
            const SizedBox(height: 12),
            const _QuickLogCard(),
          ],
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
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleLarge
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
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .titleSmall
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
                                    textCapitalization: TextCapitalization.words,
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
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Changing your state may change state-specific Task Book recommendations and certification requirements.'),
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
                                      (years == null || years < 0 || years > 80)) {
                                    ScaffoldMessenger.of(sheetContext)
                                        .showSnackBar(
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
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
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
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleMedium
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
                    Text('State', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
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
  const _GraphicHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 2.25,
            child: Image.asset(
              'assets/graphics/career_road_banner_v2.jpg',
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Container(
                color: FireOpsSemanticColors.headerDark,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.route_outlined,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 12,
                    offset: Offset(0, 4),
                    color: Color(0x33000000),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/icons/career_road_icon_v2.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
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
              if (targetDate != null) 'Target: ${_formatMonthYear(targetDate!)}',
            ].join(' • ')
          : 'Choose a career goal and FireOps will build your path.',
      emphasisText: hasGoal && nextStep != null ? 'Next: $nextStep' : null,
      progress: hasGoal ? progress : null,
      status: status,
      actionLabel: hasGoal ? 'Open Task Book' : 'Choose Goal',
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
      detail = expired == 1 ? '1 certification expired' : '$expired certifications expired';
    } else if (nextExpirationName != null &&
        nextExpirationDate != null &&
        nextExpirationDays != null &&
        nextExpirationDays! <= 90) {
      final dayLabel = nextExpirationDays == 1 ? 'day' : 'days';
      detail = '$nextExpirationName expires in $nextExpirationDays $dayLabel • '
          '${_formatDate(nextExpirationDate!)}';
    } else if (total == 0) {
      detail = 'Add the certifications you already hold.';
    } else {
      detail = 'All tracked certifications are current';
    }

    return _HomeCard(
      icon: Icons.verified_outlined,
      eyebrow: 'CERTIFICATIONS',
      title: total == 0 ? 'Start your credential record' : '$total tracked',
      subtitle: total == 0 ? 'Add certifications to track renewals.' : '$current Current • $expiring Expiring',
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
            snapshot.connectionState == ConnectionState.waiting && summary == null;

        final subtitle = 'Record something you did today.';
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
      _StatusTone.neutral =>
        (cs.surfaceContainerHighest, cs.onSurfaceVariant),
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
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.7),
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
