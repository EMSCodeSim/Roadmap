import 'package:flutter/material.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

class DepartmentClassesPage extends StatefulWidget {
  const DepartmentClassesPage({super.key});
  @override
  State<DepartmentClassesPage> createState() => _DepartmentClassesPageState();
}

class _DepartmentClassesPageState extends State<DepartmentClassesPage> {
  final _api = ResponderRoadmapApi();
  List<DepartmentClassSummary>? _classes;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final rows = await _api.listClasses(); if (mounted) setState(() { _classes = rows; _error = null; }); } catch (e) { if (mounted) setState(() { _classes = const []; _error = e.toString(); }); } }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Proctor Classes')),
    body: _classes == null ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Assigned skills rosters', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6), const Text('Select a class, choose a student, and record each skill result at the testing station.'),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 16),
        if (_classes!.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No classes are assigned to you.'))),
        ..._classes!.map((row) => Card(child: ListTile(
          contentPadding: const EdgeInsets.all(14), leading: const Icon(Icons.fact_check_outlined), title: Text(row.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${row.checklistTitle}\n${row.completeCount} of ${row.rosterCount} students complete · ${row.status}'), isThreeLine: true,
          trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _DepartmentClassDetailPage(classId: row.id))),
        ))),
      ]),
    ),
  );
}

class _DepartmentClassDetailPage extends StatefulWidget {
  final String classId;
  const _DepartmentClassDetailPage({required this.classId});
  @override
  State<_DepartmentClassDetailPage> createState() => _DepartmentClassDetailPageState();
}

class _DepartmentClassDetailPageState extends State<_DepartmentClassDetailPage> {
  final _api = ResponderRoadmapApi();
  DepartmentClassDetail? _detail;
  String? _studentId;
  String? _error;
  bool _busy = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { _setDetail(await _api.getClass(widget.classId)); } catch (e) { if (mounted) setState(() => _error = e.toString()); } }
  void _setDetail(DepartmentClassDetail detail) { if (!mounted) return; setState(() { _detail = detail; _studentId = detail.roster.any((item) => item.id == _studentId) ? _studentId : (detail.roster.isEmpty ? null : detail.roster.first.id); _error = null; }); }
  DepartmentClassStudent? get _student { for (final item in _detail?.roster ?? const <DepartmentClassStudent>[]) { if (item.id == _studentId) return item; } return null; }

  Future<String?> _correctionNotes(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text(title), content: TextField(controller: controller, maxLines: 4, autofocus: true, decoration: const InputDecoration(labelText: 'What must the student correct?')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (controller.text.trim().isNotEmpty) Navigator.pop(context, controller.text.trim()); }, child: const Text('Save result'))]));
  }

  Future<void> _record(DepartmentClassSkill skill, String result) async {
    final student = _student; if (student == null || _detail == null) return;
    var notes = ''; if (result == 'FAIL' || result == 'NEEDS_REMEDIATION') { final entered = await _correctionNotes(result == 'FAIL' ? 'Record failed skill' : 'Remediation required'); if (entered == null) return; notes = entered; }
    setState(() => _busy = true);
    try { _setDetail(await _api.recordClassSkill(classId: widget.classId, enrollmentId: student.id, requirementId: skill.id, result: result, notes: notes)); } catch (e) { if (mounted) setState(() => _error = e.toString()); } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail; final student = _student;
    return Scaffold(appBar: AppBar(title: Text(detail?.title ?? 'Class roster')), body: detail == null ? Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!)) : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 28), children: [
      Text(detail.checklistTitle, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _studentId, decoration: const InputDecoration(labelText: 'Student'), items: detail.roster.map((item) => DropdownMenuItem(value: item.id, child: Text('${item.name} · ${item.finalResult.replaceAll('_', ' ')}'))).toList(), onChanged: (value) => setState(() => _studentId = value)),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      if (student != null) ...[
        const SizedBox(height: 12), DropdownButtonFormField<String>(value: student.attendance, decoration: const InputDecoration(labelText: 'Attendance'), items: const ['REGISTERED', 'PRESENT', 'ABSENT', 'EXCUSED'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: _busy || detail.status == 'COMPLETE' ? null : (value) async { if (value == null) return; setState(() => _busy = true); try { _setDetail(await _api.updateClassStudent(classId: detail.id, enrollmentId: student.id, attendance: value)); } finally { if (mounted) setState(() => _busy = false); } }),
        const SizedBox(height: 18),
        ...detail.sections.map((section) => Card(margin: const EdgeInsets.only(bottom: 14), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(14), color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w900))),
          ...section.skills.map((skill) { DepartmentClassSkillResult? recorded; for (final item in student.results) { if (item.requirementId == skill.id) recorded = item; } return Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(skill.title, style: const TextStyle(fontWeight: FontWeight.w800))), Chip(label: Text((recorded?.result ?? 'NOT_EVALUATED').replaceAll('_', ' ')))]),
            if (skill.description.isNotEmpty) Text(skill.description), if (recorded != null) Padding(padding: const EdgeInsets.only(top: 5), child: Text('${recorded.evaluatorName}${recorded.notes.isEmpty ? '' : ' · ${recorded.notes}'}', style: Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height: 8), Wrap(spacing: 7, runSpacing: 7, children: [FilledButton(onPressed: _busy || detail.status == 'COMPLETE' ? null : () => _record(skill, 'PASS'), child: const Text('Pass')), OutlinedButton(onPressed: _busy || detail.status == 'COMPLETE' ? null : () => _record(skill, 'NEEDS_REMEDIATION'), child: const Text('Remediation')), OutlinedButton(onPressed: _busy || detail.status == 'COMPLETE' ? null : () => _record(skill, 'FAIL'), child: const Text('Fail')), TextButton(onPressed: _busy || detail.status == 'COMPLETE' ? null : () => _record(skill, 'NOT_APPLICABLE'), child: const Text('N/A'))]),
          ])); }),
        ]))),
      ],
    ]));
  }
}
