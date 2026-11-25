import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/pages/career/quick_log_launcher.dart';
import 'package:firepath/nav.dart';

class FireOpsImportPage extends StatefulWidget {
  final Uri uri;
  const FireOpsImportPage({super.key, required this.uri});
  @override
  State<FireOpsImportPage> createState() => _FireOpsImportPageState();
}
class _FireOpsImportPageState extends State<FireOpsImportPage> {
  final _minutes = TextEditingController();
  final _notes = TextEditingController();
  bool _confirmed = false;
  bool _busy = false;
  String? _error;
  String get _id => widget.uri.queryParameters['id'] ?? '';
  String get _title => widget.uri.queryParameters['title'] ?? '';
  String get _category => widget.uri.queryParameters['category'] ?? '';
  bool get _valid => RegExp(r'^[a-z0-9-]{1,100}$').hasMatch(_id) && _title.trim().isNotEmpty && _title.length <= 200 && _category.length <= 100;
  @override
  void dispose() { _minutes.dispose(); _notes.dispose(); super.dispose(); }
  Future<void> _save() async {
    final minutes = int.tryParse(_minutes.text.trim());
    if (!_valid || !_confirmed || minutes == null || minutes < 1 || minutes > 1440) {
      setState(() => _error = 'Confirm completion and enter actual minutes (1–1440).'); return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final now = DateTime.now();
      final store = CareerRecordStore();
      await store.load();
      final record = CareerRecord(id: 'fireops-${now.microsecondsSinceEpoch}', type: CareerRecordType.training, title: _title.trim(), category: _category.trim().isEmpty ? 'Fire training' : _category.trim(), date: now, roleOrAssignment: null, summary: _notes.text.trim().isEmpty ? 'Self-reported FireOpsSim practice.' : _notes.text.trim(), impact: null, evidenceReference: Uri.https('fireopssim.com','/drill-library.html',{'q':_title}).toString(), hours: minutes / 60, repetitions: 1, tags: const ['fireopssim','self-reported'], relatedGoalId: null, relatedRequirementId: null, highlight: false, outcome: CareerRecordOutcome.completed, details: {'source':'FireOpsSim','drillId':_id,'actualMinutes':minutes}, createdAt: now, updatedAt: now);
      if (!await store.upsert(record)) throw StateError('Save failed');
      QuickLogLauncher.recordRevision.value++;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personal training saved.')));
      context.go(AppRoutes.personalLog);
    } catch (_) { if(mounted) setState(() { _busy = false; _error = 'Unable to save. Please review your records before retrying.'; }); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Log FireOpsSim training')), body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
    if (!_valid) const Text('Invalid training link. Return to FireOpsSim and choose a drill.'),
    if (_valid) ...[
      Text(_title, style: Theme.of(context).textTheme.headlineSmall),
      Text(_category),
      const SizedBox(height: 12),
      const Text('Personal, self-reported practice only. This does not award CE, department credit or qualification sign-off.'),
      TextField(controller: _minutes, enabled: !_busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual minutes practiced')),
      TextField(controller: _notes, enabled: !_busy, maxLength: 2000, maxLines: 4, decoration: const InputDecoration(labelText: 'What did you practice or learn?')),
      CheckboxListTile(value: _confirmed, onChanged: _busy ? null : (v) => setState(() => _confirmed = v ?? false), title: const Text('I completed this practice.')),
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      FilledButton(onPressed: _busy || !_confirmed ? null : _save, child: Text(_busy ? 'Saving…' : 'Save personal training')),
    ],
    TextButton(onPressed: _busy ? null : () => context.go(AppRoutes.home), child: const Text('Cancel / Home')),
  ])));
}
