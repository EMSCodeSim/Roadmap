import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/theme.dart';

/// Searchable US state picker used in onboarding and profile edits.
class UsStatePickerSheet extends StatefulWidget {
  final String? selectedCode;
  const UsStatePickerSheet({super.key, required this.selectedCode});

  static Future<String?> pick(BuildContext context, {required String? selectedCode}) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => UsStatePickerSheet(selectedCode: selectedCode),
    );
  }

  @override
  State<UsStatePickerSheet> createState() => _UsStatePickerSheetState();
}

class _UsStatePickerSheetState extends State<UsStatePickerSheet> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = _search.text.trim().toLowerCase();

    final options = FireOpsCatalog.usStateOptions.where((o) {
      if (q.isEmpty) return true;
      return o.name.toLowerCase().contains(q) || o.code.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select state',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _search,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search states'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'Fire and EMS certification and advancement requirements can vary by state. Fire Career Roadmap uses your state to improve your Task Book recommendations.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final o = options[index];
                final selected = (widget.selectedCode ?? '').toUpperCase() == o.code;
                return Material(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () => context.pop(o.code),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              o.code,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(selected ? Icons.check_circle : Icons.chevron_right, color: selected ? cs.primary : cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
