import 'package:flutter/material.dart';

import 'package:firepath/models/home_section_preference.dart';
import 'package:firepath/services/home_section_preferences_store.dart';
import 'package:firepath/services/theme.dart';

class HomeScreenCustomizationSheet extends StatefulWidget {
  final HomeSectionPreferencesStore store;

  HomeScreenCustomizationSheet({
    super.key,
    HomeSectionPreferencesStore? store,
  }) : store = store ?? HomeSectionPreferencesStore();

  static Future<bool?> show(BuildContext context) => showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => HomeScreenCustomizationSheet(),
      );

  @override
  State<HomeScreenCustomizationSheet> createState() =>
      _HomeScreenCustomizationSheetState();
}

class _HomeScreenCustomizationSheetState
    extends State<HomeScreenCustomizationSheet> {
  List<HomeSectionPreference> _items = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _setVisible(int index, bool value) {
    final visibleCount = _items.where((item) => item.visible).length;
    if (!value && visibleCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep at least one Home section visible.')),
      );
      return;
    }
    setState(() => _items[index] = _items[index].copyWith(visible: value));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await widget.store.save(_items);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Home Screen choices could not be saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize Home Screen',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Choose what appears on Home. Drag sections into the order that is most useful to you.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                    buildDefaultDragHandles: false,
                    itemCount: _items.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _items.removeAt(oldIndex);
                        _items.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Padding(
                        key: ValueKey(item.type),
                        padding: const EdgeInsets.only(bottom: 9),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          opacity: item.visible ? 1 : 0.58,
                          child: Container(
                            decoration: BoxDecoration(
                              color: item.visible
                                  ? cs.primaryContainer.withValues(alpha: 0.34)
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: item.visible
                                    ? cs.primary.withValues(alpha: 0.24)
                                    : cs.outline.withValues(alpha: 0.14),
                              ),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(12, 7, 6, 7),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: item.visible
                                      ? cs.primary
                                      : cs.onSurfaceVariant
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  item.type.icon,
                                  color: item.visible
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                              title: Text(
                                item.type.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(item.type.description),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch.adaptive(
                                    key: Key(
                                      'home_section_toggle_${item.type.name}',
                                    ),
                                    value: item.visible,
                                    onChanged: (value) =>
                                        _setVisible(index, value),
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.drag_handle_rounded),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _loading || _saving ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Saving…' : 'Save Home Screen'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
