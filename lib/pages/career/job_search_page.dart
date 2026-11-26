import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/services/local_store.dart';

class JobSearchPage extends StatefulWidget {
  const JobSearchPage({super.key});

  @override
  State<JobSearchPage> createState() => _JobSearchPageState();
}

class _JobSearchPageState extends State<JobSearchPage> {
  static const _storageKey = 'fireops.jobSearchPreferences.v1';
  static final _feedUri =
      Uri.parse('https://emscodesim.com/jobs/jobs.json');
  static final _boardUri = Uri.parse('https://emscodesim.com/jobs/');

  final _store = LocalStore();
  final _position = TextEditingController();
  final _location = TextEditingController();
  final _minimumPay = TextEditingController();
  final _keywords = TextEditingController();

  String _category = '';
  String _employmentType = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<_ResponderJob> _jobs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _position.dispose();
    _location.dispose();
    _minimumPay.dispose();
    _keywords.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await _store.loadJsonMap(_storageKey);
    if (saved != null) {
      _position.text = saved['position'] as String? ?? '';
      _location.text = saved['location'] as String? ?? '';
      _minimumPay.text = saved['minimumAnnualPay']?.toString() ?? '';
      _keywords.text = saved['keywords'] as String? ?? '';
      _category = saved['category'] as String? ?? '';
      _employmentType = saved['employmentType'] as String? ?? '';
    }
    await _refreshJobs();
  }

  Map<String, dynamic> get _preferences => {
        'position': _position.text.trim(),
        'location': _location.text.trim(),
        'minimumAnnualPay':
            int.tryParse(_minimumPay.text.replaceAll(RegExp(r'[^0-9]'), '')),
        'keywords': _keywords.text.trim(),
        'category': _category,
        'employmentType': _employmentType,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await _store.saveJsonChecked(_storageKey, _preferences);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          saved
              ? 'Job search requirements saved'
              : 'Could not save job search requirements',
        ),
      ),
    );
    if (saved) await _refreshJobs();
  }

  Future<void> _refreshJobs() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await http.get(_feedUri);
      if (response.statusCode != 200) {
        throw Exception('Job feed returned ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final jobs = decoded is List
          ? decoded
              .whereType<Map>()
              .map((item) =>
                  _ResponderJob.fromJson(Map<String, dynamic>.from(item)))
              .where((job) =>
                  job.approved &&
                  job.applyUrl.startsWith('https://') &&
                  (job.closes == null || !job.closes!.isBefore(today)))
              .toList()
          : <_ResponderJob>[];
      jobs.sort((a, b) {
        final aDate = a.closes ?? DateTime(2100);
        final bDate = b.closes ?? DateTime(2100);
        return aDate.compareTo(bDate);
      });
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Verified jobs could not be loaded. Check your connection and try again.';
      });
    }
  }

  List<_ResponderJob> get _matches {
    final position = _position.text.trim().toLowerCase();
    final location = _location.text.trim().toLowerCase();
    final keywords = _keywords.text.trim().toLowerCase();
    final minimumPay =
        int.tryParse(_minimumPay.text.replaceAll(RegExp(r'[^0-9]'), ''));

    return _jobs.where((job) {
      final searchable =
          '${job.title} ${job.employer} ${job.category}'.toLowerCase();
      final place = '${job.city} ${job.state}'.toLowerCase();
      final employment = job.normalizedEmploymentType;

      if (position.isNotEmpty && !searchable.contains(position)) return false;
      if (location.isNotEmpty && !place.contains(location)) return false;
      if (_category.isNotEmpty && job.category != _category) return false;
      if (keywords.isNotEmpty) {
        final combined = '$searchable $place';
        final terms = keywords
            .split(RegExp(r'[, ]+'))
            .where((term) => term.isNotEmpty);
        if (!terms.every(combined.contains)) return false;
      }
      if (_employmentType.isNotEmpty &&
          employment != _employmentType.toLowerCase()) {
        return false;
      }
      if (minimumPay != null && minimumPay > 0) {
        final annual = job.minimumAnnualPay;
        if (annual == null || annual < minimumPay) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _open(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this job link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Job Search'),
        actions: [
          IconButton(
            tooltip: 'Open full job board',
            onPressed: () => _open(_boardUri),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshJobs,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF071A33), Color(0xFF166534)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.travel_explore_rounded,
                      color: Colors.white, size: 32),
                  SizedBox(height: 10),
                  Text(
                    'Your next opportunity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Save your requirements once. Return anytime to see verified fire and EMS jobs that match.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'SEARCH REQUIREMENTS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _position,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Position',
                hintText: 'Paramedic, Firefighter, Captain, Instructor',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Denver, Colorado, or another area',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Service category',
                prefixIcon: Icon(Icons.local_fire_department_outlined),
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('All categories')),
                DropdownMenuItem(value: 'EMT', child: Text('EMT')),
                DropdownMenuItem(value: 'Paramedic', child: Text('Paramedic')),
                DropdownMenuItem(value: 'Fire', child: Text('Fire')),
                DropdownMenuItem(value: 'Leadership', child: Text('Leadership')),
                DropdownMenuItem(value: 'Education', child: Text('Education')),
                DropdownMenuItem(value: 'Dispatch', child: Text('Dispatch')),
              ],
              onChanged: (value) => setState(() => _category = value ?? ''),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _employmentType,
              decoration: const InputDecoration(
                labelText: 'Employment type',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('Any type')),
                DropdownMenuItem(value: 'full-time', child: Text('Full-time')),
                DropdownMenuItem(value: 'part-time', child: Text('Part-time')),
                DropdownMenuItem(value: 'temporary', child: Text('Temporary')),
                DropdownMenuItem(value: 'volunteer', child: Text('Volunteer')),
              ],
              onChanged: (value) =>
                  setState(() => _employmentType = value ?? ''),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minimumPay,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum annual pay',
                hintText: '75000',
                prefixText: r'$ ',
                prefixIcon: Icon(Icons.payments_outlined),
                helperText:
                    'Hourly listings are estimated at 2,080 hours per year.',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keywords,
              decoration: const InputDecoration(
                labelText: 'Other keywords',
                hintText: '911, flight, wildland, training officer',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_rounded),
                label: const Text('Save search requirements'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'MATCHING JOBS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),
                if (!_loading && _error == null)
                  Text(
                    '${matches.length}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _refreshJobs,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (matches.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'No active verified jobs match every saved requirement.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try broadening the position, location, pay, or employment type.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...matches.map(
                (job) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _open(Uri.parse(job.applyUrl)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFDCFCE7),
                                child: Icon(
                                  Icons.work_outline_rounded,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  job.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                              const Icon(Icons.open_in_new_rounded, size: 19),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            job.employer,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [job.city, job.state]
                                .where((part) => part.isNotEmpty)
                                .join(' • '),
                          ),
                          if (job.salary.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              job.salary,
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          if (job.closes != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              'Closes ${job.closes!.month}/${job.closes!.day}/${job.closes!.year}',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _open(_boardUri),
              icon: const Icon(Icons.travel_explore_outlined),
              label: const Text('Open complete Responder Jobs board'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponderJob {
  const _ResponderJob({
    required this.title,
    required this.employer,
    required this.city,
    required this.state,
    required this.category,
    required this.salary,
    required this.applyUrl,
    required this.approved,
    required this.closes,
    required this.employmentType,
  });

  final String title;
  final String employer;
  final String city;
  final String state;
  final String category;
  final String salary;
  final String applyUrl;
  final bool approved;
  final DateTime? closes;
  final String employmentType;

  factory _ResponderJob.fromJson(Map<String, dynamic> json) => _ResponderJob(
        title: json['title'] as String? ?? '',
        employer: json['employer'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        category: json['category'] as String? ?? '',
        salary: json['salary'] as String? ?? '',
        applyUrl: json['applyUrl'] as String? ?? '',
        approved: json['approved'] as bool? ?? false,
        closes: DateTime.tryParse(json['closes'] as String? ?? ''),
        employmentType: json['employmentType'] as String? ?? '',
      );

  String get normalizedEmploymentType {
    final provided = employmentType.trim().toLowerCase();
    if (provided.isNotEmpty) return provided;
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('temporary') || lowerTitle.contains('seasonal')) {
      return 'temporary';
    }
    if (lowerTitle.contains('part-time') || lowerTitle.contains('part time')) {
      return 'part-time';
    }
    if (lowerTitle.contains('volunteer')) return 'volunteer';
    return 'full-time';
  }

  int? get minimumAnnualPay {
    if (salary.trim().isEmpty) return null;
    final values = RegExp(r'[0-9][0-9,]*(?:\.[0-9]+)?')
        .allMatches(salary)
        .map(
          (match) =>
              double.tryParse(match.group(0)!.replaceAll(',', '')),
        )
        .whereType<double>()
        .toList();
    if (values.isEmpty) return null;
    var minimum = values.first;
    final lower = salary.toLowerCase();
    if (lower.contains('hour')) minimum *= 2080;
    return minimum.round();
  }
}
