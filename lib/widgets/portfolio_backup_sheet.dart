import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/career_backup_service.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

/// Phone-friendly backup/restore sheet. File save/share and file pick are
/// primary; clipboard paste is a fallback for older backups.
class PortfolioBackupSheet extends StatefulWidget {
  const PortfolioBackupSheet({super.key, this.onRestored});

  final VoidCallback? onRestored;

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onRestored,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => PortfolioBackupSheet(onRestored: onRestored),
    );
  }

  @override
  State<PortfolioBackupSheet> createState() => _PortfolioBackupSheetState();
}

class _PortfolioBackupSheetState extends State<PortfolioBackupSheet> {
  final _backup = CareerBackupService();
  final _paste = TextEditingController();
  bool _busy = false;
  bool _showPaste = false;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    final result = await _backup.shareOrSaveBackup();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _restoreFromFile() async {
    final confirmed = await _confirmRestore(
      'The selected backup file will replace the FireOps career portfolio on this device.',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final result = await _backup.restoreFromPickedFile();
    if (!mounted) return;
    setState(() => _busy = false);
    await _finishRestore(result);
  }

  Future<void> _restoreFromPaste() async {
    final raw = _paste.text.trim();
    if (raw.isEmpty) return;
    final confirmed = await _confirmRestore(
      'The pasted backup will replace the FireOps career portfolio on this device.',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final result = await _backup.restoreFromPastedJson(raw);
    if (!mounted) return;
    setState(() => _busy = false);
    await _finishRestore(result);
  }

  Future<bool?> _confirmRestore(String body) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace current portfolio?'),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishRestore(CareerRestoreResult result) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (!result.success) return;
    await context.read<AppState>().bootstrap();
    widget.onRestored?.call();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Backup & restore',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Save a FireOps Career Portfolio file before changing phones. Restoring replaces the portfolio on this device. Current backups use schema version 5.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('backup-save-file'),
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('Save or share backup file'),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              key: const Key('backup-restore-file'),
              onPressed: _busy ? null : _restoreFromFile,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Restore from backup file'),
            ),
            const SizedBox(height: 16),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() => _showPaste = !_showPaste),
              child: Text(_showPaste
                  ? 'Hide paste fallback'
                  : 'Paste an older backup instead'),
            ),
            if (_showPaste) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _paste,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste FireOps Career Portfolio JSON',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _restoreFromPaste,
                icon: const Icon(Icons.restore_outlined),
                label: const Text('Restore pasted backup'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final json = await _backup.exportBackupJson();
                        await Clipboard.setData(ClipboardData(text: json));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Backup copied. Prefer the backup file for large portfolios.',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy backup JSON'),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Do not put patient-identifying information in career notes. Keep backup files in a private folder, not a shared department drive.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
