import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/app_state.dart';

/// A single home for the responder's durable personal record and app settings.
///
/// Log and Certificates remain full features, but no longer consume permanent
/// bottom-navigation slots. This keeps the primary navigation focused on Home,
/// Department, My Roadmap, and Profile while preserving every existing route.
class ProfileHubPage extends StatelessWidget {
  const ProfileHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final mode = context.watch<AppModeController>();
    final profile = app.profile;
    final departmentName = mode.departmentLink?.departmentName;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My professional record',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    departmentName == null
                        ? 'Personal Roadmap'
                        : '$departmentName · Personal + department-connected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Career path: ${profile.effectiveCareerPath.shortLabel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ProfileAction(
            icon: Icons.note_alt_outlined,
            title: 'Career Record',
            subtitle: 'Training, calls, skills, driving, exposures, and evidence',
            onTap: () => context.push(AppRoutes.personalLog),
          ),
          _ProfileAction(
            icon: Icons.workspace_premium_outlined,
            title: 'Credentials & Certificates',
            subtitle: 'Keep credentials, expiration dates, and supporting records current',
            onTap: () => context.push(AppRoutes.certifications),
          ),
          _ProfileAction(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Career path, backup, privacy, support, and app preferences',
            onTap: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}
