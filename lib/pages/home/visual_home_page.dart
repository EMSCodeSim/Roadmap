import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/nav.dart';
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
import 'package:firepath/widgets/unread_pulse_indicator.dart';
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';
import 'package:firepath/widgets/public_safety_metric_tile.dart';
import 'package:firepath/services/theme.dart';

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
    final currentCredentialCount = app.certifications
        .where((c) => c.status == CertificationStatus.current)
        .length;
    final nextStepTitle = nextStep?.requirement.name ??
        (roadmap == null ? 'Choose a goal when you are ready' : 'Your roadmap is caught up');
    final nextStepSubtitle = nextStep == null
        ? 'Keep documenting the work that is shaping your career.'
        : 'Open training, study, official, and practice resources for this step.';

    final sectionWidgets = <HomeSectionType, Widget>{
      HomeSectionType.goal: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, 'Career Goal'),
          AppCardTile(
            icon: Icons.flag_outlined,
            title: app.selectedGoal?.title ?? 'Choose your career goal',
            subtitle: app.selectedGoal == null
                ? 'Build a personal plan for the position or achievement you want next.'
                : 'Open your Roadmap to review progress and requirements.',
            // Open the active plan itself. RoadmapEntryPage falls back to
            // goal setup when the user has not selected a roadmap yet.
            onTap: () => context.go(AppRoutes.myPathLegacy),
          ),
        ],
      ),
      HomeSectionType.nextStep: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, 'Your Next Best Step'),
          AppCardTile(
            icon: Icons.auto_awesome_rounded,
            title: nextStepTitle,
            subtitle: nextStepSubtitle,
            onTap: () {
              if (roadmap == null) {
                context.go(AppRoutes.goalSetup);
                return;
              }
              if (nextStep != null) {
                context.push(
                  AppRoutes.getStarted,
                  extra: nextStep.requirement,
                );
                return;
              }
              context.go(AppRoutes.careerGoals);
            },
          ),
        ],
      ),
      HomeSectionType.needsAttention: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            context,
            'Needs Attention',
            actionLabel: 'Records',
            onAction: () => context.go(AppRoutes.training),
          ),
          if (credentials.isEmpty)
            AppCardTile(
              icon: Icons.verified_outlined,
              title: 'No credential follow-up needed',
              subtitle:
                  'Missing dates, upcoming renewals, and expired credentials appear here.',
              onTap: () => context.go(AppRoutes.certifications),
            )
          else
            ...credentials.take(3).map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: colors.error,
                      ),
                      title: Text(app.certificationDisplayName(item.cert)),
                      subtitle: Text(
                        item.missingExpirationDate
                            ? 'No expiration date · review credential status'
                            : item.isExpired
                                ? 'Expired · renewal needs attention'
                                : 'Expires in ${item.daysRemaining} ${item.daysRemaining == 1 ? 'day' : 'days'}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(
                        '${AppRoutes.certificationDetail}/${item.cert.id}',
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 8),
          AppCardTile(
            icon: Icons.history_rounded,
            title: _loadingRecords
                ? 'Checking personal records…'
                : followUps.isEmpty
                    ? 'No unfinished follow-ups'
                    : '${followUps.length} follow-up${followUps.length == 1 ? '' : 's'} to finish',
            subtitle: _loadingRecords
                ? 'Your saved history and Roadmap evidence are loading.'
                : followUps.isEmpty
                    ? 'Logged activity and completed milestones stay in Records.'
                    : followUps.first.title,
            onTap: () => context.go(AppRoutes.training),
          ),
        ],
      ),
      HomeSectionType.careerSnapshot: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, 'Career Snapshot'),
          Row(
            children: [
              Expanded(
                child: PublicSafetyMetricTile(
                  icon: Icons.auto_awesome_rounded,
                  accent: Theme.of(context).brightness == Brightness.dark
                      ? DarkModeColors.growthPurple
                      : LightModeColors.growthPurple,
                  value: '${monthRecords.length}',
                  label: 'Activities',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PublicSafetyMetricTile(
                  icon: Icons.schedule_rounded,
                  accent: Theme.of(context).brightness == Brightness.dark
                      ? DarkModeColors.trainingBlue
                      : LightModeColors.trainingBlue,
                  value: monthHours == 0
                      ? '—'
                      : monthHours.toStringAsFixed(
                          monthHours == monthHours.roundToDouble() ? 0 : 1,
                        ),
                  label: 'Hours',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PublicSafetyMetricTile(
                  icon: Icons.verified_rounded,
                  accent: Theme.of(context).brightness == Brightness.dark
                      ? DarkModeColors.credentialGreen
                      : LightModeColors.credentialGreen,
                  value: '$currentCredentialCount',
                  label: 'Credentials',
                ),
              ),
            ],
          ),
        ],
      ),
      HomeSectionType.jobSearch: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, 'Job Search Findings'),
          AppCardTile(
            icon: Icons.work_outline_rounded,
            title: 'Review jobs matching your saved search',
            subtitle:
                'Open verified fire and EMS listings without rebuilding your filters.',
            onTap: () => context.push(AppRoutes.jobSearch),
          ),
        ],
      ),
      HomeSectionType.dailyQuiz: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, 'Daily Quiz'),
          AppCardTile(
            icon: Icons.quiz_outlined,
            title: 'Take today’s five-minute EMS quiz',
            subtitle: 'Practice EMT or paramedic questions on EMSCodeSim.',
            onTap: () => _openExternal(Uri.parse('https://emscodesim.com/quiz/')),
          ),
        ],
      ),
      HomeSectionType.trainingIdeas: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, 'Training Ideas'),
          AppCardTile(
            icon: Icons.school_outlined,
            title: 'Find something useful to train today',
            subtitle: 'Choose FireOpsSim drills or EMSCodeSim practice.',
            onTap: _openTrainingIdeas,
          ),
        ],
      ),
      HomeSectionType.department: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            context,
            'Department',
            actionLabel: 'Open',
            onAction: () => context.go(AppRoutes.department),
          ),
          AppCardTile(
            icon: Icons.apartment_rounded,
            title: department.actionCount == 0
                ? 'No department actions waiting'
                : '${department.actionCount} item${department.actionCount == 1 ? '' : 's'} need attention',
            subtitle: department.unreadCount == 0
                ? 'Department requests and updates appear here.'
                : '${department.unreadCount} unread update${department.unreadCount == 1 ? '' : 's'}',
            trailing: department.unreadCount > 0
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UnreadPulseIndicator(),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  )
                : null,
            onTap: () => context.go(AppRoutes.department),
          ),
        ],
      ),
    };

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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final preference in _homeSections)
              if (preference.visible &&
                  (preference.type != HomeSectionType.department ||
                      hasDepartment)) ...[
                sectionWidgets[preference.type]!,
                const SizedBox(height: 18),
              ],
          ],
        ),
      ),
    );
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
              title: const Text('Fire training ideas'),
              subtitle: const Text('Open the FireOpsSim drill library'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => Navigator.pop(
                sheetContext,
                Uri.parse('https://fireopssim.com/drill-library'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('EMS training ideas'),
              subtitle: const Text('Open the EMSCodeSim training library'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => Navigator.pop(
                sheetContext,
                Uri.parse('https://emscodesim.com/ems-training-library.html'),
              ),
            ),
          ],
        ),
      ),
    );
    if (destination != null && mounted) await _openExternal(destination);
  }

  // _statusCard removed in favor of shared AppCardTile.
}
