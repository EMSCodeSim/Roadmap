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
import 'package:firepath/widgets/app_card_tile.dart';
import 'package:firepath/widgets/unread_pulse_indicator.dart';
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 5),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
}

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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF071A33), Color(0xFF164E7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF071A33).withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.76),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              app.selectedGoal?.title ?? 'Build your career story',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    nextStep?.requirement.name ??
                        (roadmap == null
                            ? 'Choose a goal when you are ready'
                            : 'Your current roadmap is caught up'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    nextStep == null
                        ? 'Keep documenting the work that is shaping your career.'
                        : 'Recommended next step in your personal growth plan.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => context.go(
                      roadmap == null
                          ? AppRoutes.goalSetup
                          : AppRoutes.careerGoals,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      roadmap == null ? 'Set a career goal' : 'Open next step',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF071A33),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFF7C3AED),
                    value: '${monthRecords.length}',
                    label: 'This month',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF2563EB),
                    value: monthHours == 0
                        ? '—'
                        : monthHours.toStringAsFixed(
                            monthHours == monthHours.roundToDouble() ? 0 : 1,
                          ),
                    label: 'Hours logged',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.verified_rounded,
                    color: const Color(0xFF10B981),
                    value: '${app.certifications.length}',
                    label: 'Credentials',
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
