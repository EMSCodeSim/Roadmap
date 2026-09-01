import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/theme.dart';

class CertificationPickerPage extends StatefulWidget {
  final Object? extra;
  const CertificationPickerPage({super.key, required this.extra});

  @override
  State<CertificationPickerPage> createState() =>
      _CertificationPickerPageState();
}

class _CertificationPickerPageState extends State<CertificationPickerPage> {
  final TextEditingController _search = TextEditingController();

  String? _prefillDefinitionId;
  String? _prefillName;

  String? _completedFromGoalId;
  String? _completedFromRequirementId;

  @override
  void initState() {
    super.initState();
    final extra = widget.extra;
    if (extra is Map) {
      _prefillDefinitionId = extra['prefillDefinitionId'] as String?;
      _prefillName = extra['prefillName'] as String?;
      _completedFromGoalId = extra['completedFromGoalId'] as String?;
      _completedFromRequirementId =
          extra['completedFromRequirementId'] as String?;
    }
    if (_prefillName != null && _prefillName!.trim().isNotEmpty) {
      _search.text = _prefillName!.trim();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final defs = FireOpsCatalog.certificationDefinitions();
    final preselect = _prefillDefinitionId;
    final query = _search.text.trim();

    List<_DefRow> rows() {
      final q = FireOpsCatalog.normalizeCertificationText(query);
      final list = defs
          .map((d) {
            final blob = FireOpsCatalog.normalizeCertificationText(
              '${d.displayName} ${d.shortName ?? ''} ${d.aliases.join(' ')} ${d.searchKeywords.join(' ')}',
            );
            final hit = q.isEmpty ? true : blob.contains(q);
            if (!hit) return null;
            final isPrefill = preselect != null && d.id == preselect;
            return _DefRow(
              defId: d.id,
              title: d.displayName,
              subtitle: d.shortName ?? d.category.name,
              emphasized: isPrefill,
            );
          })
          .whereType<_DefRow>()
          .toList();

      list.sort((a, b) {
        if (a.emphasized != b.emphasized) return a.emphasized ? -1 : 1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

      return list;
    }

    final list = rows();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toCertifications(),
        title: const Text('Find Certification'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            Text(
              'Search certifications',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pick a known credential to link it to a stable ID (better matching).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search certifications',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () => setState(() => _search.clear()),
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (list.isEmpty)
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                ),
                child: Text(
                  'No matches yet. Try a shorter query, or add a custom certification.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            else
              ...list.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PickerCard(
                    row: r,
                    onTap: () => context.push(
                      '${AppRoutes.certificationDetail}/new',
                      extra: {
                        'definitionId': r.defId,
                        'name': r.title,
                        'completedFromGoalId': _completedFromGoalId,
                        'completedFromRequirementId':
                            _completedFromRequirementId,
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            _PickerCard(
              row: const _DefRow(
                defId: null,
                title: "Can't find it?",
                subtitle: 'Add Custom Certification',
                emphasized: false,
              ),
              onTap: () => context.push(
                '${AppRoutes.certificationDetail}/new',
                extra: {
                  'definitionId': null,
                  'name': _prefillName,
                  'completedFromGoalId': _completedFromGoalId,
                  'completedFromRequirementId': _completedFromRequirementId,
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _DefRow {
  final String? defId;
  final String title;
  final String subtitle;
  final bool emphasized;

  const _DefRow({
    required this.defId,
    required this.title,
    required this.subtitle,
    required this.emphasized,
  });
}

class _PickerCard extends StatelessWidget {
  final _DefRow row;
  final VoidCallback onTap;
  const _PickerCard({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: row.emphasized
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outline.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Icon(
              row.defId == null ? Icons.edit_outlined : Icons.badge_outlined,
              color: row.emphasized ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
