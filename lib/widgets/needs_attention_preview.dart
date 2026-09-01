import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/needs_attention_engine.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/services/theme.dart';

class NeedsAttentionPreview extends StatefulWidget {
  const NeedsAttentionPreview({super.key});

  @override
  State<NeedsAttentionPreview> createState() => _NeedsAttentionPreviewState();
}

class _NeedsAttentionPreviewState extends State<NeedsAttentionPreview> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loaded = false;

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
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final app = context.watch<AppState>();
    final items = NeedsAttentionEngine.analyze(app: app, records: _records);
    if (items.isEmpty) return const SizedBox.shrink();

    final nowCount = items
        .where((item) => item.urgency == NeedsAttentionUrgency.now)
        .length;
    final preview = items.take(2).toList();
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: .34),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.error.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: cs.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Needs Attention',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                '${items.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.error,
                    ),
              ),
            ],
          ),
          if (nowCount > 0) ...[
            const SizedBox(height: 3),
            Text(
              '$nowCount ${nowCount == 1 ? 'item needs' : 'items need'} attention now',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          const SizedBox(height: 10),
          ...preview.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.urgency == NeedsAttentionUrgency.now
                        ? Icons.priority_high_rounded
                        : Icons.schedule_outlined,
                    size: 17,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.needsAttention),
              icon: const Icon(Icons.rule_outlined),
              label: const Text('Review'),
            ),
          ),
        ],
      ),
    );
  }
}
