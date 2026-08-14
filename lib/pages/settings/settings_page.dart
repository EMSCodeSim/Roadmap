import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _resetting = false;

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
            _SettingsSection(
              title: 'APP',
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Fire Career Roadmap'),
                  subtitle: const Text('Career planning and professional record'),
                  trailing: const Text('1.1.1'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('DATA & PRIVACY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    )),
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
                title: Text('Reset app',
                    style: TextStyle(
                      color: cs.error,
                      fontWeight: FontWeight.w900,
                    )),
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
              'Your data is stored locally on this device. Reset cannot be undone unless you previously created a backup.',
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
        title: const Text('Reset Fire Career Roadmap?'),
        content: const Text(
          'This will permanently delete your profile, certifications, career goal, Task Books, progress, Quick Log history, saved apparatus, preferences, and supporting records from this device.',
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
        icon: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
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
      const SnackBar(content: Text('The app could not be fully reset. Please try again.')),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              )),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: cs.outline.withValues(alpha: .14)),
        ),
        child: Column(children: children),
      ),
    ]);
  }
}
