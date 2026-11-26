import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/services/career_inbox.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/certification_urgency.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/widgets/app_card_tile.dart';
import 'package:firepath/widgets/unread_pulse_indicator.dart';
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';
import 'package:firepath/widgets/public_safety_metric_tile.dart';
import 'package:firepath/widgets/career_dashboard_header.dart';
import 'package:firepath/services/theme.dart';

/// A compact daily overview. Lifelong history lives in Career Timeline.
class VisualHomePage extends StatefulWidget {
  const VisualHomePage({super.key});

  @override
  State<VisualHomePage> createState() => _VisualHomePageState();
}

class _VisualHomePageState extends State<VisualHomePage> {
  final CareerRecordStore _recordStore = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loadingRecords = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _recordStore.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loadingRecords = false;
    });
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
    final role = app.profile.currentRoles.isEmpty
        ? 'Fire & EMS professional'
        : app.profile.currentRoles.join(' • ');
    final followUps = CareerInbox.build(app: app, records: _records)
        .where((item) => item.kind != CareerInboxKind.certification)
        .toList(growable: false);
    final departmentName = appMode.departmentLink?.departmentName;
    final currentCredentialCount = app.certifications
        .where((c) => c.status == CertificationStatus.current)
        .length;
    final nextStepTitle = nextStep?.requirement.name ??
        (roadmap == null ? 'Choose a goal when you are ready' : 'Your roadmap is caught up');
    final nextStepSubtitle = nextStep == null
        ? 'Keep documenting the work that is shaping your career.'
        : 'Recommended next step in your personal growth plan.';
    final actionLabel = roadmap == null ? 'Set a career goal' : 'Open next step';

    return Scaffold(
      appBar: FirefighterRoadmapAppBar(
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            CareerDashboardHeader(
              roleLabel: role,
              departmentLabel: departmentName,
              goalTitle: app.selectedGoal?.title ?? 'Build your career story',
              nextStepTitle: nextStepTitle,
              nextStepSubtitle: nextStepSubtitle,
              actionLabel: actionLabel,
              onAction: () => context.go(
                roadmap == null ? AppRoutes.goalSetup : AppRoutes.careerGoals,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PublicSafetyMetricTile(
                    icon: Icons.auto_awesome_rounded,
                    accent: Theme.of(context).brightness == Brightness.dark
                        ? DarkModeColors.growthPurple
                        : LightModeColors.growthPurple,
                    value: '${monthRecords.length}',
                    label: 'Activities (month)',
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
                    label: 'Training hours',
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
                    label: 'Current creds',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle(
              context,
              'Credentials',
              actionLabel: 'All',
              onAction: () => context.go(AppRoutes.certifications),
            ),
            if (credentials.isEmpty)
              AppCardTile(
                icon: Icons.verified_outlined,
                title: 'No credential follow-up needed',
                subtitle: 'Missing expiration dates, expiring credentials, and expired credentials will appear here.',
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
            _sectionTitle(
              context,
              'Unfinished records',
              actionLabel: 'Records',
              onAction: () => context.go(AppRoutes.training),
            ),
            AppCardTile(
              icon: Icons.history_rounded,
              title: _loadingRecords
                  ? 'Checking personal records…'
                  : followUps.isEmpty
                      ? 'No unfinished follow-ups'
                      : '${followUps.length} follow-up${followUps.length == 1 ? '' : 's'} to finish',
              subtitle: _loadingRecords
                  ? 'Your saved history and roadmap evidence are loading.'
                  : followUps.isEmpty
                      ? 'Logged activity and completed milestones stay in Records.'
                      : followUps.first.title,
              onTap: () => context.go(AppRoutes.training),
            ),
            if (hasDepartment) ...[
              const SizedBox(height: 16),
              _sectionTitle(
                context,
                'Department attention',
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

  // _statusCard removed in favor of shared AppCardTile.
}
