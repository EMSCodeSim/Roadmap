import 'package:flutter/material.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

class DepartmentQualificationsPage extends StatefulWidget {
  const DepartmentQualificationsPage({super.key});

  @override
  State<DepartmentQualificationsPage> createState() => _DepartmentQualificationsPageState();
}

class _DepartmentQualificationsPageState extends State<DepartmentQualificationsPage> {
  final _api = ResponderRoadmapApi();
  List<DepartmentQualificationRole> _mine = const [];
  List<DepartmentQualificationMember> _members = const [];
  bool _loading = true;
  bool _canLookup = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final mine = await _api.getMyQualifications();
      List<DepartmentQualificationMember> members = const [];
      var canLookup = true;
      try {
        members = await _api.getDepartmentQualifications();
      } on ResponderRoadmapApiException catch (e) {
        if (e.statusCode == 403) {
          canLookup = false;
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      setState(() {
        _mine = mine;
        _members = members;
        _canLookup = canLookup;
        _loading = false;
      });
    } on ResponderRoadmapApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = _members.where((member) {
      if (q.isEmpty) return true;
      if (member.name.toLowerCase().contains(q) ||
          member.rank.toLowerCase().contains(q) ||
          member.position.toLowerCase().contains(q)) return true;
      return member.qualifications.any((role) =>
          role.name.toLowerCase().contains(q) ||
          role.status.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Qualifications')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const ListView(children: [SizedBox(height: 220), Center(child: CircularProgressIndicator())])
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!))),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My qualifications', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          const Text('Department readiness and authorization. Completing training does not automatically grant approval.'),
                          const SizedBox(height: 8),
                          if (_mine.isEmpty)
                            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('No department qualification roles are configured yet.'))
                          else
                            ..._mine.map((role) => _QualificationTile(role: role)),
                        ],
                      ),
                    ),
                  ),
                  if (_canLookup) ...[
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Who Can Do What', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            const Text('Read-only lookup for Acting Officer and other authorized department roles.'),
                            const SizedBox(height: 10),
                            TextField(
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Medic Driver, Acting Officer, Smith…'),
                              onChanged: (value) => setState(() => _query = value),
                            ),
                            const SizedBox(height: 8),
                            if (filtered.isEmpty)
                              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('No matching qualifications.'))
                            else
                              ...filtered.take(20).map((member) => ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Text([member.rank, member.position].where((v) => v.trim().isNotEmpty).join(' · ')),
                                children: member.qualifications.map((role) => ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.only(left: 16),
                                  title: Text(role.name),
                                  trailing: Text(role.status.replaceAll('_', ' ')),
                                )).toList(),
                              )),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Responder Roadmap records department qualification status. The department remains the authority that approves, restricts, or renews operational authorization.'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _QualificationTile extends StatelessWidget {
  final DepartmentQualificationRole role;
  const _QualificationTile({required this.role});

  @override
  Widget build(BuildContext context) {
    final approved = role.status == 'APPROVED';
    final attention = const {'RESTRICTED', 'RENEWAL_REQUIRED', 'AWAITING_APPROVAL'}.contains(role.status);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Icon(
        approved ? Icons.verified_user_rounded : attention ? Icons.warning_amber_rounded : Icons.pending_actions_outlined,
        color: approved ? Colors.green : attention ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(role.status.replaceAll('_', ' ')),
      childrenPadding: const EdgeInsets.only(bottom: 10),
      children: [
        if (role.description.isNotEmpty) Align(alignment: Alignment.centerLeft, child: Text(role.description)),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            role.requirementsMet ? 'Requirements met' : '${role.missingCount} requirement${role.missingCount == 1 ? '' : 's'} missing',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (role.restriction.isNotEmpty) Align(alignment: Alignment.centerLeft, child: Text('Restriction: ${role.restriction}')),
        if (role.note.isNotEmpty) Align(alignment: Alignment.centerLeft, child: Text('Department note: ${role.note}')),
      ],
    );
  }
}
