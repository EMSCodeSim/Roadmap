import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/services/department_link_store.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/state/app_mode_controller.dart';

class DepartmentSettingsPage extends StatefulWidget {
  const DepartmentSettingsPage({super.key});

  @override
  State<DepartmentSettingsPage> createState() => _DepartmentSettingsPageState();
}

class _DepartmentSettingsPageState extends State<DepartmentSettingsPage> {
  final _api = ResponderRoadmapApi();
  final _linkStore = DepartmentLinkStore();
  bool _disconnecting = false;

  Future<void> _confirmDisconnect(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _DisconnectDepartmentSheet(),
    );
    if (confirmed != true) return;
    await _disconnect(context);
  }

  Future<void> _disconnect(BuildContext context) async {
    if (_disconnecting) return;
    setState(() => _disconnecting = true);
    try {
      await Future.wait<void>([
        _api.disconnect(),
        _linkStore.clear(),
      ]);
      if (!context.mounted) return;
      await context.read<AppModeController>().setDepartmentLink(null);
      if (!context.mounted) return;
      context.go(AppRoutes.department);
    } catch (e) {
      debugPrint('DepartmentSettings: disconnect failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not disconnect right now. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppModeController>();
    final link = mode.departmentLink;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Settings'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (link == null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'You’re not connected to a department yet.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.department),
              icon: const Icon(Icons.groups_2_outlined),
              label: const Text('Go to Department'),
            ),
          ] else ...[
            _SettingsSection(
              title: 'Department',
              children: [
                _InfoTile(
                  icon: Icons.apartment_rounded,
                  title: link.departmentName,
                  subtitle: 'Department ID: ${link.departmentId}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsSection(
              title: 'Your access',
              children: [
                _InfoTile(
                  icon: Icons.badge_outlined,
                  title: link.userName,
                  subtitle: link.email,
                ),
                _InfoTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Role: ${mode.role}',
                  subtitle: link.rank == null || (link.rank ?? '').trim().isEmpty
                      ? 'Rank: —'
                      : 'Rank: ${link.rank}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsSection(
              title: 'Admin settings',
              helperText: mode.isAdmin
                  ? 'These settings are limited to administrators.'
                  : 'Administrator-only settings are locked for your role.',
              children: [
                _ActionTile(
                  enabled: mode.isAdmin,
                  icon: Icons.manage_accounts_outlined,
                  title: 'Manage members & roles',
                  subtitle: 'Available in the Department Portal.',
                  onTap: mode.isAdmin
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Member management is handled in the Department Portal (web).',
                              ),
                            ),
                          );
                        }
                      : null,
                ),
                _ActionTile(
                  enabled: mode.isAdmin,
                  icon: Icons.settings_suggest_outlined,
                  title: 'Configure training workflows',
                  subtitle: 'Administrator-only.',
                  onTap: mode.isAdmin
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Workflow configuration is coming soon in-app.',
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsSection(
              title: 'Account',
              children: [
                _ActionTile(
                  enabled: !_disconnecting,
                  icon: Icons.link_off_rounded,
                  title: 'Disconnect from department',
                  subtitle: 'Sign out and remove this department from the app.',
                  destructive: true,
                  trailing: _disconnecting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _disconnecting ? null : () => _confirmDisconnect(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.helperText,
  });

  final String title;
  final String? helperText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(title, style: theme.textTheme.titleSmall),
      ),
      if (helperText != null) ...[
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(helperText!, style: theme.textTheme.bodySmall),
        ),
      ],
      const SizedBox(height: 10),
      Card(child: Column(children: children)),
    ]);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = destructive
        ? theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error)
        : theme.textTheme.titleMedium;

    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: destructive ? theme.colorScheme.error : null),
      title: Text(title, style: titleStyle),
      subtitle: Text(subtitle),
      trailing: trailing ?? (!enabled ? const Icon(Icons.lock_outline_rounded) : const Icon(Icons.chevron_right_rounded)),
      onTap: enabled ? onTap : null,
    );
  }
}

class _DisconnectDepartmentSheet extends StatelessWidget {
  const _DisconnectDepartmentSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Disconnect from department?', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'This will remove your department connection from this device. Your department records remain on ResponderRoadmap.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Disconnect'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
