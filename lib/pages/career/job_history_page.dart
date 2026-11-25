import 'package:flutter/material.dart';
import 'package:firepath/services/local_store.dart';

class JobHistoryEntry {
  const JobHistoryEntry({
    required this.id,
    required this.employer,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.employmentType,
    required this.location,
    required this.notes,
  });

  final String id;
  final String employer;
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String employmentType;
  final String location;
  final String notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'employer': employer,
        'title': title,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isCurrent': isCurrent,
        'employmentType': employmentType,
        'location': location,
        'notes': notes,
      };

  factory JobHistoryEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return JobHistoryEntry(
      id: json['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      employer: json['employer'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? now,
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      isCurrent: json['isCurrent'] as bool? ?? false,
      employmentType: json['employmentType'] as String? ?? 'Career',
      location: json['location'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}

class JobHistoryPage extends StatefulWidget {
  const JobHistoryPage({super.key});

  @override
  State<JobHistoryPage> createState() => _JobHistoryPageState();
}

class _JobHistoryPageState extends State<JobHistoryPage> {
  static const _storageKey = 'fireops.personalJobHistory.v1';
  final _localStore = LocalStore();
  List<JobHistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _localStore.loadJsonList(_storageKey);
    if (!mounted) return;
    setState(() {
      _entries = rows.map(JobHistoryEntry.fromJson).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _localStore.saveJson(
      _storageKey,
      _entries.map((entry) => entry.toJson()).toList(),
    );
  }

  Future<void> _edit([JobHistoryEntry? entry]) async {
    final result = await Navigator.of(context).push<JobHistoryEntry>(
      MaterialPageRoute(
        builder: (_) => _JobRoleEditorPage(entry: entry),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _entries.indexWhere((item) => item.id == result.id);
      if (index < 0) {
        _entries.add(result);
      } else {
        _entries[index] = result;
      }
      _entries.sort((a, b) => b.startDate.compareTo(a.startDate));
    });
    await _save();
  }

  Future<void> _delete(JobHistoryEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this position?'),
        content: const Text('This job history entry will be deleted from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _entries.removeWhere((item) => item.id == entry.id));
    await _save();
  }

  String _date(DateTime value) => '${_month(value.month)} ${value.year}';

  String _month(int month) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][month - 1];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentCount = _entries.where((entry) => entry.isCurrent).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Job History')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Add position'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work_history_outlined, size: 52, color: cs.primary),
                        const SizedBox(height: 14),
                        Text('Build your work history',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text(
                          'Keep each role, agency, and service period together. This becomes the foundation for a resume and a clearer view of your career.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () => _edit(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add your first position'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    Card(
                      color: cs.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.work_history_outlined, color: cs.onPrimaryContainer, size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_entries.length} ${_entries.length == 1 ? 'position' : 'positions'} documented · $currentCount current',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._entries.map((entry) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                            leading: CircleAvatar(
                              backgroundColor: cs.secondaryContainer,
                              child: Icon(Icons.business_center_outlined, color: cs.onSecondaryContainer),
                            ),
                            title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                '${entry.employer} · ${entry.employmentType}\n'
                                '${_date(entry.startDate)} – ${entry.isCurrent ? 'Present' : _date(entry.endDate ?? entry.startDate)}'
                                '${entry.location.isEmpty ? '' : '\n${entry.location}'}'
                                '${entry.notes.isEmpty ? '' : '\n${entry.notes}'}',
                              ),
                            ),
                            isThreeLine: entry.location.isNotEmpty || entry.notes.isNotEmpty,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) => value == 'edit' ? _edit(entry) : _delete(entry),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Remove')),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
    );
  }
}

class _JobRoleEditorPage extends StatefulWidget {
  const _JobRoleEditorPage({this.entry});
  final JobHistoryEntry? entry;

  @override
  State<_JobRoleEditorPage> createState() => _JobRoleEditorPageState();
}

class _JobRoleEditorPageState extends State<_JobRoleEditorPage> {
  static const _types = ['Career', 'Volunteer', 'Part-time', 'Seasonal', 'Contract', 'Other'];
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _employer;
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late DateTime _start;
  DateTime? _end;
  late bool _current;
  late String _type;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _employer = TextEditingController(text: entry?.employer ?? '');
    _title = TextEditingController(text: entry?.title ?? '');
    _location = TextEditingController(text: entry?.location ?? '');
    _notes = TextEditingController(text: entry?.notes ?? '');
    _start = entry?.startDate ?? DateTime.now();
    _end = entry?.endDate;
    _current = entry?.isCurrent ?? true;
    _type = entry?.employmentType ?? 'Career';
  }

  @override
  void dispose() {
    _employer.dispose();
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _format(DateTime? date) => date == null
      ? 'Select date'
      : '${date.month}/${date.day}/${date.year}';

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : (_end ?? DateTime.now()),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
        _current = false;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(JobHistoryEntry(
      id: widget.entry?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      employer: _employer.text.trim(),
      title: _title.text.trim(),
      startDate: _start,
      endDate: _current ? null : _end,
      isCurrent: _current,
      employmentType: _type,
      location: _location.text.trim(),
      notes: _notes.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Add position' : 'Edit position'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Position or title *', hintText: 'Paramedic, Firefighter, Instructor'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter a position or title' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _employer,
              decoration: const InputDecoration(labelText: 'Employer or agency *'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter an employer or agency' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Service type'),
              items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(_format(_start)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: () => _pickDate(start: true),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('I currently work here'),
              value: _current,
              onChanged: (value) => setState(() => _current = value),
            ),
            if (!_current)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End date'),
                subtitle: Text(_format(_end)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: () => _pickDate(start: false),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Role notes (optional)',
                hintText: 'Key responsibilities, assignments, or progression',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
}
