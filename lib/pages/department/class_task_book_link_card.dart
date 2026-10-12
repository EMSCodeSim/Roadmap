import 'package:flutter/material.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/pages/department/class_workflow_rules.dart';

/// Mobile companion to the website's class -> Task Book workflow.
/// No competency or qualification is approved by creating assignments.
class ClassTaskBookLinkCard extends StatefulWidget {
  const ClassTaskBookLinkCard({
    super.key,
    required this.detail,
    required this.onAssigned,
  });

  final DepartmentClassDetail detail;
  final VoidCallback onAssigned;

  @override
  State<ClassTaskBookLinkCard> createState() => _ClassTaskBookLinkCardState();
}

class _ClassTaskBookLinkCardState extends State<ClassTaskBookLinkCard> {
  final _api = ResponderRoadmapApi();
  List<Map<String, dynamic>>? _books;
  List<Map<String, dynamic>> _assignments = [];
  bool _progressLoading = false;
  bool _verifyBeforeRetry = false;
  String? _selectedBook;
  final Set<String> _selectedMembers = {};
  String? _error;
  String? _message;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadProgress();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _api.listPublishedClassTaskBooks();
      if (mounted) setState(() { _books = books; _error = null; });
    } catch (error) {
      if (mounted) setState(() { _books = const []; _error = error.toString(); });
    }
  }

  Future<void> _loadProgress() async {
    if (!mounted) return;
    setState(() => _progressLoading = true);
    try {
      final assignments = await _api.listDepartmentTaskBookAssignments();
      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _progressLoading = false;
        _verifyBeforeRetry = false;
      });
    } catch (error) {
      if (mounted) setState(() {
        _progressLoading = false;
        _error = 'Could not refresh assignment progress: $error';
      });
    }
  }

  void _select(Iterable<DepartmentClassStudent> students) {
    setState(() {
      _selectedMembers
        ..clear()
        ..addAll(eligibleClassMembershipIds(students));
    });
  }

  Future<void> _assign() async {
    if (_saving || _verifyBeforeRetry || _selectedBook == null || _selectedMembers.isEmpty) return;
    final count = _selectedMembers.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Task Book?'),
        content: Text('Assign to $count selected class members? Existing assignments are skipped. Attendance does not pass skills; individual evidence and evaluator approval are still required.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Assign')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() { _saving = true; _error = null; _message = null; });
    try {
      final result = await _api.assignTaskBookToClassRoster(
        classId: widget.detail.id,
        templateId: _selectedBook!,
        membershipIds: _selectedMembers.toList(),
      );
      if (!mounted) return;
      setState(() {
        _message = '${result['created'] ?? 0} assigned · ${result['skipped'] ?? 0} already assigned';
        _selectedMembers.clear();
      });
      widget.onAssigned();
      await _loadProgress();
    } on ResponderRoadmapApiException catch (error) {
      if (mounted) setState(() {
        _verifyBeforeRetry = assignmentResponseMayBeAmbiguous(error);
        _error = _verifyBeforeRetry
            ? 'Connection interrupted. The assignment may have been saved. Refresh progress before retrying to avoid duplicate requests.'
            : error.message;
      });
    } catch (error) {
      if (mounted) setState(() { _verifyBeforeRetry = true; _error = 'Could not confirm assignment. Refresh progress before retrying: $error'; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.detail.roster.where((student) => student.membershipId?.isNotEmpty == true).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CONNECT CLASS TO TASK BOOK', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Assign a published Task Book to this class roster. Class results can become evidence only after class completion and instructor approval. Each Task Book sign-off and qualification decision remains separate.'),
          const SizedBox(height: 12),
          if (_books == null) const LinearProgressIndicator()
          else if (_books!.isEmpty) const Text('No published Task Books are available for assignment.')
          else DropdownButtonFormField<String>(
            value: _selectedBook,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Published Task Book', border: OutlineInputBorder()),
            items: _books!.map((book) => DropdownMenuItem<String>(
              value: book['id'] as String,
              child: Text(book['title']?.toString() ?? 'Task Book', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: _saving ? null : (value) => setState(() => _selectedBook = value),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 4, children: [
            OutlinedButton(onPressed: _saving ? null : () => _select(members.where((m) => m.attendance == 'PRESENT')), child: const Text('Present')),
            OutlinedButton(onPressed: _saving ? null : () => _select(members), child: const Text('Entire roster')),
            TextButton(onPressed: _saving ? null : () => _select(const []), child: const Text('Clear')),
          ]),
          if (members.isEmpty) const Text('No linked department members on this roster. Guests cannot receive department Task Books.'),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 230),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final id = member.membershipId!;
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(member.name),
                  subtitle: Text(member.attendance),
                  value: _selectedMembers.contains(id),
                  onChanged: _saving ? null : (checked) => setState(() {
                    if (checked == true) { _selectedMembers.add(id); } else { _selectedMembers.remove(id); }
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('Roster Task Book progress', style: Theme.of(context).textTheme.titleSmall)),
            IconButton(
              tooltip: 'Refresh assignment progress',
              onPressed: _progressLoading || _saving ? null : _loadProgress,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ]),
          if (_progressLoading) const LinearProgressIndicator(),
          for (final member in members)
            Builder(builder: (context) {
              final linked = classMemberAssignments(_assignments, member.membershipId!);
              if (linked.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  for (final assignment in linked)
                    Text(
                      '${assignment['taskBookTitle'] ?? 'Task Book'} · ${assignment['progress'] ?? 0}% · ${assignment['pendingApproval'] ?? 0} awaiting approval · ${assignment['status'] ?? 'IN_PROGRESS'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ]),
              );
            }),
          if (_verifyBeforeRetry) const Text(
            'Assignment result uncertain. Refresh progress to verify what was saved before trying again.',
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _saving || _verifyBeforeRetry || _selectedBook == null || _selectedMembers.isEmpty ? null : _assign,
            icon: const Icon(Icons.assignment_add),
            label: Text(_saving ? 'Assigning…' : 'Assign to ${_selectedMembers.length} selected'),
          )),
          if (_message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.primary))),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ]),
      ),
    );
  }
}
