import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class OnboardingV2Page extends StatefulWidget {
  const OnboardingV2Page({super.key});

  @override
  State<OnboardingV2Page> createState() => _OnboardingV2PageState();
}

class _OnboardingV2PageState extends State<OnboardingV2Page> {
  final PageController _pages = PageController();
  final Set<String> _roles = {};
  final Set<String> _certs = {};
  final TextEditingController _years = TextEditingController();
  final TextEditingController _certSearch = TextEditingController();

  int _step = 0;
  String? _serviceType;
  String? _state;
  String? _goalId;
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void dispose() {
    _pages.dispose();
    _years.dispose();
    _certSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _step == 0
            ? null
            : IconButton(
                tooltip: 'Back',
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
              ),
        title: const Text('Career Setup'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${_step + 1}/3')),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _currentStep(),
                  _certStep(),
                  _goalStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: _saving ? null : _next,
                  child: Text(
                    _saving
                        ? 'Building Task Book…'
                        : _step == 2
                            ? 'Build My Task Book'
                            : 'Continue',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currentStep() {
    final cs = Theme.of(context).colorScheme;
    final commonRoles = FireOpsCatalog.commonRoles
        .where((role) => !role.toLowerCase().contains('custom'))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        Text(
          'Where are you now?',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your current role. This gives Fire Career Roadmap the right starting point.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...commonRoles.map(
              (role) => FilterChip(
                label: Text(role),
                selected: _roles.contains(role),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _roles.add(role);
                  } else {
                    _roles.remove(role);
                  }
                }),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Custom role'),
              onPressed: _addCustomRole,
            ),
          ],
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String?>(
          value: _serviceType,
          decoration: const InputDecoration(labelText: 'Service type'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Not set')),
            DropdownMenuItem(value: 'Volunteer', child: Text('Volunteer')),
            DropdownMenuItem(value: 'Career', child: Text('Career')),
            DropdownMenuItem(value: 'Combination', child: Text('Combination')),
            DropdownMenuItem(value: 'Paid-on-Call', child: Text('Paid-on-Call')),
            DropdownMenuItem(value: 'Seasonal', child: Text('Seasonal')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (value) => setState(() => _serviceType = value),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _state,
                decoration: const InputDecoration(labelText: 'State'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Not set')),
                  ...FireOpsCatalog.usStates.map(
                    (value) => DropdownMenuItem(value: value, child: Text(value)),
                  ),
                ],
                onChanged: (value) => setState(() => _state = value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _years,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Years of service'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _certStep() {
    final cs = Theme.of(context).colorScheme;
    final query = _certSearch.text.trim().toLowerCase();
    final certs = FireOpsCatalog.commonCertifications
        .where((cert) => query.isEmpty || cert.toLowerCase().contains(query))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What do you already have?',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Select current certifications. You can add expiration dates later.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _certSearch,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search certifications',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _addCustomCert,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Custom Certification'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: certs.length,
            itemBuilder: (context, index) {
              final cert = certs[index];
              return Card(
                child: CheckboxListTile(
                  value: _certs.contains(cert),
                  title: Text(cert),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (_) => setState(() {
                    if (_certs.contains(cert)) {
                      _certs.remove(cert);
                    } else {
                      _certs.add(cert);
                    }
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _goalStep() {
    final cs = Theme.of(context).colorScheme;
    final goals = FireOpsCatalog.goals();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        Text(
          'Where do you want to go?',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your next goal. The app will build a Task Book, then let you review and customize it before you use it.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _addCustomGoal,
            icon: const Icon(Icons.add),
            label: const Text('Create Custom Goal'),
          ),
        ),
        const SizedBox(height: 10),
        ...goals.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _goalId == goal.id ? cs.primaryContainer : cs.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(
                onTap: () => setState(() => _goalId = goal.id),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: _goalId == goal.id
                          ? cs.primary.withValues(alpha: 0.45)
                          : cs.outline.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _goalId == goal.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if ((goal.subtitle ?? '').isNotEmpty)
                              Text(
                                goal.subtitle!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _pickTargetDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _targetDate == null
                  ? 'Add Optional Target Date'
                  : 'Target: ${_targetDate!.month}/${_targetDate!.day}/${_targetDate!.year}',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _next() async {
    if (_step == 0 && _roles.isEmpty) {
      _message('Choose at least one current role.');
      return;
    }
    if (_step < 2) {
      await _pages.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      if (mounted) setState(() => _step += 1);
      return;
    }
    if (_goalId == null) {
      _message('Choose a career goal to continue.');
      return;
    }
    await _finish();
  }

  Future<void> _back() async {
    if (_step == 0) return;
    await _pages.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    if (mounted) setState(() => _step -= 1);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final years = int.tryParse(_years.text.trim());
      final profile = UserProfile(
        currentRoles: _roles.toList()..sort(),
        primaryGoalId: _goalId,
        targetDate: null,
        careerPlan: CareerPlan(
          goalId: _goalId,
          startDate: now,
          targetDate: _targetDate,
          timelineEnabled: _targetDate != null,
          timelineStatus: _targetDate == null
              ? TimelineStatus.noTargetDate
              : TimelineStatus.needsAttention,
        ),
        yearsOfService: years,
        serviceType: _serviceType,
        departmentName: null,
        state: _state,
        createdAt: now,
        updatedAt: now,
      );

      final certifications = _certs.map((name) {
        final id = name
            .toLowerCase()
            .replaceAll('–', '-')
            .replaceAll(RegExp(r'[^a-z0-9\- ]'), '')
            .trim()
            .replaceAll(' ', '_');
        return Certification(
          id: id,
          name: name,
          certificationDefinitionId:
              FireOpsCatalog.matchCertificationDefinitionId(name),
          issuingOrganization: null,
          certificationNumber: null,
          issueDate: null,
          expirationDate: null,
          doesNotExpire: false,
          notes: null,
          renewalHistory: const [],
          createdAt: now,
          updatedAt: now,
        );
      }).toList();

      await context.read<AppState>().completeOnboarding(
            profile: profile,
            certifications: certifications,
          );
      if (!mounted) return;
      context.go(AppRoutes.taskBookReview);
    } catch (_) {
      if (mounted) _message('Setup could not be completed. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addCustomRole() async {
    final controller = TextEditingController();
    final value = await _textDialog(
      title: 'Custom role',
      label: 'Role name',
      controller: controller,
    );
    controller.dispose();
    if (value != null && mounted) setState(() => _roles.add(value));
  }

  Future<void> _addCustomCert() async {
    final controller = TextEditingController();
    final value = await _textDialog(
      title: 'Custom certification',
      label: 'Certification name',
      controller: controller,
    );
    controller.dispose();
    if (value != null && mounted) setState(() => _certs.add(value));
  }

  Future<void> _addCustomGoal() async {
    final controller = TextEditingController();
    final value = await _textDialog(
      title: 'Custom career goal',
      label: 'Goal title',
      controller: controller,
    );
    controller.dispose();
    if (value != null && mounted) {
      setState(() => _goalId = 'custom:$value');
    }
  }

  Future<String?> _textDialog({
    required String title,
    required String label,
    required TextEditingController controller,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 15, 12, 31),
    );
    if (picked != null && mounted) setState(() => _targetDate = picked);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
