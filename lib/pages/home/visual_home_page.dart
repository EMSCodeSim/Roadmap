import 'package:firepath/pages/department/department_classes_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/home_section_preference.dart';
import 'package:firepath/services/career_inbox.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/certification_urgency.dart';
import 'package:firepath/services/home_section_preferences_store.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/widgets/app_card_tile.dart';
<<<<<<< Updated upstream
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';
=======
<<<<<<< Updated upstream
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';
=======
import 'package:firepath/widgets/unread_pulse_indicator.dart';
import 'package:firepath/widgets/public_safety_metric_tile.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/compact_page_header.dart';
import 'package:firepath/widgets/modern_motion.dart';
>>>>>>> Stashed changes
>>>>>>> Stashed changes

/// A compact daily overview. Lifelong history lives in Career Timeline.
class VisualHomePage extends StatefulWidget {
  const VisualHomePage({super.key});

  @override
  State<VisualHomePage> createState() => _VisualHomePageState();
}

class _VisualHomePageState extends State<VisualHomePage>
    with AutomaticKeepAliveClientMixin {
  final CareerRecordStore _recordStore = CareerRecordStore();
  final HomeSectionPreferencesStore _homeSectionStore =
      HomeSectionPreferencesStore();
  List<CareerRecord> _records = const [];
  List<HomeSectionPreference> _homeSections =
      List<HomeSectionPreference>.from(HomeSectionPreferencesStore.defaults);
  bool _loadingRecords = true;

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
      _loadingRecords = false;
    });
  }

  Future<void> _loadHomeSections() async {
    final sections = await _homeSectionStore.load();
    if (!mounted) return;
    setState(() => _homeSections = sections);
  }

  Future<void> _refresh() async {
    await Future.wait([_loadRecords(), _loadHomeSections()]);
  }

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
    final credentials = CertificationUrgency.urgent(
      app.certifications,
      withinDays: 90,
    );
    final now = DateTime.now();
    final monthRecords = _records
        .where((record) =>
            record.date.year == now.year && record.date.month == now.month)
        .toList();
    final monthHours = monthRecords.fold<double>(
      0,
      (total, record) => total + (record.hours ?? 0),
    );
    final followUps = CareerInbox.build(app: app, records: _records)
        .where((item) => item.kind != CareerInboxKind.certification)
        .toList(growable: false);
    final attentionCount = credentials.length + followUps.length;
    final currentCredentialCount = app.certifications
        .where((c) => c.status == CertificationStatus.current)
        .length;
    final nextStepTitle = nextStep?.requirement.name ??
        (roadmap == null ? 'Choose a goal when you are ready' : 'Your roadmap is caught up');
    final nextStepSubtitle = nextStep == null
        ? 'Keep documenting the work that is shaping your career.'
        : 'Open training, study, official, and practice resources for this step.';

<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
    bool isVisible(HomeSectionType type) {
      for (final preference in _homeSections) {
        if (preference.type == type) return preference.visible;
      }
      return false;
    }

    final recentRecords = List<CareerRecord>.from(_records)
      ..sort((a, b) => b.date.compareTo(a.date));

    final todayCards = <Widget>[
      if (isVisible(HomeSectionType.needsAttention))
        _HomeGridCard(
          icon: Icons.notifications_active_outlined,
          title: 'Needs Attention',
          detail: attentionCount == 0
              ? 'Nothing needs action'
              : '$attentionCount item${attentionCount == 1 ? '' : 's'} to review',
          value: '$attentionCount',
          accent: colors.error,
          onTap: () => context.push(AppRoutes.needsAttention),
        ),
      if (isVisible(HomeSectionType.dailyQuiz))
        _HomeGridCard(
          icon: Icons.quiz_outlined,
          title: 'Daily Quiz',
          detail: 'Five-minute EMS quiz',
          accent: const Color(0xFF2563EB),
          onTap: () => _openExternal(
            Uri.parse('https://emscodesim.com/quiz/'),
          ),
        ),
      _HomeGridCard(
        icon: Icons.add_circle_outline_rounded,
        title: 'Quick Add',
        detail: 'Log a call, skill or training',
        accent: const Color(0xFF7C3AED),
        onTap: () async {
          await QuickLogLauncher.open(context);
          await _loadRecords();
        },
<<<<<<< Updated upstream
      ),
      if (isVisible(HomeSectionType.trainingIdeas))
        _HomeGridCard(
          icon: Icons.school_outlined,
          title: 'Training Ideas',
          detail: 'Fire and EMS resources',
          accent: const Color(0xFFEA580C),
          onTap: _openTrainingIdeas,
        ),
    ];

    final optionalCards = <Widget>[
      if (isVisible(HomeSectionType.careerSnapshot))
        _HomeGridCard(
          icon: Icons.insights_outlined,
          title: 'Career Snapshot',
          detail:
              '${monthRecords.length} activities · ${monthHours == 0 ? '—' : monthHours.toStringAsFixed(monthHours == monthHours.roundToDouble() ? 0 : 1)} hours',
          value: '$currentCredentialCount',
          valueLabel: 'credentials',
          accent: const Color(0xFF7C3AED),
          onTap: () => context.go(AppRoutes.training),
        ),
      if (isVisible(HomeSectionType.jobSearch))
        _HomeGridCard(
          icon: Icons.work_outline_rounded,
          title: 'Job Search',
          detail: 'Review saved search findings',
          accent: const Color(0xFF0F766E),
          onTap: () => context.push(AppRoutes.jobSearch),
        ),
      if (isVisible(HomeSectionType.department) && hasDepartment)
        _HomeGridCard(
          icon: Icons.apartment_rounded,
          title: 'Department',
          detail: department.unreadCount == 0
              ? 'No unread updates'
              : '${department.unreadCount} unread update${department.unreadCount == 1 ? '' : 's'}',
          value: department.actionCount > 0
              ? '${department.actionCount}'
              : null,
          accent: const Color(0xFFDC2626),
          onTap: () => context.go(AppRoutes.department),
        ),
    ];
=======
      ),
      if (isVisible(HomeSectionType.trainingIdeas))
        _HomeGridCard(
          icon: Icons.school_outlined,
          title: 'Training Ideas',
          detail: 'Fire and EMS resources',
          accent: const Color(0xFFEA580C),
          onTap: _openTrainingIdeas,
        ),
    ];

    final optionalCards = <Widget>[
      if (isVisible(HomeSectionType.careerSnapshot))
        _HomeGridCard(
          icon: Icons.insights_outlined,
          title: 'Career Snapshot',
          detail:
              '${monthRecords.length} activities · ${monthHours == 0 ? '—' : monthHours.toStringAsFixed(monthHours == monthHours.roundToDouble() ? 0 : 1)} hours',
          value: '$currentCredentialCount',
          valueLabel: 'credentials',
          accent: const Color(0xFF7C3AED),
          onTap: () => context.go(AppRoutes.training),
        ),
      if (isVisible(HomeSectionType.jobSearch))
        _HomeGridCard(
          icon: Icons.work_outline_rounded,
          title: 'Job Search',
          detail: 'Review saved search findings',
          accent: const Color(0xFF0F766E),
          onTap: () => context.push(AppRoutes.jobSearch),
        ),
      if (isVisible(HomeSectionType.department) && hasDepartment)
        _HomeGridCard(
          icon: Icons.apartment_rounded,
          title: 'Department',
          detail: department.unreadCount == 0
              ? 'No unread updates'
              : '${department.unreadCount} unread update${department.unreadCount == 1 ? '' : 's'}',
          value: department.actionCount > 0
              ? '${department.actionCount}'
              : null,
          accent: const Color(0xFFDC2626),
          onTap: () => context.go(AppRoutes.department),
        ),
    ];
=======
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
            context.push(AppRoutes.getStarted, extra: nextStep.requirement);
            return;
          }
          context.go(AppRoutes.careerGoals);
        },
      ),
      HomeSectionType.needsAttention: _NeedsAttentionCard(
        urgentCredentials: credentials.length,
        followUps: followUps.length,
        departmentActions: hasDepartment ? department.actionCount : 0,
        departmentUnread: hasDepartment ? department.unreadCount : 0,
        onReviewCredentials: () => context.go(AppRoutes.certifications),
        onReviewRecords: () => context.go(AppRoutes.training),
        onOpenDepartment: hasDepartment ? () => context.go(AppRoutes.department) : null,
        loadingRecords: _loadingRecords,
      ),
      HomeSectionType.careerSnapshot: _CareerSnapshotRow(
        activities: monthRecords.length,
        hours: monthHours,
        credentials: currentCredentialCount,
      ),
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
        onOpenEms: () => _openExternal(Uri.parse('https://emscodesim.com/ems-training-library.html')),
        onOpenFire: () => _openExternal(Uri.parse('https://fireopssim.com/drill-library')),
        onShowAnother: _openTrainingIdeas,
      ),
      HomeSectionType.department: _DepartmentMiniCard(
        unread: department.unreadCount,
        actionCount: department.actionCount,
        onOpen: () => context.go(AppRoutes.department),
      ),
    };
>>>>>>> Stashed changes

    final greeting = _greetingFor(DateTime.now());
    final primaryRole = (app.profile.currentRoles.isEmpty
            ? 'Responder'
            : app.profile.currentRoles.first)
        .trim();
    final roadmapPill = roadmap == null
        ? HeaderPill(icon: Icons.flag_outlined, label: 'Set a goal', color: colors.secondary)
        : HeaderPill(
            icon: Icons.trending_up_rounded,
            label: '${(roadmap.percentComplete * 100).round()}% goal',
            color: Theme.of(context).brightness == Brightness.dark ? DarkModeColors.growthPurple : LightModeColors.growthPurple,
          );
>>>>>>> Stashed changes

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
<<<<<<< Updated upstream
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (isVisible(HomeSectionType.goal)) ...[
              _sectionTitle(
                context,
                'Career Goal',
                actionLabel: roadmap == null ? null : 'View Roadmap',
                onAction: roadmap == null
                    ? null
                    : () => context.go(AppRoutes.myPathLegacy),
              ),
              _CareerGoalHomeCard(
                title: app.selectedGoal?.title ?? 'Choose your career goal',
                completed: roadmap?.completedCount ?? 0,
                total: roadmap?.totalCount ?? 0,
                progress: roadmap?.percentComplete ?? 0,
                onTap: () => context.go(AppRoutes.myPathLegacy),
              ),
              const SizedBox(height: 20),
            ],
            if (isVisible(HomeSectionType.nextStep)) ...[
              _sectionTitle(context, 'Next Best Step'),
              _NextBestStepHomeCard(
                title: nextStepTitle,
                detail: nextStepSubtitle,
                enabled: roadmap != null,
                onTap: () {
                  if (roadmap == null) {
                    context.go(AppRoutes.goalSetup);
                    return;
                  }
                  if (nextStep != null) {
                    AppRouter.openRoadmapPrimaryAction(
                      context,
                      nextStep.requirement,
                      goalId: roadmap.goal.id,
                    );
                    return;
                  }
                  context.go(AppRoutes.careerGoals);
                },
              ),
              const SizedBox(height: 20),
            ],
            if (todayCards.isNotEmpty) ...[
              _sectionTitle(context, 'Today'),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 142,
                ),
                children: todayCards,
              ),
              const SizedBox(height: 20),
            ],
            if (optionalCards.isNotEmpty) ...[
              _sectionTitle(context, 'More'),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 132,
                ),
                children: optionalCards,
              ),
              const SizedBox(height: 20),
            ],
            if (!_loadingRecords && recentRecords.isNotEmpty) ...[
              _sectionTitle(
                context,
                'Recent Activity',
                actionLabel: 'View all',
                onAction: () => context.go(AppRoutes.training),
              ),
              for (final record in recentRecords.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: AppCardTile(
                    icon: _recordIcon(record),
                    title: record.title,
                    subtitle:
                        '${_recordTypeLabel(record)} · ${_formatRecordDate(record.date)}',
                    onTap: () => context.go(AppRoutes.training),
                  ),
                ),
            ],
<<<<<<< Updated upstream
=======
=======
        child: CustomScrollView(
          key: const PageStorageKey('visual_home_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: CompactPageHeader(
                  title: '$greeting',
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
                    if (_homeSections[i].visible &&
                        (_homeSections[i].type != HomeSectionType.department || hasDepartment)) ...[
                      FadeSlideIn(
                        delay: Duration(milliseconds: 30 * i),
                        child: sectionWidgets[_homeSections[i].type]!,
                      ),
                      const SizedBox(height: 14),
                    ],
                ]),
              ),
            ),
>>>>>>> Stashed changes
>>>>>>> Stashed changes
          ],
        ),
      ),
    );
  }

<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
  IconData _recordIcon(CareerRecord record) {
    return switch (record.type) {
      CareerRecordType.operationalExperience =>
        Icons.local_fire_department_outlined,
      CareerRecordType.skill => Icons.handyman_outlined,
      CareerRecordType.training => Icons.school_outlined,
      CareerRecordType.achievement => Icons.emoji_events_outlined,
      CareerRecordType.leadership => Icons.groups_outlined,
      CareerRecordType.teaching => Icons.co_present_outlined,
      CareerRecordType.project => Icons.task_alt_outlined,
      CareerRecordType.education => Icons.menu_book_outlined,
      CareerRecordType.taskBookEvidence => Icons.fact_check_outlined,
    };
  }

  String _recordTypeLabel(CareerRecord record) => record.type.label;

  String _formatRecordDate(DateTime date) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      );
=======
  String _greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 5) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
>>>>>>> Stashed changes

  Future<void> _openExternal(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this resource.')),
      );
    }
  }

  Future<void> _openTrainingIdeas() async {
    final destination = await showModalBottomSheet<Uri>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose training ideas',
              style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: const Text('FireOpsSim drill library'),
              subtitle: const Text('Fire drills, scenarios and crew practice'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => Navigator.pop(
                sheetContext,
                Uri.parse('https://fireopssim.com/drill-library'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('EMSCodeSim training library'),
              subtitle: const Text('EMT and paramedic practice resources'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => Navigator.pop(
                sheetContext,
                Uri.parse(
                  'https://emscodesim.com/ems-training-library.html',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (destination != null && mounted) {
      await _openExternal(destination);
    }
  }

  // _statusCard removed in favor of shared AppCardTile.
}

<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
class _CareerGoalHomeCard extends StatelessWidget {
  const _CareerGoalHomeCard({
    required this.title,
    required this.completed,
    required this.total,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final int completed;
  final int total;
  final double progress;
  final VoidCallback onTap;
<<<<<<< Updated upstream
=======
=======
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
>>>>>>> Stashed changes
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
    const accent = Color(0xFF7C3AED);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.flag_outlined, color: accent),
                  ),
                  const SizedBox(width: 13),
<<<<<<< Updated upstream
=======
=======
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.1),
                ),
              ),
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

  const _HomeGoalCard({
    required this.goalTitle,
    required this.percent,
    required this.completed,
    required this.total,
    required this.onViewRoadmap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark ? DarkModeColors.growthPurple : LightModeColors.growthPurple;
    final effectivePercent = (percent ?? 0).toDouble().clamp(0.0, 1.0);
    final progressLabel = (total ?? 0) <= 0
        ? 'No requirements yet'
        : '${completed ?? 0} of ${total ?? 0} complete';

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
>>>>>>> Stashed changes
>>>>>>> Stashed changes
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          total == 0
                              ? 'Build your personal career plan'
                              : '$completed of $total complete',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    color: accent,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              ],
<<<<<<< Updated upstream
=======
=======
                        Text(goalTitle ?? 'Choose your career destination', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900), maxLines: 2, overflow: TextOverflow.ellipsis),
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
>>>>>>> Stashed changes
>>>>>>> Stashed changes
            ],
          ),
        ),
      ),
    );
  }
}

<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
class _NextBestStepHomeCard extends StatelessWidget {
  const _NextBestStepHomeCard({
    required this.title,
    required this.detail,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String detail;
  final bool enabled;
  final VoidCallback onTap;
<<<<<<< Updated upstream
=======
=======
class _NextBestStepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? effortMinutes;
  final VoidCallback onOpen;

  const _NextBestStepCard({required this.title, required this.subtitle, required this.effortMinutes, required this.onOpen});
>>>>>>> Stashed changes
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
    const accent = Color(0xFF2563EB);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: accent),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: onTap,
                      icon: Icon(
                        enabled
                            ? Icons.play_arrow_rounded
                            : Icons.flag_outlined,
                      ),
                      label: Text(enabled ? 'Start' : 'Choose goal'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeGridCard extends StatelessWidget {
  const _HomeGridCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.accent,
    required this.onTap,
    this.value,
    this.valueLabel,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color accent;
  final VoidCallback onTap;
  final String? value;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.30)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: accent, size: 21),
                  ),
                  const Spacer(),
                  if (value != null)
                    Container(
                      constraints: const BoxConstraints(minWidth: 30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        value!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                valueLabel == null ? detail : '$detail · $valueLabel',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.25,
                ),
<<<<<<< Updated upstream
=======
=======
    final accent = Theme.of(context).brightness == Brightness.dark ? DarkModeColors.trainingBlue : LightModeColors.trainingBlue;
    final effortLabel = (effortMinutes ?? 0) > 0 ? '≈ ${effortMinutes} min' : null;

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
                        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.25, fontWeight: FontWeight.w600)),
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
>>>>>>> Stashed changes
>>>>>>> Stashed changes
              ),
            ],
          ),
        ),
      ),
    );
  }
}

<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
=======
class _NeedsAttentionCard extends StatelessWidget {
  final int urgentCredentials;
  final int followUps;
  final int departmentActions;
  final int departmentUnread;
  final VoidCallback onReviewCredentials;
  final VoidCallback onReviewRecords;
  final VoidCallback? onOpenDepartment;
  final bool loadingRecords;

  const _NeedsAttentionCard({
    required this.urgentCredentials,
    required this.followUps,
    required this.departmentActions,
    required this.departmentUnread,
    required this.onReviewCredentials,
    required this.onReviewRecords,
    required this.onOpenDepartment,
    required this.loadingRecords,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final urgent = urgentCredentials > 0;
    final attentionColor = urgent
        ? cs.error
        : (Theme.of(context).brightness == Brightness.dark ? DarkModeColors.drivingAmber : LightModeColors.drivingAmber);
    final total = urgentCredentials + (loadingRecords ? 0 : followUps) + (onOpenDepartment == null ? 0 : departmentActions);

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
                  Expanded(
                    child: Text(
                      total == 0 ? "You're caught up" : '$total item${total == 1 ? '' : 's'} need a next step',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          row(
            icon: Icons.verified_outlined,
            label: 'Credentials',
            count: urgentCredentials,
            onTap: onReviewCredentials,
            color: urgentCredentials > 0 ? cs.error : FireOpsSemanticColors.green,
          ),
          const SizedBox(height: 10),
          row(
            icon: Icons.history_rounded,
            label: loadingRecords ? 'Records (loading…) ' : 'Records follow-ups',
            count: loadingRecords ? 0 : followUps,
            onTap: onReviewRecords,
            color: Theme.of(context).brightness == Brightness.dark ? DarkModeColors.trainingBlue : LightModeColors.trainingBlue,
          ),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(bodyTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(bodySubtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.25, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              if (meta != null) HeaderPill(icon: meta!.icon, label: meta!.label, color: accent),
              const Spacer(),
              SizedBox(height: AppTouchTargets.minButtonHeight, child: FilledButton(onPressed: onPrimary, child: Text(primaryLabel))),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _TrainingIdeasCard extends StatelessWidget {
  final VoidCallback onOpenFire;
  final VoidCallback onOpenEms;
  final VoidCallback onShowAnother;

  const _TrainingIdeasCard({required this.onOpenFire, required this.onOpenEms, required this.onShowAnother});

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
                    Row(children: [
                      SizedBox(height: 44, child: FilledButton.tonalIcon(onPressed: onOpen, icon: const Icon(Icons.open_in_new_rounded), label: const Text('Open Resource'))),
                      const SizedBox(width: 10),
                      SizedBox(height: 44, child: OutlinedButton.icon(onPressed: onShowAnother, icon: const Icon(Icons.shuffle_rounded), label: const Text('Show Another'))),
                    ]),
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
        trailing: unread > 0
            ? const Row(mainAxisSize: MainAxisSize.min, children: [UnreadPulseIndicator(), SizedBox(width: 8), Icon(Icons.chevron_right_rounded)])
            : null,
        onTap: onOpen,
      ),
    );
  }
}
>>>>>>> Stashed changes
>>>>>>> Stashed changes
