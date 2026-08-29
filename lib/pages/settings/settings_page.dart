import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/widgets/portfolio_backup_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _resetting = false;

  static final Uri _privacyUrl =
      Uri.parse('https://fireopssim.com/career-road-privacy.html');
  static final Uri _supportUrl =
      Uri.parse('https://fireopssim.com/career-road-support.html');

  Future<void> _openUrl(Uri url) async {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the page. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toHome(),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            const _SettingsSection(
              title: 'APP',
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About FireOps Career Road'),
                  subtitle: Text('Career planning and professional record'),
                  trailing: Text('1.1.10 (17)'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SettingsSection(
              title: 'PRIVACY & SUPPORT',
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('How personal and department data are handled'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(_privacyUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Support'),
                  subtitle: const Text('Troubleshooting and help for this app'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(_supportUrl),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SettingsSection(
              title: 'BACKUP',
              children: [
                ListTile(
                  key: const Key('settings-backup-restore'),
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Backup & restore'),
                  subtitle: const Text(
                    'Save a portfolio file, or restore one onto this device',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => PortfolioBackupSheet.show(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'DATA & PRIVACY',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: .34),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: cs.error.withValues(alpha: .24)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                leading: Icon(Icons.restart_alt, color: cs.error),
                title: Text(
                  'Reset app',
                  style: TextStyle(
                    color: cs.error,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: const Text(
                  'Erase local career data and return to first-time setup.',
                ),
                trailing: _resetting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _resetting ? null : _confirmReset,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your personal Career Road data is stored locally on this device. Optional department Task Book data is sent to ResponderRoadmap only when you connect a department account and submit department work.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final first = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Reset FireOps Career Road?'),
        content: const Text(
          'This will permanently delete your profile, certifications, career goal, personal Task Books, progress, Quick Log history, saved apparatus, preferences, and supporting records from this device. Department records already submitted to ResponderRoadmap are not deleted by this local reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;

    final finalConfirmation = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_forever,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Final confirmation'),
        content: const Text(
          'This action cannot be undone. The app will reopen at first-time setup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep My Data'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (finalConfirmation != true || !mounted) return;

    setState(() => _resetting = true);
    final success = await context.read<AppState>().resetApp();
    if (!mounted) return;
    if (success) {
      context.go(AppRoutes.onboarding);
      return;
    }
    setState(() => _resetting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The app could not be fully reset. Please try again.'),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: cs.outline.withValues(alpha: .14)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
