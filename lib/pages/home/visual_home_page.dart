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
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';

/// A compact daily overview. Lifelong history lives in Career Timeline.
class VisualHomePage extends StatefulWidget {
  const VisualHomePage({super.key});

  @override
  State<VisualHomePage> createState() => _VisualHomePageState();
}

class _VisualHomePageState extends State<VisualHomePage> {
  final CareerRecordStore _recordStore = CareerRecordStore();
  final HomeSectionPreferencesStore _homeSectionStore =
      HomeSectionPreferencesStore();
  List<CareerRecord> _records = const [];
  List<HomeSectionPreference> _homeSections =
      List<HomeSectionPreference>.from(HomeSectionPreferencesStore.defaults);
  bool _loadingRecords = true;

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

    return Scaffold(
      appBar: FirefighterRoadmapAppBar(
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
      body: RefreshIndicator(
        onRefresh: _refresh,
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
          ],
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
            ],
          ),
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

