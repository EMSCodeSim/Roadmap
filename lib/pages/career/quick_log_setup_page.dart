import 'package:flutter/material.dart';

import 'package:firepath/widgets/app_back_button.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/quick_log_template.dart';
import 'package:firepath/models/quick_log_tracker.dart';
import 'package:firepath/services/quick_log_preferences_store.dart';
import 'package:firepath/services/theme.dart';

class QuickLogSetupPage extends StatefulWidget {
  const QuickLogSetupPage({super.key});

  @override
  State<QuickLogSetupPage> createState() => _QuickLogSetupPageState();
}

class _QuickLogSetupPageState extends State<QuickLogSetupPage> {
  final QuickLogPreferencesStore _store = QuickLogPreferencesStore();
  bool _loading = true;
  bool _saving = false;
  List<String> _pinned = [];
  List<QuickLogTemplate> _custom = [];
  QuickLogRolePreset? _preset;
  List<String> _quickActionKeys = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await _store.load();
    if (!mounted) return;
    setState(() {
      _pinned = List<String>.from(preferences.pinnedIds);
      _custom = List<QuickLogTemplate>.from(preferences.customTemplates);
      _preset = _guessPreset(_pinned);
      _quickActionKeys = List<String>.from(preferences.quickActionKeys);
      _loading = false;
    });
  }

  static const List<(String, String, IconData)> _quickActionOptions = [
    ('call', 'CALL', Icons.local_fire_department_outlined),
    ('training', 'TRAINING', Icons.school_outlined),
    ('skill', 'SKILL', Icons.handyman_outlined),
    ('drive', 'DRIVE', Icons.local_shipping_outlined),
    ('task_book', 'TASK BOOK', Icons.fact_check_outlined),
    ('career', 'CAREER', Icons.military_tech_outlined),
  ];

  void _toggleQuickAction(String key) {
    setState(() {
      if (_quickActionKeys.contains(key)) {
        _quickActionKeys.remove(key);
      } else {
        _quickActionKeys.add(key);
      }
      if (_quickActionKeys.isEmpty) {
        _quickActionKeys =
            List<String>.from(QuickLogPreferencesStore.defaultQuickActionKeys);
      }
    });
  }

  QuickLogRolePreset? _guessPreset(List<String> pinned) {
    for (final preset in QuickLogRolePreset.values) {
      final defaults = QuickLogCatalog.defaultsFor(preset);
      if (defaults.length == pinned.length &&
          List.generate(
            defaults.length,
            (i) => defaults[i] == pinned[i],
          ).every((e) => e)) {
        return preset;
      }
    }
    return null;
  }

  List<QuickLogTracker> get _customTrackers => _custom
      .map(
        (template) => QuickLogTracker(
          keyName: template.id,
          title: template.title,
          category: template.category,
          type: template.type,
          iconName: template.iconKey,
          tracksOutcome: template.tracksOutcome,
          custom: true,
        ),
      )
      .toList();

  QuickLogTracker? _tracker(String key) =>
      QuickLogCatalog.byKey(key, _customTrackers);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = _pinned
        .map(_tracker)
        .whereType<QuickLogTracker>()
        .toList();
    final available = [
      ...QuickLogCatalog.builtIns,
      ..._customTrackers,
    ].where((tracker) => !_pinned.contains(tracker.keyName)).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton.toLog(),
        title: const Text('Set Up Quick Log'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Build the buttons you actually use',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pinned buttons appear first in Quick Log and prefill the activity name and category. Skills such as IV, IO, and advanced airway also keep success/failure tracking available.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'STARTING SET',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: QuickLogRolePreset.values.map((preset) {
                      return ChoiceChip(
                        label: Text(preset.label),
                        selected: _preset == preset,
                        onSelected: (_) {
                          setState(() {
                            _preset = preset;
                            _pinned = QuickLogCatalog.defaultsFor(preset);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'QUICK ACTIONS (TOP GRID)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick what shows up first when you open Quick Log. You can turn items on/off anytime.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickActionOptions.map((option) {
                      final key = option.$1;
                      final label = option.$2;
                      final icon = option.$3;
                      final selected = _quickActionKeys.contains(key);
                      return FilterChip(
                        selected: selected,
                        label: Text(label),
                        avatar: Icon(icon, size: 18),
                        onSelected: (_) => _toggleQuickAction(key),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'YOUR QUICK BUTTONS',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ),
                      Text('${selected.length} selected'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selected.isEmpty)
                    _EmptyPinned(onAddCustom: _createCustomButton)
                  else
                    ...selected.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tracker = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PinnedButtonTile(
                          tracker: tracker,
                          position: index + 1,
                          canMoveUp: index > 0,
                          canMoveDown: index < selected.length - 1,
                          onMoveUp: () => _move(index, index - 1),
                          onMoveDown: () => _move(index, index + 1),
                          onRemove: () =>
                              setState(() => _pinned.remove(tracker.keyName)),
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _createCustomButton,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create Custom Quick Button'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AVAILABLE BUTTONS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...available.map(
                    (tracker) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AvailableButtonTile(
                        tracker: tracker,
                        onAdd: () => setState(() {
                          _preset = null;
                          _pinned.add(tracker.keyName);
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: _loading || _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Saving…' : 'Save Quick Log Setup'),
            ),
          ),
        ),
      ),
    );
  }

  void _move(int from, int to) {
    if (to < 0 || to >= _pinned.length) return;
    setState(() {
      _preset = null;
      final item = _pinned.removeAt(from);
      _pinned.insert(to, item);
    });
  }

  Future<void> _createCustomButton() async {
    var type = CareerRecordType.skill;
    var trackOutcome = false;
    final title = TextEditingController();
    final category = TextEditingController();

    final template = await showDialog<QuickLogTemplate>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Custom Quick Button'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Button name',
                      hintText: 'Example: Pediatric IV',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: category,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CareerRecordType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Log type'),
                    items: CareerRecordType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: trackOutcome,
                    onChanged: (value) =>
                        setDialogState(() => trackOutcome = value),
                    title: const Text('Track success / failure'),
                    subtitle: const Text(
                      'Use this for procedures where attempts and success rate matter.',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final cleanTitle = title.text.trim();
                  if (cleanTitle.isEmpty) return;
                  final now = DateTime.now().millisecondsSinceEpoch;
                  Navigator.pop(
                    dialogContext,
                    QuickLogTemplate(
                      id: 'custom.$now',
                      title: cleanTitle,
                      category: category.text.trim().isEmpty
                          ? type.label
                          : category.text.trim(),
                      type: type,
                      tracksOutcome: trackOutcome,
                      iconKey: type == CareerRecordType.operationalExperience
                          ? 'fire'
                          : 'add_task',
                      isCustom: true,
                    ),
                  );
                },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );

    title.dispose();
    category.dispose();
    if (template == null || !mounted) return;
    setState(() {
      _preset = null;
      _custom.add(template);
      _pinned.add(template.id);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _store.save(
        QuickLogPreferences(
          pinnedIds: List<String>.from(_pinned),
          customTemplates: List<QuickLogTemplate>.from(_custom),
          quickActionKeys: List<String>.from(_quickActionKeys),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PinnedButtonTile extends StatelessWidget {
  final QuickLogTracker tracker;
  final int position;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  const _PinnedButtonTile({
    required this.tracker,
    required this.position,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            child: Text('$position'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tracker.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  tracker.tracksOutcome
                      ? '${tracker.category} • success tracking'
                      : tracker.category,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Move up',
            onPressed: canMoveUp ? onMoveUp : null,
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            tooltip: 'Move down',
            onPressed: canMoveDown ? onMoveDown : null,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _AvailableButtonTile extends StatelessWidget {
  final QuickLogTracker tracker;
  final VoidCallback onAdd;

  const _AvailableButtonTile({required this.tracker, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
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
                  tracker.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  tracker.tracksOutcome
                      ? '${tracker.category} • success tracking'
                      : tracker.category,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPinned extends StatelessWidget {
  final VoidCallback onAddCustom;
  const _EmptyPinned({required this.onAddCustom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'No quick buttons selected yet.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: onAddCustom,
              child: const Text('Create a Custom Button'),
            ),
          ),
        ],
      ),
    );
  }
}
