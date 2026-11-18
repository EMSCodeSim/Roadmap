import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/career_inbox.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/certification_urgency.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';

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
    const navy = Color(0xFF09213D);
    const red = Color(0xFFC8102E);
    final roadmap = app.roadmap;
    final nextStep = roadmap?.nextStep;
    final hasDepartment = appMode.departmentLink != null;
    final hasPersonalHistory = _records.isNotEmpty || app.certifications.isNotEmpty;
    final firstRecordQuery =
        !_loadingRecords && !hasPersonalHistory ? '?create=1&first=1' : '?create=1';
    final credentials = CertificationUrgency.urgent(
      app.certifications,
      withinDays: 90,
    );
    final followUps = CareerInbox.build(app: app, records: _records)
        .where((item) => item.kind != CareerInboxKind.certification)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const FirefighterRoadmapWordmark(foregroundColor: Colors.white),
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
            Text(
              'Today',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Your priorities, at a glance.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Card(
              color: navy,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR CAREER',
                        style: TextStyle(color: Colors.white70,
                            fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text(
                      _loadingRecords
                          ? 'Loading your career history…'
                          : !hasPersonalHistory
                              ? 'Your record is ready to build'
                              : _records.isEmpty
                                  ? 'Your history is getting started'
                                  : '${_records.length} personal career records',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Training, experience and accomplishments — all in one place.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    if (!_loadingRecords && _records.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Start with a certification, recent class, experience, or accomplishment. You can add older records anytime.',
                        style: TextStyle(color: Colors.white70, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: red, foregroundColor: Colors.white),
                        onPressed: () => context.push(
                          '${AppRoutes.careerEvidence}$firstRecordQuery',
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(
                          !_loadingRecords && _records.isEmpty
                              ? 'Add my first record'
                              : 'Add detailed career history',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.growth),
                        child: const Text('View Career Timeline',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle(context, 'Next action'),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const CircleAvatar(
                  child: Icon(Icons.arrow_forward_rounded),
                ),
                title: Text(
                  nextStep?.requirement.name ??
                      (roadmap == null
                          ? 'Set a career goal (optional)'
                          : 'No immediate roadmap step'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  roadmap == null
                      ? 'Your personal record works without a goal. Add one later for suggested next steps.'
                      : nextStep == null
                          ? 'Review your personal growth plan.'
                          : 'Part of your ${app.selectedGoal?.title ?? 'career'} goal. You can change your goal anytime.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go(
                  roadmap == null ? AppRoutes.goalSetup : AppRoutes.careerGoals,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle(
              context,
              'Credentials',
              actionLabel: 'All',
              onAction: () => context.go(AppRoutes.certifications),
            ),
            if (credentials.isEmpty)
              _statusCard(
                icon: Icons.verified_outlined,
                title: 'No credentials need attention',
                detail: 'Expiring and expired credentials will appear here.',
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
                          item.isExpired
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
            _statusCard(
              icon: Icons.history_rounded,
              title: _loadingRecords
                  ? 'Checking personal records…'
                  : followUps.isEmpty
                      ? 'No unfinished follow-ups'
                      : '${followUps.length} follow-up${followUps.length == 1 ? '' : 's'} to finish',
              detail: _loadingRecords
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
              _statusCard(
                icon: Icons.apartment_rounded,
                title: department.actionCount == 0
                    ? 'No department actions waiting'
                    : '${department.actionCount} item${department.actionCount == 1 ? '' : 's'} need attention',
                detail: department.unreadCount == 0
                    ? 'Department requests and updates appear here.'
                    : '${department.unreadCount} unread update${department.unreadCount == 1 ? '' : 's'}',
                onTap: () => context.go(AppRoutes.department),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.careerGoals),
              icon: const Icon(Icons.route_rounded),
              label: const Text('Open Career Goals'),
            ),
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

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String detail,
    VoidCallback? onTap,
  }) =>
      Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(detail),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}
