import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class CertificationDetailPage extends StatefulWidget {
  final String certId;
  final Object? extra;
  const CertificationDetailPage({super.key, required this.certId, required this.extra});

  @override
  State<CertificationDetailPage> createState() => _CertificationDetailPageState();
}

class _CertificationDetailPageState extends State<CertificationDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late Certification _cert;

  late final TextEditingController _name;
  late final TextEditingController _org;
  late final TextEditingController _number;
  late final TextEditingController _notes;

  DateTime? _issueDate;
  DateTime? _expirationDate;
  bool _doesNotExpire = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _cert = Certification.empty(id: 'new_${now.millisecondsSinceEpoch}');
    _name = TextEditingController();
    _org = TextEditingController();
    _number = TextEditingController();
    _notes = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.certId != 'new') {
      final existing = context.read<AppState>().getCertificationById(widget.certId);
      if (existing != null) {
        _cert = existing;
        _name.text = existing.name;
        _org.text = existing.issuingOrganization ?? '';
        _number.text = existing.certificationNumber ?? '';
        _notes.text = existing.notes ?? '';
        _issueDate = existing.issueDate;
        _expirationDate = existing.expirationDate;
        _doesNotExpire = existing.doesNotExpire;
      }
    } else {
      // Optional prefill when coming from a requirement.
      final extra = widget.extra;
      String? prefill;
      if (extra is Map && extra['name'] is String) prefill = extra['name'] as String;
      if (prefill != null && _name.text.trim().isEmpty) {
        _name.text = prefill;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _org.dispose();
    _number.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickIssueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, firstDate: DateTime(1990), lastDate: DateTime(now.year + 10), initialDate: _issueDate ?? now);
    if (picked == null) return;
    setState(() => _issueDate = picked);
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, firstDate: DateTime(1990), lastDate: DateTime(now.year + 30), initialDate: _expirationDate ?? now);
    if (picked == null) return;
    setState(() => _expirationDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = _cert.copyWith(
      name: _name.text.trim(),
      issuingOrganization: _org.text.trim().isEmpty ? null : _org.text.trim(),
      certificationNumber: _number.text.trim().isEmpty ? null : _number.text.trim(),
      issueDate: _issueDate,
      expirationDate: _doesNotExpire ? null : _expirationDate,
      doesNotExpire: _doesNotExpire,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      updatedAt: DateTime.now(),
      clearExpirationDate: _doesNotExpire,
    );
    await context.read<AppState>().upsertCertification(updated);
    if (!mounted) return;

    final extra = widget.extra;
    final completedFromGoalId = (extra is Map) ? extra['completedFromGoalId'] as String? : null;
    final completedFromRequirementId = (extra is Map) ? extra['completedFromRequirementId'] as String? : null;
    final shouldCelebrate = completedFromGoalId != null && completedFromRequirementId != null;

    bool viewNext = false;
    Requirement? next;
    if (shouldCelebrate) {
      next = context.read<AppState>().roadmap?.nextStep?.requirement;
      viewNext = (await _showNiceWork(context, updated.name, next?.name)) ?? false;
    }

    final router = GoRouter.of(context);
    router.pop();
    if (viewNext && next != null) {
      // Wait one frame so we don't push while the current page is popping.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(AppRoutes.requirementDetail, extra: next);
      });
    }
  }

  Future<bool?> _showNiceWork(BuildContext context, String completedName, String? nextName) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nice work', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.sm),
              Text('$completedName completed.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
              if (nextName != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('YOUR NEW NEXT STEP', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(nextName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: nextName == null ? null : () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                  child: const Text('View Next Step'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _delete() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Delete certification?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.sm),
              Text('This cannot be undone.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ],
          ),
        );
      },
    );
    if (confirm != true) return;
    await context.read<AppState>().deleteCertification(_cert.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = _cert.copyWith(
      name: _name.text,
      doesNotExpire: _doesNotExpire,
      expirationDate: _expirationDate,
      issueDate: _issueDate,
      clearExpirationDate: _doesNotExpire,
    ).status;
    final (label, color, icon) = switch (status) {
      CertificationStatus.current => ('Current', FireOpsSemanticColors.completed, Icons.check_circle),
      CertificationStatus.expiringSoon => ('Expiring Soon', FireOpsSemanticColors.warning, Icons.warning_amber_rounded),
      CertificationStatus.expired => ('Expired', FireOpsSemanticColors.expired, Icons.cancel),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.certId == 'new' ? 'Add Certification' : 'Certification'),
        actions: [
          if (widget.certId != 'new')
            IconButton(
              tooltip: 'Delete',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.paddingLg,
            children: [
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                child: Row(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Certification name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(controller: _org, decoration: const InputDecoration(labelText: 'Issuing organization')),
              const SizedBox(height: AppSpacing.md),
              TextFormField(controller: _number, decoration: const InputDecoration(labelText: 'Certification / license number')),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(label: 'Issue date', value: _issueDate, onTap: _pickIssueDate, onClear: () => setState(() => _issueDate = null)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DateTile(
                      label: 'Expiration date',
                      value: _doesNotExpire ? null : _expirationDate,
                      onTap: _doesNotExpire ? null : _pickExpirationDate,
                      onClear: _doesNotExpire ? null : () => setState(() => _expirationDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                value: _doesNotExpire,
                onChanged: (v) => setState(() => _doesNotExpire = v),
                title: const Text('Does Not Expire'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 4, minLines: 3),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _DateTile({required this.label, required this.value, required this.onTap, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = value == null ? '—' : _formatDate(value!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (onClear != null && value != null)
              IconButton(onPressed: onClear, icon: const Icon(Icons.close), tooltip: 'Clear'),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
