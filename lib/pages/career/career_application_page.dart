import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/services/local_store.dart';
import 'package:firepath/state/app_state.dart';

class CareerApplicationPage extends StatefulWidget {
  const CareerApplicationPage({super.key});

  @override
  State<CareerApplicationPage> createState() => _CareerApplicationPageState();
}

class _CareerApplicationPageState extends State<CareerApplicationPage> {
  static const _profileKey = 'fireops.applicationProfile.v1';
  static const _trackerKey = 'fireops.applicationTracker.v1';
  static const _jobHistoryKey = 'fireops.personalJobHistory.v1';

  static const _documentLabels = <String, String>{
    'resume': 'Current resume',
    'coverLetter': 'Base cover letter',
    'diploma': 'High school diploma or GED',
    'transcripts': 'Official transcripts available',
    'licenses': 'Driver and professional licenses',
    'certificates': 'Fire, EMS, and specialty certificates',
    'cpat': 'Current CPAT documentation',
    'birthCertificate': 'Birth certificate available',
    'workAuthorization': 'Work authorization documents',
    'dd214': 'DD214, if applicable',
  };

  final _store = LocalStore();
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _applications = [];
  int _jobHistoryCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _store.loadJsonMap(_profileKey) ?? <String, dynamic>{};
    final tracker = await _store.loadJsonList(_trackerKey);
    final history = await _store.loadJsonList(_jobHistoryKey);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _applications = tracker;
      _jobHistoryCount = history.length;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    _profile['updatedAt'] = DateTime.now().toIso8601String();
    await _store.saveJson(_profileKey, _profile);
  }

  Future<void> _saveApplications() async {
    await _store.saveJson(_trackerKey, _applications);
  }

  int get _readinessPercent {
    const importantFields = [
      'legalName',
      'phone',
      'email',
      'cityState',
      'driverLicense',
      'workAuthorization',
      'highestEducation',
      'school',
      'licenseSummary',
      'professionalReferences',
      'addressHistory',
      'drivingHistory',
    ];
    var complete = importantFields
        .where((key) => (_profile[key]?.toString().trim() ?? '').isNotEmpty)
        .length;
    if (_jobHistoryCount > 0) complete++;
    if (context.read<AppState>().certifications.isNotEmpty) complete++;
    final documents = Map<String, dynamic>.from(
      _profile['documents'] as Map? ?? const <String, dynamic>{},
    );
    if (documents.values.where((value) => value == true).length >= 4) complete++;
    return ((complete / (importantFields.length + 3)) * 100).round();
  }

  Future<void> _editSection(
    String title,
    String description,
    List<_ApplicationField> fields,
  ) async {
    final controllers = {
      for (final field in fields)
        field.key: TextEditingController(
          text: _profile[field.key]?.toString() ?? '',
        ),
    };
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, bottom + 18),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(description),
                  const SizedBox(height: 16),
                  ...fields.map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controllers[field.key],
                        keyboardType: field.keyboardType,
                        minLines: field.multiline ? 3 : 1,
                        maxLines: field.multiline ? 6 : 1,
                        decoration: InputDecoration(
                          labelText: field.label,
                          hintText: field.hint,
                          alignLabelWithHint: field.multiline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save application profile'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (saved == true) {
      setState(() {
        for (final field in fields) {
          _profile[field.key] = controllers[field.key]!.text.trim();
        }
      });
      await _saveProfile();
    }
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> _editDocuments() async {
    final documents = Map<String, dynamic>.from(
      _profile['documents'] as Map? ?? const <String, dynamic>{},
    );
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'Document readiness',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(6, 5, 6, 10),
                    child: Text(
                      'Mark documents you can quickly provide. This checklist does not upload or store the documents.',
                    ),
                  ),
                  ..._documentLabels.entries.map(
                    (entry) => CheckboxListTile(
                      value: documents[entry.key] == true,
                      title: Text(entry.value),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) => setSheetState(
                        () => documents[entry.key] = value == true,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, documents),
                    child: const Text('Save document checklist'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    setState(() => _profile['documents'] = result);
    await _saveProfile();
  }

  Future<void> _editApplication([Map<String, dynamic>? existing]) async {
    final department = TextEditingController(text: existing?['department'] as String? ?? '');
    final position = TextEditingController(text: existing?['position'] as String? ?? '');
    final deadline = TextEditingController(text: existing?['deadline'] as String? ?? '');
    final contact = TextEditingController(text: existing?['contact'] as String? ?? '');
    final notes = TextEditingController(text: existing?['notes'] as String? ?? '');
    var status = existing?['status'] as String? ?? 'Interested';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottom = MediaQuery.viewInsetsOf(context).bottom;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, bottom + 18),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'Track an application' : 'Update application',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: department, decoration: const InputDecoration(labelText: 'Department or agency')),
                    const SizedBox(height: 12),
                    TextField(controller: position, decoration: const InputDecoration(labelText: 'Position')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Hiring stage'),
                      items: const [
                        'Interested',
                        'Preparing',
                        'Applied',
                        'Testing',
                        'Interview',
                        'Background',
                        'Conditional offer',
                        'Hired',
                        'Closed',
                      ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) => setSheetState(() => status = value ?? status),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: deadline, decoration: const InputDecoration(labelText: 'Next deadline or date', hintText: 'MM/DD/YYYY — written test')),
                    const SizedBox(height: 12),
                    TextField(controller: contact, decoration: const InputDecoration(labelText: 'Contact or confirmation number')),
                    const SizedBox(height: 12),
                    TextField(controller: notes, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Notes', alignLabelWithHint: true)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Save application'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (saved == true && department.text.trim().isNotEmpty) {
      final row = <String, dynamic>{
        'id': existing?['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
        'department': department.text.trim(),
        'position': position.text.trim(),
        'status': status,
        'deadline': deadline.text.trim(),
        'contact': contact.text.trim(),
        'notes': notes.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      setState(() {
        final index = _applications.indexWhere((item) => item['id'] == row['id']);
        if (index < 0) {
          _applications.insert(0, row);
        } else {
          _applications[index] = row;
        }
      });
      await _saveApplications();
    }
    department.dispose();
    position.dispose();
    deadline.dispose();
    contact.dispose();
    notes.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final documents = Map<String, dynamic>.from(
      _profile['documents'] as Map? ?? const <String, dynamic>{},
    );
    final readyDocuments = documents.values.where((value) => value == true).length;
    final readiness = _readinessPercent;

    return Scaffold(
      appBar: AppBar(title: const Text('Application Center')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF071A33), Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                const Text(
                  'Be ready when the right job opens',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Keep the details large departments frequently request organized, current, and ready to reuse.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: readiness / 100,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                        backgroundColor: Colors.white24,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$readiness%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Application profile',
            subtitle: 'Save reusable facts once. Always verify them before submitting an official application.',
          ),
          const SizedBox(height: 8),
          _ProfileTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal information & eligibility',
            complete: _hasValues(['legalName', 'phone', 'email', 'cityState', 'driverLicense', 'workAuthorization']),
            onTap: () => _editSection(
              'Personal information & eligibility',
              'Do not enter a Social Security number, banking information, or identity-document numbers here.',
              const [
                _ApplicationField('legalName', 'Full legal name'),
                _ApplicationField('previousNames', 'Previous names, if applicable'),
                _ApplicationField('phone', 'Phone', keyboardType: TextInputType.phone),
                _ApplicationField('email', 'Email', keyboardType: TextInputType.emailAddress),
                _ApplicationField('cityState', 'Current city and state'),
                _ApplicationField('driverLicense', 'Driver license state and class', hint: 'Colorado — Class R'),
                _ApplicationField('workAuthorization', 'Authorized to work in the U.S.?', hint: 'Yes / No'),
                _ApplicationField('relocation', 'Residency or relocation notes'),
              ],
            ),
          ),
          _ProfileTile(
            icon: Icons.school_outlined,
            title: 'Education & training',
            complete: _hasValues(['highestEducation', 'school']),
            onTap: () => _editSection(
              'Education & training',
              'Record the information you regularly need when applications ask for education and academy history.',
              const [
                _ApplicationField('highestEducation', 'Highest education completed'),
                _ApplicationField('school', 'School or institution'),
                _ApplicationField('graduationYear', 'Graduation year'),
                _ApplicationField('academyHistory', 'Fire/EMS academy history', multiline: true),
                _ApplicationField('specialTraining', 'Specialized training summary', multiline: true),
              ],
            ),
          ),
          _ProfileTile(
            icon: Icons.local_fire_department_outlined,
            title: 'Licenses, certifications & testing',
            detail: '${app.certifications.length} credentials already tracked',
            complete: app.certifications.isNotEmpty && _hasValues(['licenseSummary']),
            onTap: () => _editSection(
              'Licenses, certifications & testing',
              'Responder Roadmap already tracks credentials. Add application-specific license and testing details here.',
              const [
                _ApplicationField('licenseSummary', 'EMT/paramedic or professional license details', multiline: true),
                _ApplicationField('cpatStatus', 'CPAT date and expiration'),
                _ApplicationField('writtenScores', 'Written-test scores or eligibility lists', multiline: true),
                _ApplicationField('specialQualifications', 'Apparatus, wildland, instructor, or specialty qualifications', multiline: true),
              ],
            ),
          ),
          _ProfileTile(
            icon: Icons.fact_check_outlined,
            title: 'Background preparation',
            complete: _hasValues(['addressHistory', 'drivingHistory']),
            onTap: () => _editSection(
              'Background preparation',
              'Use this as a truthful preparation aid. Enter complete disclosures only into the department’s secure official system.',
              const [
                _ApplicationField('addressHistory', 'Address-history readiness', hint: 'Example: Complete for the past 10 years'),
                _ApplicationField('drivingHistory', 'Driving-history readiness', hint: 'States licensed in; records collected'),
                _ApplicationField('employmentDisclosures', 'Employment discipline or separation notes', multiline: true),
                _ApplicationField('priorApplications', 'Previous public-safety applications', multiline: true),
                _ApplicationField('militaryService', 'Military service and DD214 notes', multiline: true),
                _ApplicationField('backgroundNotes', 'Other items to verify before a background packet', multiline: true),
              ],
            ),
          ),
          _ProfileTile(
            icon: Icons.groups_outlined,
            title: 'References',
            complete: _hasValues(['professionalReferences']),
            onTap: () => _editSection(
              'References',
              'Keep references current and ask permission before listing someone on an application.',
              const [
                _ApplicationField('professionalReferences', 'Professional references', hint: 'Name — role — phone — email — relationship', multiline: true),
                _ApplicationField('personalReferences', 'Personal references', multiline: true),
                _ApplicationField('supervisorContacts', 'Past supervisor contacts', multiline: true),
                _ApplicationField('referenceVerified', 'Last date references were verified'),
              ],
            ),
          ),
          _ProfileTile(
            icon: Icons.folder_copy_outlined,
            title: 'Document readiness',
            detail: '$readyDocuments of ${_documentLabels.length} marked ready',
            complete: readyDocuments >= 4,
            onTap: _editDocuments,
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Connected career information',
            subtitle: 'Use the information Roadmap already keeps instead of rebuilding it for every opportunity.',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.work_history_outlined,
                  title: 'Job history',
                  detail: '$_jobHistoryCount roles',
                  onTap: () async {
                    await context.push(AppRoutes.jobHistory);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionCard(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Credentials',
                  detail: '${app.certifications.length} tracked',
                  onTap: () => context.push(AppRoutes.certifications),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.travel_explore_rounded,
                  title: 'Saved search',
                  detail: 'Find matching jobs',
                  onTap: () => context.push(AppRoutes.jobSearch),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionCard(
                  icon: Icons.description_outlined,
                  title: 'Career export',
                  detail: 'Prepare your records',
                  onTap: () => context.push(AppRoutes.careerExport),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _SectionHeader(title: 'Application tracker', subtitle: 'Keep deadlines and hiring stages from getting lost.')),
              IconButton.filled(
                tooltip: 'Track an application',
                onPressed: _editApplication,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_applications.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.route_outlined, size: 38, color: cs.primary),
                    const SizedBox(height: 8),
                    const Text('No applications tracked yet', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    const Text('Add a department when you become interested, then follow it through hiring.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(onPressed: _editApplication, icon: const Icon(Icons.add_rounded), label: const Text('Track an application')),
                  ],
                ),
              ),
            )
          else
            ..._applications.map(
              (application) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.apartment_rounded, color: cs.onPrimaryContainer),
                  ),
                  title: Text(application['department'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text([
                    application['position'],
                    application['status'],
                    if ((application['deadline'] as String? ?? '').isNotEmpty) application['deadline'],
                  ].whereType<String>().where((value) => value.isNotEmpty).join(' · ')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editApplication(application),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
            child: const ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('Keep sensitive details in official systems'),
              subtitle: Text('Do not store Social Security numbers, banking data, medical records, passwords, or identity-document numbers in Roadmap.'),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValues(List<String> keys) =>
      keys.every((key) => (_profile[key]?.toString().trim() ?? '').isNotEmpty);
}

class _ApplicationField {
  const _ApplicationField(
    this.key,
    this.label, {
    this.hint,
    this.multiline = false,
    this.keyboardType,
  });

  final String key;
  final String label;
  final String? hint;
  final bool multiline;
  final TextInputType? keyboardType;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35)),
        ],
      );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, required this.complete, required this.onTap, this.detail});
  final IconData icon;
  final String title;
  final String? detail;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(detail ?? (complete ? 'Ready to review' : 'Information still needed')),
          trailing: Icon(complete ? Icons.check_circle_rounded : Icons.chevron_right_rounded, color: complete ? Colors.green.shade700 : null),
          onTap: onTap,
        ),
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.detail, required this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(detail, maxLines: 2),
              ],
            ),
          ),
        ),
      );
}
