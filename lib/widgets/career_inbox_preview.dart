import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_inbox.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class CareerInboxPreview extends StatefulWidget {
  const CareerInboxPreview({super.key});

  @override
  State<CareerInboxPreview> createState() => _CareerInboxPreviewState();
}

class _CareerInboxPreviewState extends State<CareerInboxPreview> {
  final CareerRecordStore _store = CareerRecordStore();
  List<CareerRecord> _records = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
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
    final items = CareerInbox.build(app: app, records: _records);
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return Container(
        height: 72,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: .12)),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();
    final first = items.first;
    final urgent = first.priority <= 1;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () async {
        await context.push(AppRoutes.careerInbox);
        if (mounted) await _reload();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: urgent
              ? cs.errorContainer.withValues(alpha: .50)
              : cs.secondaryContainer.withValues(alpha: .60),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(
              Icons.inbox_outlined,
              color: urgent ? cs.error : cs.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${items.length} thing${items.length == 1 ? '' : 's'} need attention',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    first.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
