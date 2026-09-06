import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/services/certification_urgency.dart';
import 'package:firepath/services/department_certification_sharing.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/services/catalog.dart';

class CertificationDetailPage extends StatefulWidget {
  final String certId;
  final Object? extra;
  const CertificationDetailPage({
    super.key,
    required this.certId,
    required this.extra,
  });

  @override
  State<CertificationDetailPage> createState() =>
      _CertificationDetailPageState();
}

class _CertificationDetailPageState extends State<CertificationDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late Certification _cert;
  bool _autoOpenedRenewal = false;

  late final TextEditingController _name;
  late final TextEditingController _org;
  late final TextEditingController _number;
  late final TextEditingController _notes;

  DateTime? _issueDate;
  DateTime? _expirationDate;
  bool _doesNotExpire = false;
  final ResponderRoadmapApi _departmentApi = ResponderRoadmapApi();
  Set<String> _sharedCertificationIds = <String>{};
  bool _sharingInitialized = false;
  bool _sharingLoading = false;
  bool _sharingSaving = false;
  bool _departmentConnected = false;
  String? _departmentName;
  String? _sharingError;

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
      final existing = context.read<AppState>().getCertificationById(
        widget.certId,
      );
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
      String? prefillDefId;
      if (extra is Map && extra['name'] is String)
        prefill = extra['name'] as String;
      if (extra is Map && extra['definitionId'] is String)
        prefillDefId = extra['definitionId'] as String;
      if (prefill != null && _name.text.trim().isEmpty) {
        _name.text = prefill;
      }
      if (prefillDefId != null &&
          (_cert.certificationDefinitionId == null ||
              _cert.certificationDefinitionId!.isEmpty)) {
        _cert = _cert.copyWith(certificationDefinitionId: prefillDefId);
      }
    }

    final extra = widget.extra;
    final shouldFocusRenewal = extra is Map && extra['focus'] == 'renewal';
    if (shouldFocusRenewal && !_autoOpenedRenewal) {
      _autoOpenedRenewal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showRenewalUpdateSheet();
      });
    }

    if (widget.certId != 'new' && !_sharingInitialized) {
      _sharingInitialized = true;
      _loadDepartmentSharing();
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
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 10),
      initialDate: _issueDate ?? now,
    );
    if (picked == null) return;
    setState(() => _issueDate = picked);
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 30),
      initialDate: _expirationDate ?? now,
    );
    if (picked == null) return;
    setState(() => _expirationDate = picked);
  }

  Future<void> _loadDepartmentSharing() async {
    setState(() {
      _sharingLoading = true;
      _sharingError = null;
    });
    try {
      if (!await _departmentApi.hasStoredToken) {
        if (!mounted) return;
        setState(() {
          _departmentConnected = false;
          _sharingLoading = false;
        });
        return;
      }
      final session = await _departmentApi.currentSession();
      if (!session.hasDepartment) {
        if (!mounted) return;
        setState(() {
          _departmentConnected = false;
          _sharingLoading = false;
        });
        return;
      }
      final sharing = await _departmentApi.getCertificationSharing();
      if (!mounted) return;
      setState(() {
        _departmentConnected = true;
        _departmentName = session.departmentName;
        _sharedCertificationIds = sharing.sharedSourceIds;
        _sharingLoading = false;
      });
    } on ResponderRoadmapApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _departmentConnected = false;
        _sharingLoading = false;
        _sharingError = error.statusCode == 401 || error.statusCode == 403
            ? 'Sign in again from the Department tab to manage sharing.'
            : error.message;
      });
    }
  }

  List<Map<String, dynamic>> _sharingPayloads(
    Set<String> sharedIds, {
    Certification? replacement,
  }) {
    final certifications = context.read<AppState>().certifications;
    return certifications
        .where((certification) => sharedIds.contains(certification.id))
        .map(
          (certification) => departmentCertificationPayload(
            replacement?.id == certification.id
                ? replacement!
                : certification,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _setDepartmentShared(bool share) async {
    if (_sharingSaving || !_departmentConnected) return;
    final next = Set<String>.from(_sharedCertificationIds);
    share ? next.add(_cert.id) : next.remove(_cert.id);
    setState(() {
      _sharingSaving = true;
      _sharingError = null;
    });
    try {
      final result = await _departmentApi.syncCertificationSharing(
        _sharingPayloads(next),
      );
      if (!mounted) return;
      setState(() => _sharedCertificationIds = result.sharedSourceIds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            share
                ? '${_cert.name} and its expiration date are shared with ${_departmentName ?? 'your department'}.'
                : '${_cert.name} is no longer shared with ${_departmentName ?? 'your department'}.',
          ),
        ),
      );
    } on ResponderRoadmapApiException catch (error) {
      if (!mounted) return;
      setState(() => _sharingError = error.message);
    } finally {
      if (mounted) setState(() => _sharingSaving = false);
    }
  }

  Future<bool> _syncSharedUpdate(Certification updated) async {
    if (!_departmentConnected ||
        !_sharedCertificationIds.contains(updated.id)) {
      return true;
    }
    try {
      final result = await _departmentApi.syncCertificationSharing(
        _sharingPayloads(_sharedCertificationIds, replacement: updated),
      );
      if (!mounted) return true;
      setState(() {
        _sharedCertificationIds = result.sharedSourceIds;
        _sharingError = null;
      });
      return true;
    } on ResponderRoadmapApiException catch (error) {
      if (!mounted) return false;
      setState(() => _sharingError = error.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Certification saved on this device, but the department update failed: ${error.message}',
          ),
          duration: const Duration(seconds: 7),
        ),
      );
      return false;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Duplicate protection (stable ID).
    final defId = _cert.certificationDefinitionId;
    if (widget.certId == 'new' && defId != null) {
      final existing = context
          .read<AppState>()
          .certifications
          .where((c) => c.certificationDefinitionId == defId)
          .toList();
      if (existing.isNotEmpty) {
        final picked = await _showDuplicateDialog(
          context,
          name:
              FireOpsCatalog.certificationById()[defId]?.displayName ??
              _name.text.trim(),
        );
        if (picked == null) return;
        if (picked == _DuplicateChoice.updateExisting) {
          // Reuse the most recently updated record.
          existing.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          _cert = existing.first;
        }
      }
    }

    // Renewal history (minimal structure; no full UI yet).
    List<CertificationRenewal> history = List.of(_cert.renewalHistory);
    if (widget.certId != 'new') {
      final before = context.read<AppState>().getCertificationById(_cert.id);
      if (before != null) {
        final changedDates =
            before.issueDate != _issueDate ||
            before.expirationDate !=
                (_doesNotExpire ? null : _expirationDate) ||
            before.doesNotExpire != _doesNotExpire;
        if (changedDates) {
          history = [
            ...history,
            CertificationRenewal(
              issueDate: before.issueDate,
              expirationDate: before.expirationDate,
              doesNotExpire: before.doesNotExpire,
              issuingOrganization: before.issuingOrganization,
              certificationNumber: before.certificationNumber,
              notes: before.notes,
              createdAt: DateTime.now(),
            ),
          ];
        }
      }
    }

    final updated = _cert.copyWith(
      name: _name.text.trim(),
      issuingOrganization: _org.text.trim().isEmpty ? null : _org.text.trim(),
      certificationNumber: _number.text.trim().isEmpty
          ? null
          : _number.text.trim(),
      issueDate: _issueDate,
      expirationDate: _doesNotExpire ? null : _expirationDate,
      doesNotExpire: _doesNotExpire,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      renewalHistory: history,
      updatedAt: DateTime.now(),
      clearExpirationDate: _doesNotExpire,
    );
    await context.read<AppState>().upsertCertification(updated);
    if (!mounted) return;
    _cert = updated;
    if (!await _syncSharedUpdate(updated)) return;
    if (!mounted) return;

    final extra = widget.extra;
    final completedFromGoalId = (extra is Map)
        ? extra['completedFromGoalId'] as String?
        : null;
    final completedFromRequirementId = (extra is Map)
        ? extra['completedFromRequirementId'] as String?
        : null;
    final shouldCelebrate =
        completedFromGoalId != null && completedFromRequirementId != null;

    bool viewNext = false;
    Requirement? next;
    if (shouldCelebrate) {
      next = context.read<AppState>().roadmap?.nextStep?.requirement;
      viewNext =
          (await _showNiceWork(context, updated.name, next?.name)) ?? false;
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

  Future<void> _showRenewalUpdateSheet() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    var newExpiration = _expirationDate;
    var newIssueDate = _issueDate;
    final noteController = TextEditingController();
    final now = DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final previewCert = _cert.copyWith(
              issueDate: newIssueDate,
              expirationDate: _doesNotExpire ? null : newExpiration,
              doesNotExpire: _doesNotExpire,
              clearExpirationDate: _doesNotExpire,
            );
            final guidance = CertificationUrgency.renewalGuidance(previewCert);
            final isExpired = previewCert.status == CertificationStatus.expired;

            Future<void> pickExpiration() async {
              final picked = await showDatePicker(
                context: sheetContext,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 30),
                initialDate: newExpiration ?? now,
              );
              if (picked == null) return;
              setSheetState(() => newExpiration = picked);
            }

            Future<void> pickIssue() async {
              final picked = await showDatePicker(
                context: sheetContext,
                firstDate: DateTime(1990),
                lastDate: DateTime(now.year + 1),
                initialDate: newIssueDate ?? now,
              );
              if (picked == null) return;
              setSheetState(() => newIssueDate = picked);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isExpired
                        ? 'Renew credential (expired)'
                        : 'Renew credential (expiring soon)',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    guidance.summary,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          label: 'Issue date',
                          value: newIssueDate,
                          onTap: pickIssue,
                          onClear: () => setSheetState(() => newIssueDate = null),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _DateTile(
                          label: 'New expiration',
                          value: newExpiration,
                          onTap: pickExpiration,
                          onClear: () => setSheetState(() => newExpiration = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Renewal note (optional proof details)',
                      hintText: 'e.g., “Completed 24 CE hours, submitted renewal online”',
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final before = _cert;
                        final history = <CertificationRenewal>[...before.renewalHistory];
                        history.add(
                          CertificationRenewal(
                            issueDate: before.issueDate,
                            expirationDate: before.expirationDate,
                            doesNotExpire: before.doesNotExpire,
                            issuingOrganization: before.issuingOrganization,
                            certificationNumber: before.certificationNumber,
                            notes: before.notes,
                            createdAt: DateTime.now(),
                          ),
                        );

                        final note = noteController.text.trim();
                        final updated = before.copyWith(
                          issueDate: newIssueDate,
                          expirationDate: newExpiration,
                          doesNotExpire: false,
                          renewalHistory: history,
                          notes: note.isEmpty ? before.notes : note,
                          updatedAt: DateTime.now(),
                        );
                        await context.read<AppState>().upsertCertification(updated);
                        if (!mounted) return;
                        setState(() {
                          _cert = updated;
                          _issueDate = updated.issueDate;
                          _expirationDate = updated.expirationDate;
                          _doesNotExpire = updated.doesNotExpire;
                          if (note.isNotEmpty) _notes.text = note;
                        });
                        await _syncSharedUpdate(updated);
                        if (!mounted) return;
                        if (sheetContext.mounted) sheetContext.pop();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark Renewed / Update Dates'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => sheetContext.pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: const Text('Not right now'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _logRenewalProgress() {
    final state = context.read<AppState>();
    final roadmap = state.roadmap;
    final defId = _cert.certificationDefinitionId;
    Requirement? relatedReq;
    if (defId != null && roadmap != null) {
      for (final item in roadmap.all) {
        final r = item.requirement;
        if (r.type == RequirementType.certification &&
            r.certificationDefinitionId == defId) {
          relatedReq = r;
          break;
        }
      }
    }

    final name = state.certificationDisplayName(_cert);

    QuickLogLauncher.open(
      context,
      prefill: LogPrefill(
        title: 'Renewal: $name',
        category: 'Certification Renewal',
        relatedGoalId: roadmap?.goal.id,
        relatedRequirementId: relatedReq?.id,
        relatedTaskId: null,
        tags: ['renewal', 'certification'],
      ),
    );
  }

  Future<bool?> _showNiceWork(
    BuildContext context,
    String completedName,
    String? nextName,
  ) {
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
              Text(
                'Nice work',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$completedName completed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              if (nextName != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'YOUR NEW NEXT STEP',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: nextName == null ? null : () => context.pop(true),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: const Text('View Next Step'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.pop(false),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
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
              Text(
                'Delete certification?',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This cannot be undone.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.pop(true),
                child: const Text('Delete'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
    if (confirm != true) return;
    if (_departmentConnected &&
        _sharedCertificationIds.contains(_cert.id)) {
      setState(() {
        _sharingSaving = true;
        _sharingError = null;
      });
      try {
        final next = Set<String>.from(_sharedCertificationIds)
          ..remove(_cert.id);
        final result = await _departmentApi.syncCertificationSharing(
          _sharingPayloads(next),
        );
        if (!mounted) return;
        setState(() => _sharedCertificationIds = result.sharedSourceIds);
      } on ResponderRoadmapApiException catch (error) {
        if (!mounted) return;
        setState(() => _sharingError = error.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not remove this certification from your department: ${error.message}',
            ),
          ),
        );
        return;
      } finally {
        if (mounted) setState(() => _sharingSaving = false);
      }
    }
    await context.read<AppState>().deleteCertification(_cert.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = _cert
        .copyWith(
          name: _name.text,
          doesNotExpire: _doesNotExpire,
          expirationDate: _expirationDate,
          issueDate: _issueDate,
          clearExpirationDate: _doesNotExpire,
        )
        .status;
    final (label, color, icon) = switch (status) {
      CertificationStatus.current => (
        'Current',
        FireOpsSemanticColors.completed,
        Icons.check_circle,
      ),
      CertificationStatus.expiringSoon => (
        'Expiring Soon',
        FireOpsSemanticColors.warning,
        Icons.warning_amber_rounded,
      ),
      CertificationStatus.expired => (
        'Expired',
        FireOpsSemanticColors.expired,
        Icons.cancel,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toCertifications(),

        title: Text(
          widget.certId == 'new' ? 'Add Certification' : 'Certification',
        ),
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
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (status != CertificationStatus.current) ...[
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        height: 40,
                        child: FilledButton.tonalIcon(
                          onPressed: _showRenewalUpdateSheet,
                          icon: const Icon(Icons.autorenew),
                          label: const Text('Renew'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (status != CertificationStatus.current) ...[
                const SizedBox(height: AppSpacing.md),
                _RenewalPlanCard(
                  cert: _cert.copyWith(
                    name: _name.text,
                    doesNotExpire: _doesNotExpire,
                    expirationDate: _expirationDate,
                    issueDate: _issueDate,
                    clearExpirationDate: _doesNotExpire,
                  ),
                  onRenewNow: _showRenewalUpdateSheet,
                  onLogProgress: _logRenewalProgress,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Certification name',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              if (_cert.certificationDefinitionId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _LinkedDefinitionChip(
                  definitionId: _cert.certificationDefinitionId!,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _org,
                decoration: const InputDecoration(
                  labelText: 'Issuing organization',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _number,
                decoration: const InputDecoration(
                  labelText: 'Certification / license number',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: 'Issue date',
                      value: _issueDate,
                      onTap: _pickIssueDate,
                      onClear: () => setState(() => _issueDate = null),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DateTile(
                      label: 'Expiration date',
                      value: _doesNotExpire ? null : _expirationDate,
                      onTap: _doesNotExpire ? null : _pickExpirationDate,
                      onClear: _doesNotExpire
                          ? null
                          : () => setState(() => _expirationDate = null),
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
              if (widget.certId != 'new') ...[
                const SizedBox(height: AppSpacing.md),
                _DepartmentSharingCard(
                  connected: _departmentConnected,
                  departmentName: _departmentName,
                  shared: _sharedCertificationIds.contains(_cert.id),
                  loading: _sharingLoading,
                  saving: _sharingSaving,
                  error: _sharingError,
                  expirationDate: _cert.expirationDate,
                  doesNotExpire: _cert.doesNotExpire,
                  onChanged: _setDepartmentShared,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
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

class _DepartmentSharingCard extends StatelessWidget {
  final bool connected;
  final String? departmentName;
  final bool shared;
  final bool loading;
  final bool saving;
  final String? error;
  final DateTime? expirationDate;
  final bool doesNotExpire;
  final ValueChanged<bool> onChanged;

  const _DepartmentSharingCard({
    required this.connected,
    required this.departmentName,
    required this.shared,
    required this.loading,
    required this.saving,
    required this.error,
    required this.expirationDate,
    required this.doesNotExpire,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expiration = doesNotExpire
        ? 'Does not expire'
        : expirationDate == null
            ? 'No expiration date entered'
            : 'Expires ${_DateTile._formatDate(expirationDate!)}';
    final destination = departmentName?.trim().isNotEmpty == true
        ? departmentName!
        : 'your department';

    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: shared,
            onChanged: loading || saving || !connected ? null : onChanged,
            secondary: Icon(
              shared ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            ),
            title: const Text(
              'Share with department',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              loading
                  ? 'Checking department sharing…'
                  : connected
                      ? shared
                          ? 'Shared with $destination · $expiration'
                          : 'Share this certification and its expiration date with $destination.'
                      : 'Sign in from the Department tab to enable sharing.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              'The department receives the certification name, issuer, issue date, and expiration date or does-not-expire status. Your credential number and personal notes stay private.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                error!,
                style: TextStyle(
                  color: cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (saving) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = value == null ? '—' : _formatDate(value!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null && value != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
                tooltip: 'Clear',
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _RenewalPlanCard extends StatelessWidget {
  final Certification cert;
  final VoidCallback onRenewNow;
  final VoidCallback onLogProgress;

  const _RenewalPlanCard({
    required this.cert,
    required this.onRenewNow,
    required this.onLogProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final guidance = CertificationUrgency.renewalGuidance(cert);
    final isExpired = cert.status == CertificationStatus.expired;

    final bg = isExpired
        ? cs.errorContainer.withValues(alpha: 0.45)
        : cs.secondaryContainer.withValues(alpha: 0.35);
    final border = isExpired
        ? FireOpsSemanticColors.expired
        : FireOpsSemanticColors.warning;
    final icon = isExpired ? Icons.cancel : Icons.warning_amber_rounded;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: border),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  guidance.headline,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            guidance.summary,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 12),
          Text(
            'HOW TO COMPLETE',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          ...guidance.steps.take(6).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(height: 1.35, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onRenewNow,
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Renew / Update Dates'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onLogProgress,
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Log renewal progress'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DuplicateChoice { updateExisting, addAnother }

extension on _CertificationDetailPageState {
  Future<_DuplicateChoice?> _showDuplicateDialog(
    BuildContext context, {
    required String name,
  }) {
    return showModalBottomSheet<_DuplicateChoice>(
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
              Text(
                'Already added',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You already have $name. Some people keep multiple records (different issuers or renewals).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => context.pop(_DuplicateChoice.updateExisting),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: const Text('Update Existing'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.pop(_DuplicateChoice.addAnother),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: const Text('Add Another Record'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.pop(null),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LinkedDefinitionChip extends StatelessWidget {
  final String definitionId;
  const _LinkedDefinitionChip({required this.definitionId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final def = FireOpsCatalog.certificationById()[definitionId];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            def?.displayName ?? definitionId,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
