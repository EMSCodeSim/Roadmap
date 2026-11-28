import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/home_section_preference.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/certification_urgency.dart';
import 'package:firepath/services/home_section_preferences_store.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/widgets/app_card_tile.dart';
import 'package:firepath/widgets/compact_page_header.dart';
import 'package:firepath/widgets/modern_motion.dart';
import 'package:firepath/widgets/public_safety_metric_tile.dart';
import 'package:firepath/widgets/unread_pulse_indicator.dart';

/// A compact daily overview. Lifelong history lives in Career Timeline.
class VisualHomePage extends StatefulWidget {
  const VisualHomePage({super.key});

  @override
  State<VisualHomePage> createState() => _VisualHomePageState();
}

class _VisualHomePageState extends State<VisualHomePage> with AutomaticKeepAliveClientMixin {
  final CareerRecordStore _recordStore = CareerRecordStore();
  final HomeSectionPreferencesStore _homeSectionStore = HomeSectionPreferencesStore();

  List<CareerRecord> _records = const [];
  List<HomeSectionPreference> _homeSections = List<HomeSectionPreference>.from(HomeSectionPreferencesStore.defaults);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _loadHomeSections();
  }

  Future<void> _loadRecords() async {
    final records = await _recordStore.load();
    if (!mounted) return;
    setState(() {
      _records = records;
    });
  }

  Future<void> _loadHomeSections() async {
    final sections = await _homeSectionStore.load();
    if (!mounted) return;
    setState(() => _homeSections = sections);
  }

  Future<void> _refresh() async => Future.wait([_loadRecords(), _loadHomeSections()]);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final app = context.watch<AppState>();
    final appMode = context.watch<AppModeController>();
    final department = context.watch<DepartmentInboxController>();
    final colors = Theme.of(context).colorScheme;

    final roadmap = app.roadmap;
    final nextStep = roadmap?.nextStep;
    final hasDepartment = appMode.departmentLink != null;

    final credentials = CertificationUrgency.urgent(app.certifications, withinDays: 90);
    final now = DateTime.now();
    final monthRecords = _records.where((record) => record.date.year == now.year && record.date.month == now.month).toList();
    final monthHours = monthRecords.fold<double>(0, (total, record) => total + (record.hours ?? 0));
    final currentCredentialCount = app.certifications.where((c) => c.status == CertificationStatus.current).length;

    final nextStepTitle = nextStep?.requirement.name ?? (roadmap == null ? 'Choose a goal when you are ready' : 'Your roadmap is caught up');
    final nextStepSubtitle = nextStep == null ? 'Keep documenting the work that is shaping your career.' : 'Open the same requirement and skills checklist used in your Roadmap.';

    final sectionWidgets = <HomeSectionType, Widget>{
      HomeSectionType.goal: _HomeGoalCard(
        goalTitle: app.selectedGoal?.title,
        percent: roadmap?.percentComplete,
        completed: roadmap?.completedCount,
        total: roadmap?.totalCount,
        onViewRoadmap: () => context.go(roadmap == null ? AppRoutes.goalSetup : AppRoutes.careerGoals),
      ),
      HomeSectionType.nextStep: _NextBestStepCard(
        title: nextStepTitle,
        subtitle: nextStepSubtitle,
        effortMinutes: null,
        onOpen: () {
          if (roadmap == null) {
            context.go(AppRoutes.goalSetup);
            return;
          }
          if (nextStep != null) {
            AppRouter.openRequirement(context, nextStep.requirement, goalId: roadmap.goal.id);
            return;
          }
          context.go(AppRoutes.careerGoals);
        },
      ),
      HomeSectionType.needsAttention: _NeedsAttentionCard(
        urgentCredentials: credentials.length,
        departmentActions: hasDepartment ? department.actionCount : 0,
        departmentUnread: hasDepartment ? department.unreadCount : 0,
        onReviewCredentials: () => context.go(AppRoutes.certifications),
        onOpenDepartment: hasDepartment ? () => context.go(AppRoutes.department) : null,
      ),
      HomeSectionType.careerSnapshot: _CareerSnapshotRow(activities: monthRecords.length, hours: monthHours, credentials: currentCredentialCount),
      HomeSectionType.jobSearch: _SimpleHomeCard(
        title: 'Job Search Findings',
        icon: Icons.work_outline_rounded,
        bodyTitle: 'Review jobs matching your saved search',
        bodySubtitle: 'Open verified fire and EMS listings without rebuilding your filters.',
        primaryLabel: 'Open',
        onPrimary: () => context.push(AppRoutes.jobSearch),
      ),
      HomeSectionType.dailyQuiz: _SimpleHomeCard(
        title: 'Daily Quiz',
        icon: Icons.quiz_outlined,
        bodyTitle: 'Five-minute quiz',
        bodySubtitle: 'A quick knowledge check from EMSCodeSim.',
        meta: const _CardMeta(icon: Icons.schedule_rounded, label: '≈ 5 min'),
        primaryLabel: 'Start Quiz',
        onPrimary: () => _openExternal(Uri.parse('https://emscodesim.com/quiz/')),
      ),
      HomeSectionType.trainingIdeas: _TrainingIdeasCard(
        onOpenEms: () => _openExternal(Uri.parse('https://emscodesim.com/roadmap/')),
        onOpenFire: () => _openExternal(Uri.parse('https://fireopssim.com/roadmap/')),
      ),
      HomeSectionType.department: _DepartmentMiniCard(
        unread: department.unreadCount,
        actionCount: department.actionCount,
        onOpen: () => context.go(AppRoutes.department),
      ),
    };

    final greeting = _greetingFor(DateTime.now());
    final primaryRole = (app.profile.currentRoles.isEmpty ? 'Responder' : app.profile.currentRoles.first).trim();
    final roadmapPill = roadmap == null
        ? HeaderPill(icon: Icons.flag_outlined, label: 'Set a goal', color: colors.secondary)
        : HeaderPill(
            icon: Icons.trending_up_rounded,
            label: '${(roadmap.percentComplete * 100).round()}% goal',
            color: Theme.of(context).brightness == Brightness.dark ? DarkModeColors.growthPurple : LightModeColors.growthPurple,
          );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          key: const PageStorageKey('visual_home_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: CompactPageHeader(
                  title: greeting,
                  subtitle: primaryRole.isEmpty ? null : primaryRole,
                  trailingPill: roadmapPill,
                  actions: [
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: () async {
                        await context.push(AppRoutes.settings);
                        if (mounted) await _loadHomeSections();
                      },
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  for (int i = 0; i < _homeSections.length; i++)
                    if (_homeSections[i].visible && (_homeSections[i].type != HomeSectionType.department || hasDepartment)) ...[
                      FadeSlideIn(delay: Duration(milliseconds: 30 * i), child: sectionWidgets[_homeSections[i].type] ?? const SizedBox.shrink()),
                      const SizedBox(height: 14),
                    ],
                  const SizedBox(height: 34),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 5) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _openExternal(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open this resource.')));
    }
  }

}

class _CardMeta {
  final IconData icon;
  final String label;
  const _CardMeta({required this.icon, required this.label});
}

class _HomeSectionFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _HomeSectionFrame({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.1))),
              if (trailing != null) DefaultTextStyle.merge(style: theme.textTheme.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800), child: trailing!),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _HomeGoalCard extends StatelessWidget {
  final String? goalTitle;
  final double? percent;
  final int? completed;
  final int? total;
  final VoidCallback onViewRoadmap;

  const _HomeGoalCard({required this.goalTitle, required this.percent, required this.completed, required this.total, required this.onViewRoadmap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark ? DarkModeColors.growthPurple : LightModeColors.growthPurple;
    final effectivePercent = (percent ?? 0).toDouble().clamp(0.0, 1.0);
    final progressLabel = (total ?? 0) <= 0 ? 'No requirements yet' : '${completed ?? 0} of ${total ?? 0} complete';

    return _HomeSectionFrame(
      title: 'Career goal',
      trailing: TextButton(onPressed: onViewRoadmap, child: const Text('View Roadmap')),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.flag_outlined, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goalTitle ?? 'Choose your career destination', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900), maxLines: 4),
                        const SizedBox(height: 6),
                        Text(progressLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: total == null || total == 0 ? null : effectivePercent,
                  minHeight: 10,
                  backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextBestStepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? effortMinutes;
  final VoidCallback onOpen;

  const _NextBestStepCard({required this.title, required this.subtitle, required this.effortMinutes, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark ? DarkModeColors.trainingBlue : LightModeColors.trainingBlue;
    final effortLabel = (effortMinutes ?? 0) > 0 ? '≈ $effortMinutes min' : null;

    return _HomeSectionFrame(
      title: 'Next best step',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.auto_awesome_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900), maxLines: 4),
                        const SizedBox(height: 6),
                        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.25, fontWeight: FontWeight.w600), maxLines: 5),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (effortLabel != null) ...[
                    HeaderPill(icon: Icons.schedule_rounded, label: effortLabel, color: accent),
                    const SizedBox(width: 10),
                  ],
                  const Spacer(),
                  SizedBox(
                    height: AppTouchTargets.minButtonHeight,
                    child: FilledButton.icon(
                      onPressed: onOpen,
                      icon: Icon(Icons.play_arrow_rounded, color: cs.onPrimary),
                      label: Text('Open', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onPrimary)),
                      style: FilledButton.styleFrom(backgroundColor: accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedsAttentionCard extends StatelessWidget {
  final int urgentCredentials;
  final int departmentActions;
  final int departmentUnread;
  final VoidCallback onReviewCredentials;
  final VoidCallback? onOpenDepartment;

  const _NeedsAttentionCard({
    required this.urgentCredentials,
    required this.departmentActions,
    required this.departmentUnread,
    required this.onReviewCredentials,
    required this.onOpenDepartment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final urgent = urgentCredentials > 0;
    final attentionColor = urgent ? cs.error : (Theme.of(context).brightness == Brightness.dark ? DarkModeColors.drivingAmber : LightModeColors.drivingAmber);
    final total = urgentCredentials +
        (onOpenDepartment == null ? 0 : departmentActions);

    Widget row({required IconData icon, required String label, required int count, required VoidCallback onTap, Color? color}) {
      final c = color ?? cs.primary;
      return AppCardTile(
        icon: icon,
        iconColor: c,
        iconBackground: c.withValues(alpha: 0.12),
        title: label,
        subtitle: count == 0 ? 'None' : '$count item${count == 1 ? '' : 's'}',
        trailing: TextButton(onPressed: onTap, child: const Text('Review')),
        onTap: onTap,
      );
    }

    return _HomeSectionFrame(
      title: 'Needs attention',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: total == 0 ? cs.surface : attentionColor.withValues(alpha: 0.07),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Icon(total == 0 ? Icons.check_circle_outline_rounded : Icons.notification_important_outlined, color: total == 0 ? FireOpsSemanticColors.green : attentionColor),
                  const SizedBox(width: 10),
                  Expanded(child: Text(total == 0 ? "You're caught up" : '$total item${total == 1 ? '' : 's'} need a next step', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          row(icon: Icons.verified_outlined, label: 'Credentials', count: urgentCredentials, onTap: onReviewCredentials, color: urgentCredentials > 0 ? cs.error : FireOpsSemanticColors.green),
          if (onOpenDepartment != null) ...[
            const SizedBox(height: 10),
            AppCardTile(
              icon: Icons.apartment_rounded,
              title: 'Department',
              subtitle: departmentActions == 0
                  ? (departmentUnread == 0 ? 'No actions waiting' : '$departmentUnread unread update${departmentUnread == 1 ? '' : 's'}')
                  : '$departmentActions action${departmentActions == 1 ? '' : 's'} waiting',
              trailing: departmentUnread > 0
                  ? const Row(mainAxisSize: MainAxisSize.min, children: [UnreadPulseIndicator(), SizedBox(width: 8), Icon(Icons.chevron_right_rounded)])
                  : null,
              onTap: onOpenDepartment,
            ),
          ],
        ],
      ),
    );
  }
}

class _CareerSnapshotRow extends StatelessWidget {
  final int activities;
  final double hours;
  final int credentials;

  const _CareerSnapshotRow({required this.activities, required this.hours, required this.credentials});

  @override
  Widget build(BuildContext context) {
    return _HomeSectionFrame(
      title: 'Career snapshot',
      child: Row(
        children: [
          Expanded(
            child: PublicSafetyMetricTile(
              icon: Icons.auto_awesome_rounded,
              accent: Theme.of(context).brightness == Brightness.dark ? DarkModeColors.growthPurple : LightModeColors.growthPurple,
              value: '$activities',
              label: 'This month',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PublicSafetyMetricTile(
              icon: Icons.schedule_rounded,
              accent: Theme.of(context).brightness == Brightness.dark ? DarkModeColors.trainingBlue : LightModeColors.trainingBlue,
              value: hours == 0 ? '—' : hours.toStringAsFixed(hours == hours.roundToDouble() ? 0 : 1),
              label: 'Hours',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PublicSafetyMetricTile(
              icon: Icons.verified_rounded,
              accent: Theme.of(context).brightness == Brightness.dark ? DarkModeColors.credentialGreen : LightModeColors.credentialGreen,
              value: '$credentials',
              label: 'Current',
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleHomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String bodyTitle;
  final String bodySubtitle;
  final _CardMeta? meta;
  final String primaryLabel;
  final VoidCallback onPrimary;

  const _SimpleHomeCard({
    required this.title,
    required this.icon,
    required this.bodyTitle,
    required this.bodySubtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.secondary;
    return _HomeSectionFrame(
      title: title,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bodyTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(bodySubtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.25, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (meta != null) HeaderPill(icon: meta!.icon, label: meta!.label, color: accent),
                  const Spacer(),
                  SizedBox(height: AppTouchTargets.minButtonHeight, child: FilledButton(onPressed: onPrimary, child: Text(primaryLabel))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingIdeasCard extends StatelessWidget {
  final VoidCallback onOpenFire;
  final VoidCallback onOpenEms;

  const _TrainingIdeasCard({required this.onOpenFire, required this.onOpenEms});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fire = Theme.of(context).brightness == Brightness.dark ? DarkModeColors.opsRed : LightModeColors.opsRed;
    final ems = Theme.of(context).brightness == Brightness.dark ? DarkModeColors.skillsTeal : LightModeColors.skillsTeal;

    Widget suggestion({required IconData icon, required Color color, required String source, required String title, required String subtitle, required VoidCallback onOpen}) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: cs.outline.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.25)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(height: 44, child: FilledButton.tonalIcon(onPressed: onOpen, icon: const Icon(Icons.open_in_new_rounded), label: const Text('Open Resource'))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _HomeSectionFrame(
      title: 'Training ideas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          suggestion(
            icon: Icons.local_fire_department_outlined,
            color: fire,
            source: 'FireOpsSim',
            title: 'Drill library',
            subtitle: 'Quick scenarios you can run with a crew or solo.',
            onOpen: onOpenFire,
          ),
          const SizedBox(height: 10),
          suggestion(
            icon: Icons.medical_services_outlined,
            color: ems,
            source: 'EMSCodeSim',
            title: 'Training library',
            subtitle: 'Targeted practice for EMT and paramedic concepts.',
            onOpen: onOpenEms,
          ),
        ],
      ),
    );
  }
}

class _DepartmentMiniCard extends StatelessWidget {
  final int unread;
  final int actionCount;
  final VoidCallback onOpen;

  const _DepartmentMiniCard({required this.unread, required this.actionCount, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _HomeSectionFrame(
      title: 'Department',
      trailing: TextButton(onPressed: onOpen, child: const Text('Open')),
      child: AppCardTile(
        icon: Icons.apartment_rounded,
        title: actionCount == 0 ? 'No department actions waiting' : '$actionCount item${actionCount == 1 ? '' : 's'} need attention',
        subtitle: unread == 0 ? 'Department requests and updates appear here.' : '$unread unread update${unread == 1 ? '' : 's'}',
        trailing: unread > 0 ? const Row(mainAxisSize: MainAxisSize.min, children: [UnreadPulseIndicator(), SizedBox(width: 8), Icon(Icons.chevron_right_rounded)]) : null,
        onTap: onOpen,
      ),
    );
  }
}
