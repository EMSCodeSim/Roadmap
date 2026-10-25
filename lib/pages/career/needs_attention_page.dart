import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/needs_attention_engine.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/widgets/calm_empty_state.dart';

class NeedsAttentionPage extends StatefulWidget {
  const NeedsAttentionPage({super.key});

  @override
  State<NeedsAttentionPage> createState() => _NeedsAttentionPageState();
}

class _NeedsAttentionPageState extends State<NeedsAttentionPage> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _store.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = NeedsAttentionEngine.analyze(app: app, records: _records);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toHome(),
        title: const Text('Needs Attention'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: items.isEmpty
                  ? ListView(
                      padding: AppSpacing.paddingLg,
                      children: [
                        const SizedBox(height: 40),
                        CalmEmptyState(
                          icon: Icons.check_circle_outline,
                          title: 'You’re all caught up',
                          message:
                              'This screen flags items that could block progress: expiring credentials, missing expiration dates, certifications that need matching, and Task Book progress that has stalled.',
                          primaryAction: FilledButton.icon(
                            onPressed: () => context.go(AppRoutes.myPath),
                            icon: const Icon(Icons.route_outlined),
                            label: const Text('Open Career Road'),
                          ),
                          secondaryAction: OutlinedButton.icon(
                            onPressed: () => context.go(AppRoutes.certifications),
                            icon: const Icon(Icons.workspace_premium_outlined),
                            label: const Text('Open Certifications'),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                      children: [
                        Text(
                          'Needs Attention means there’s something to review or fix that may affect your current Career Road.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 18),
                        ...NeedsAttentionUrgency.values.expand((urgency) {
                          final group = items.where((i) => i.urgency == urgency).toList();
                          if (group.isEmpty) return <Widget>[];
                          final title = switch (urgency) {
                            NeedsAttentionUrgency.now => 'NOW',
                            NeedsAttentionUrgency.soon => 'SOON',
                            NeedsAttentionUrgency.later => 'LATER',
                          };
                          return <Widget>[
                            Text(
                              title,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    letterSpacing: .8,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ...group.map((item) => _AttentionTile(
                                  item: item,
                                  onTap: () => _openItem(context, app, item),
                                )),
                            const SizedBox(height: 14),
                          ];
                        }),
                      ],
                    ),
            ),
    );
  }

  void _openItem(BuildContext context, AppState app, NeedsAttentionItem item) {
    switch (item.kind) {
      case NeedsAttentionKind.certificationExpired:
      case NeedsAttentionKind.certificationExpiring:
      case NeedsAttentionKind.certificationMissingExpiration:
        final id = item.certificationId;
        if (id != null) {
          context.push(
            '${AppRoutes.certificationDetail}/$id',
            extra: const {'focus': 'renewal'},
          );
        }
        return;
      case NeedsAttentionKind.certificationMatch:
        context.go(AppRoutes.certifications);
        return;
      case NeedsAttentionKind.missingRequiredCertification:
        final requirementId = item.requirementId;
        if (requirementId == null) return;
        final roadmap = app.roadmap;
        if (roadmap == null) return;
        for (final rr in roadmap.all) {
          if (rr.requirement.id == requirementId) {
            AppRouter.openRequirement(context, rr.requirement);
            return;
          }
        }
        return;
      case NeedsAttentionKind.stalledTaskBook:
        context.go(AppRoutes.myPath);
        return;
    }
  }
}

class _AttentionTile extends StatelessWidget {
  final NeedsAttentionItem item;
  final VoidCallback onTap;

  const _AttentionTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = switch (item.kind) {
      NeedsAttentionKind.certificationExpired => Icons.error_outline,
      NeedsAttentionKind.certificationExpiring => Icons.event_outlined,
      NeedsAttentionKind.certificationMissingExpiration => Icons.event_busy_outlined,
      NeedsAttentionKind.certificationMatch => Icons.rule_outlined,
      NeedsAttentionKind.missingRequiredCertification => Icons.school_outlined,
      NeedsAttentionKind.stalledTaskBook => Icons.pause_circle_outline,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: .14)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: item.urgency == NeedsAttentionUrgency.now
                    ? cs.error
                    : cs.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      item.detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.actionLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
