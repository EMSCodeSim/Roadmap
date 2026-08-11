import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/career_record_store.dart';

class PersonalLogPage extends StatefulWidget {
  const PersonalLogPage({super.key});

  @override
  State<PersonalLogPage> createState() => _PersonalLogPageState();
}

class _PersonalLogPageState extends State<PersonalLogPage> {
  final CareerRecordStore _store = CareerRecordStore();
  final TextEditingController _searchController = TextEditingController();

  List<CareerRecord> _records = <CareerRecord>[];
  bool _loading = true;
  int? _selectedYear = DateTime.now().year;

  static const List<_QuickPreset> _presets = [
    _QuickPreset(
      keyName: 'ems.iv',
      title: 'IV attempt',
      category: 'EMS skill',
      type: CareerRecordType.skill,
      icon: Icons.vaccines_outlined,
      tracksOutcome: true,
    ),
    _QuickPreset(
      keyName: 'ems.io',
      title: 'IO attempt',
      category: 'EMS skill',
      type: CareerRecordType.skill,
      icon: Icons.medical_services_outlined,
      tracksOutcome: true,
    ),
    _QuickPreset(
      keyName: 'ems.airway',
      title: 'Advanced airway',
      category: 'Airway',
      type: CareerRecordType.skill,
      icon: Icons.air_outlined,
      tracksOutcome: true,
    ),
    _QuickPreset(
      keyName: 'ems.cardiac_arrest',
      title: 'Cardiac arrest',
      category: 'EMS call',
      type: CareerRecordType.operationalExperience,
      icon: Icons.monitor_heart_outlined,
    ),
    _QuickPreset(
      keyName: 'fire.car_fire',
      title: 'Car fire',
      category: 'Fire call',
      type: CareerRecordType.operationalExperience,
      icon: Icons.directions_car_filled_outlined,
    ),
    _QuickPreset(
      keyName: 'fire.structure_fire',
      title: 'Structure fire',
      category: 'Fire call',
      type: CareerRecordType.operationalExperience,
      icon: Icons.home_work_outlined,
    ),
    _QuickPreset(
      keyName: 'fire.wildland',
      title: 'Wildland fire',
      category: 'Fire call',
      type: CareerRecordType.operationalExperience,
      icon: Icons.local_fire_department_outlined,
    ),
    _QuickPreset(
      keyName: 'fire.extrication',
      title: 'Extrication',
      category: 'Rescue',
      type: CareerRecordType.operationalExperience,
      icon: Icons.car_crash_outlined,
    ),
    _QuickPreset(
      keyName: 'fire.pump_ops',
      title: 'Pump operation',
      category: 'Driver / Operator',
      type: CareerRecordType.skill,
      icon: Icons.water_drop_outlined,
    ),
    _QuickPreset(
      keyName: 'fire.driver',
      title: 'Emergency driving',
      category: 'Driver / Operator',
      type: CareerRecordType.skill,
      icon: Icons.fire_truck_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final records = await _store.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _persist(List<CareerRecord> next) async {
    next.sort((a, b) => b.date.compareTo(a.date));
    await _store.save(next);
    if (!mounted) return;
    setState(() => _records = next);
  }

  Future<void> _quickLog(_QuickPreset preset) async {
    CareerRecordOutcome? outcome;
    if (preset.tracksOutcome) {
      outcome = await _pickOutcome(preset);
      if (outcome == null) return;
    }

    final now = DateTime.now();
    final record = CareerRecord(
      id: now.microsecondsSinceEpoch.toRadixString(36),
      type: preset.type,
      title: preset.title,
      category: preset.category,
      date: now,
      roleOrAssignment: null,
      summary: null,
      impact: null,
      evidenceReference: null,
      hours: null,
      repetitions: 1,
      tags: const ['quick-log'],
      relatedGoalId: null,
      relatedRequirementId: null,
      highlight: false,
      trackingKey: preset.keyName,
      outcome: outcome,
      createdAt: now,
      updatedAt: now,
    );
    await _persist([..._records, record]);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${preset.title}${outcome == null ? '' : ' • ${outcome.label}'} logged.'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => _undoRecord(record.id),
        ),
      ),
    );
  }

  Future<void> _undoRecord(String id) async {
    await _persist(_records.where((record) => record.id != id).toList());
  }

  Future<CareerRecordOutcome?> _pickOutcome(_QuickPreset preset) {
    return showModalBottomSheet<CareerRecordOutcome>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                preset.title,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'How did this attempt go?',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, CareerRecordOutcome.successful),
                icon: const Icon(Icons.check_circle_outline),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Successful'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(sheetContext, CareerRecordOutcome.unsuccessful),
                icon: const Icon(Icons.cancel_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Unsuccessful'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, CareerRecordOutcome.attempted),
                child: const Text('Log attempt without outcome'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCustomLog() async {
    var type = CareerRecordType.operationalExperience;
    var selectedDate = DateTime.now();
    CareerRecordOutcome? outcome;
    final title = TextEditingController();
    final category = TextEditingController();
    final count = TextEditingController(text: '1');
    final note = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<CareerRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Log past or custom activity'),
          content: SizedBox(
            width: 560,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Use this for anything you want to count over time. Avoid patient names or other identifying information.',
                      style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                            color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<CareerRecordType>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: CareerRecordType.values
                          .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setDialogState(() => type = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: title,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'What are you tracking?',
                        hintText: 'Pediatric IV, vehicle fire, rope rescue, teaching shift…',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Add a name.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: category,
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                        hintText: 'EMS, Fire, Rescue, Driver / Operator…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDate,
                                firstDate: DateTime(1970),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setDialogState(() => selectedDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today_outlined, size: 18),
                            label: Text(_formatDate(selectedDate)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: count,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Count'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CareerRecordOutcome?>(
                      initialValue: outcome,
                      decoration: const InputDecoration(labelText: 'Outcome (optional)'),
                      items: [
                        const DropdownMenuItem<CareerRecordOutcome?>(value: null, child: Text('Not tracked')),
                        ...CareerRecordOutcome.values.map(
                          (value) => DropdownMenuItem<CareerRecordOutcome?>(value: value, child: Text(value.label)),
                        ),
                      ],
                      onChanged: (value) => setDialogState(() => outcome = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: note,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Quick note (optional)',
                        hintText: 'Keep it brief. Add detailed evidence separately if this matters for promotion or a task book.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final parsedCount = int.tryParse(count.text.trim());
                final now = DateTime.now();
                final cleanTitle = title.text.trim();
                Navigator.pop(
                  dialogContext,
                  CareerRecord(
                    id: now.microsecondsSinceEpoch.toRadixString(36),
                    type: type,
                    title: cleanTitle,
                    category: category.text.trim().isEmpty ? type.label : category.text.trim(),
                    date: selectedDate,
                    roleOrAssignment: null,
                    summary: note.text.trim().isEmpty ? null : note.text.trim(),
                    impact: null,
                    evidenceReference: null,
                    hours: null,
                    repetitions: parsedCount != null && parsedCount > 0 ? parsedCount : 1,
                    tags: const ['quick-log', 'custom-log'],
                    relatedGoalId: null,
                    relatedRequirementId: null,
                    highlight: false,
                    trackingKey: _trackingKeyFor(cleanTitle),
                    outcome: outcome,
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    category.dispose();
    count.dispose();
    note.dispose();

    if (result != null) {
      await _persist([..._records, result]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personal log updated.')));
    }
  }

  List<int> get _years {
    final years = <int>{DateTime.now().year, ..._records.map((record) => record.date.year)}.toList()..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<CareerRecord> get _yearRecords {
    return _records.where((record) => _selectedYear == null || record.date.year == _selectedYear).toList();
  }

  List<CareerRecord> get _visibleRecords {
    final q = _searchController.text.trim().toLowerCase();
    return _yearRecords.where((record) {
      if (q.isEmpty) return true;
      final text = [
        record.title,
        record.category,
        record.type.label,
        record.outcome?.label ?? '',
        record.summary ?? '',
        ...record.tags,
      ].join(' ').toLowerCase();
      return text.contains(q);
    }).toList();
  }

  List<_LogAggregate> get _aggregates {
    final q = _searchController.text.trim().toLowerCase();
    final map = <String, _LogAggregate>{};
    for (final record in _yearRecords) {
      final key = record.trackingKey ?? _trackingKeyFor(record.title);
      final existing = map[key];
      final next = existing ?? _LogAggregate(keyName: key, title: record.title, category: record.category, type: record.type);
      next.total += record.repetitions;
      if (record.outcome == CareerRecordOutcome.successful) next.successful += record.repetitions;
      if (record.outcome == CareerRecordOutcome.unsuccessful) next.unsuccessful += record.repetitions;
      if (next.lastDate == null || record.date.isAfter(next.lastDate!)) next.lastDate = record.date;
      map[key] = next;
    }
    final values = map.values.where((item) {
      if (q.isEmpty) return true;
      return '${item.title} ${item.category} ${item.type.label}'.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return values;
  }

  int _countForPreset(_QuickPreset preset, int year) {
    return _records
        .where((record) => record.date.year == year && (record.trackingKey == preset.keyName || _trackingKeyFor(record.title) == preset.keyName))
        .fold<int>(0, (sum, record) => sum + record.repetitions);
  }

  String? _successLabelForPreset(_QuickPreset preset, int year) {
    if (!preset.tracksOutcome) return null;
    var success = 0;
    var unsuccessful = 0;
    for (final record in _records.where((record) => record.date.year == year && record.trackingKey == preset.keyName)) {
      if (record.outcome == CareerRecordOutcome.successful) success += record.repetitions;
      if (record.outcome == CareerRecordOutcome.unsuccessful) unsuccessful += record.repetitions;
    }
    final measured = success + unsuccessful;
    if (measured == 0) return null;
    return '${(success / measured * 100).round()}% success';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentYear = DateTime.now().year;
    final yearRecords = _yearRecords;
    final totalLogged = yearRecords.fold<int>(0, (sum, record) => sum + record.repetitions);
    final skillCount = yearRecords.where((record) => record.type == CareerRecordType.skill).fold<int>(0, (sum, record) => sum + record.repetitions);
    final callCount = yearRecords.where((record) => record.type == CareerRecordType.operationalExperience).fold<int>(0, (sum, record) => sum + record.repetitions);
    final successful = yearRecords.where((record) => record.outcome == CareerRecordOutcome.successful).fold<int>(0, (sum, record) => sum + record.repetitions);
    final unsuccessful = yearRecords.where((record) => record.outcome == CareerRecordOutcome.unsuccessful).fold<int>(0, (sum, record) => sum + record.repetitions);
    final measured = successful + unsuccessful;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Log'),
        actions: [
          IconButton(
            tooltip: 'Detailed career evidence',
            onPressed: () => context.push(AppRoutes.careerEvidence),
            icon: const Icon(Icons.auto_stories_outlined),
          ),
          IconButton(
            tooltip: 'Log past or custom activity',
            onPressed: _openCustomLog,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                children: [
                  Card(
                    color: cs.primaryContainer.withValues(alpha: 0.55),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Log it in seconds', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(
                            'Use this every shift for routine skills and calls. Your counts stay searchable by year, so today’s quick tap can answer questions years from now.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _openCustomLog,
                                  icon: const Icon(Icons.history_toggle_off_outlined),
                                  label: const Text('Past / custom'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push(AppRoutes.careerEvidence),
                                  icon: const Icon(Icons.note_add_outlined),
                                  label: const Text('Detailed evidence'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Quick Log', subtitle: 'Tap a call once. Skills ask only for the outcome.'),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.55,
                    ),
                    itemCount: _presets.length,
                    itemBuilder: (context, index) {
                      final preset = _presets[index];
                      return _QuickLogCard(
                        preset: preset,
                        count: _countForPreset(preset, currentYear),
                        successLabel: _successLabelForPreset(preset, currentYear),
                        onTap: () => _quickLog(preset),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: _SectionTitle(title: 'Your activity', subtitle: 'Change the year to look back at old calls and skills.')),
                      const SizedBox(width: 10),
                      DropdownButton<int?>(
                        value: _selectedYear,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All time')),
                          ..._years.map((year) => DropdownMenuItem<int?>(value: year, child: Text('$year'))),
                        ],
                        onChanged: (value) => setState(() => _selectedYear = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricChip(label: 'Logged', value: '$totalLogged', icon: Icons.add_task_outlined),
                      _MetricChip(label: 'Skills', value: '$skillCount', icon: Icons.handyman_outlined),
                      _MetricChip(label: 'Calls', value: '$callCount', icon: Icons.local_fire_department_outlined),
                      _MetricChip(
                        label: 'Success rate',
                        value: measured == 0 ? '—' : '${(successful / measured * 100).round()}%',
                        icon: Icons.trending_up_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search IV, car fire, extrication, 2023 activity…',
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_aggregates.isEmpty)
                    const _EmptyLogCard()
                  else
                    ..._aggregates.take(20).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AggregateCard(item: item),
                          ),
                        ),
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'Recent entries', subtitle: 'Routine entries stay simple. Use Detailed Evidence for promotion-worthy events.'),
                  const SizedBox(height: 10),
                  if (_visibleRecords.isEmpty)
                    const _EmptyLogCard()
                  else
                    ..._visibleRecords.take(30).map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: _RecentRecord(record: record),
                          ),
                        ),
                  const SizedBox(height: 8),
                  Text(
                    'Privacy reminder: this is a personal professional log. Do not enter patient names, addresses, DOBs, or other identifying information.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
    );
  }

  static String _trackingKeyFor(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.').replaceAll(RegExp(r'^\.+|\.+$'), '');
    return normalized.isEmpty ? 'custom.activity' : 'custom.$normalized';
  }

  static String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class _QuickPreset {
  final String keyName;
  final String title;
  final String category;
  final CareerRecordType type;
  final IconData icon;
  final bool tracksOutcome;

  const _QuickPreset({
    required this.keyName,
    required this.title,
    required this.category,
    required this.type,
    required this.icon,
    this.tracksOutcome = false,
  });
}

class _QuickLogCard extends StatelessWidget {
  final _QuickPreset preset;
  final int count;
  final String? successLabel;
  final VoidCallback onTap;

  const _QuickLogCard({required this.preset, required this.count, required this.successLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Icon(preset.icon, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(preset.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('$count this year', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    if (successLabel != null)
                      Text(successLabel!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogAggregate {
  final String keyName;
  final String title;
  final String category;
  final CareerRecordType type;
  int total = 0;
  int successful = 0;
  int unsuccessful = 0;
  DateTime? lastDate;

  _LogAggregate({required this.keyName, required this.title, required this.category, required this.type});
}

class _AggregateCard extends StatelessWidget {
  final _LogAggregate item;
  const _AggregateCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final measured = item.successful + item.unsuccessful;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    '${item.category}${item.lastDate == null ? '' : ' • last ${_PersonalLogPageState._formatDate(item.lastDate!)}'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (measured > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${item.successful} successful • ${item.unsuccessful} unsuccessful • ${(item.successful / measured * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('${item.total}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 7),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _RecentRecord extends StatelessWidget {
  final CareerRecord record;
  const _RecentRecord({required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${_PersonalLogPageState._formatDate(record.date)} • ${record.category}${record.outcome == null ? '' : ' • ${record.outcome!.label}'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                if ((record.summary ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(record.summary!, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          if (record.repetitions > 1)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text('×${record.repetitions}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _EmptyLogCard extends StatelessWidget {
  const _EmptyLogCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Nothing logged for this view yet. Use Quick Log above, or add a past/custom activity.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
