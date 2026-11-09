import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/section_header.dart';

/// Personal records landing page: Quick Logs, statistics, and certificates.
///
/// This page is a UI-only re-organization of existing destinations. It does not
/// change any training workflows or data models.
class TrainingHubPage extends StatelessWidget {
  const TrainingHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final departmentName = (app.profile.departmentName ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Your Quick Logs, career statistics, and dated certificates in one place.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Your records'),
            const SizedBox(height: 10),
            _ActionGrid(
              children: [
                _GridActionCard(
                  color: FireOpsFeatureColors.training,
                  icon: Icons.history_rounded,
                  title: 'All Quick Logs',
                  subtitle: 'Every record, searchable by date and type',
                  onTap: () => context.push(AppRoutes.personalLog),
                ),
                _GridActionCard(
                  color: FireOpsFeatureColors.certificates,
                  icon: Icons.workspace_premium_rounded,
                  title: 'Certificates & Dates',
                  subtitle: 'Issued, expiration and renewal dates',
                  onTap: () => context.push(AppRoutes.certifications),
                ),
                _GridActionCard(
                  color: FireOpsFeatureColors.roadmap,
                  icon: Icons.menu_book_rounded,
                  title: 'Records & Stats',
                  subtitle: 'Yearly and career totals',
                  onTap: () => context.push(AppRoutes.personalLog),
                ),
                _GridActionCard(
                  color: cs.primary,
                  icon: Icons.add_task_rounded,
                  title: 'Quick Add',
                  subtitle: 'Add a new record',
                  onTap: () => QuickLogLauncher.open(context),
                ),
              ],
            ),
            if (departmentName.isNotEmpty) ...[
              const SizedBox(height: 18),
              const SectionHeader(title: 'Department records'),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(Icons.fact_check_outlined, color: cs.primary),
                  title: const Text('Training Sheets'),
                  subtitle: Text('For $departmentName'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.departmentTrainingSheets),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final List<Widget> children;
  const _ActionGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 520 ? 3 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.15,
          children: children,
        );
      },
    );
  }
}

class _GridActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GridActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = color.withValues(alpha: 0.12);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.10)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
