import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/pages/profile/us_state_picker_sheet.dart';
import 'package:firepath/widgets/role_toggle_chip.dart';

class OnboardingV2Page extends StatefulWidget {
  const OnboardingV2Page({super.key});

  @override
  State<OnboardingV2Page> createState() => _OnboardingV2PageState();
}

class OnboardingHero extends StatelessWidget {
  const OnboardingHero({
    super.key,
    required this.headline,
    required this.supporting,
    required this.progressValue,
    this.progressLabel,
  });

  final String headline;
  final String supporting;
  final double progressValue;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer.withValues(alpha: 0.85),
            cs.secondaryContainer.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                ),
                child: Icon(Icons.local_fire_department, color: cs.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  headline,
                  style: t.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            supporting,
            style: t.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0, 1),
              minHeight: 9,
              backgroundColor: cs.surface.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.bolt, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  progressLabel ?? 'Step 1 takes under a minute for most users.',
                  style: t.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingBullet {
  const OnboardingBullet({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;
}

class OnboardingWhyThisMattersCard extends StatelessWidget {
  const OnboardingWhyThisMattersCard({
    super.key,
    required this.title,
    required this.bullets,
    required this.footer,
  });

  final String title;
  final List<OnboardingBullet> bullets;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline, color: cs.onSecondaryContainer),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: cs.outline.withValues(alpha: 0.12)),
                      ),
                      child: Icon(b.icon, color: cs.onSurfaceVariant, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.title,
                            style: t.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.detail,
                            style: t.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 20, color: cs.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      footer,
                      style: t.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TightBulletRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _TightBulletRow({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
          ),
          child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 1),
              Text(detail, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingSectionHeader extends StatelessWidget {
  const _OnboardingSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
        ),
      ],
    );
  }
}

class _OnboardingV2PageState extends State<OnboardingV2Page> {
  final PageController _pages = PageController();
  final Set<String> _roles = {};
  final Set<String> _certs = {};
  final TextEditingController _years = TextEditingController();
  final TextEditingController _certSearch = TextEditingController();

  int _step = 0;
  static const int _totalSteps = 4;
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: _step == 0
            ? null
            : IconButton(
                tooltip: 'Back',
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(
          switch (_step) {
            0 => 'Welcome',
            1 => 'Career Setup',
            2 => 'Certifications',
            _ => 'Career Goal',
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Step ${_step + 1} of $_totalSteps',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
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
                children: [_instructionsStep(), _currentSituationStep(), _certStep(), _goalStep()],
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
                        ? 'Building your path…'
                        : _step == 3
                        ? 'Build my Task Book'
                        : _step == 0
                        ? 'Continue — Build My Path'
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

  Widget _instructionsStep() {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHero(
              headline: 'Your path. Built fast.',
              supporting:
                  'A 60-second setup to generate your FireOps Career Road + Task Book—based on your role, state, and current certs.',
              progressValue: 1 / _totalSteps,
              progressLabel: 'Step 1 of $_totalSteps · About 1 minute',
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In this quick setup, you’ll get:',
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    _TightBulletRow(
                      icon: Icons.check_circle_outline,
                      title: 'A staged plan to Next Level',
                      detail: 'Prereqs → certs → training → hours → sign-offs → promo prep.',
                    ),
                    const SizedBox(height: 10),
                    _TightBulletRow(
                      icon: Icons.bolt,
                      title: 'Fast “make progress” logging',
                      detail: 'Quick Logs suggested from what you actually need next.',
                    ),
                    const SizedBox(height: 10),
                    _TightBulletRow(
                      icon: Icons.public,
                      title: 'State-aware links & labels',
                      detail: 'Clear “Required in [State]” vs “Common recommendation”.',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You can change anything later—role, state, certs, and department requirements.',
                      style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next up: pick your current level / role.',
                      style: t.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return SingleChildScrollView(
          // Tight scroll region (only engages on small devices).
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
            child: content,
          ),
        );
      },
    );
  }

  Widget _currentSituationStep() {
    final cs = Theme.of(context).colorScheme;
    final commonRoles = FireOpsCatalog.commonRoles
        .where((role) => !role.toLowerCase().contains('custom'))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        OnboardingHero(
          headline: 'Where are you starting from?',
          supporting:
              'This sets the right starting point, state resources, and what counts as “next up.”',
          progressValue: 2 / _totalSteps,
        ),
        const SizedBox(height: 14),
        _OnboardingSectionHeader(
          title: 'Your current level',
          subtitle: 'Quick setup. You can change anything later.',
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current role(s)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick one or more. This drives your roadmap + suggested Quick Logs.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...commonRoles.map(
                      (role) => RoleToggleChip(
                        label: role,
                        selected: _roles.contains(role),
                        onPressed: () => setState(() {
                          if (_roles.contains(role)) {
                            _roles.remove(role);
                          } else {
                            _roles.add(role);
                          }
                        }),
                      ),
                    ),
                    RoleToggleChip(
                      label: 'Add role',
                      selected: false,
                      leading: Icons.add,
                      onPressed: _addCustomRole,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _serviceType,
                  decoration: const InputDecoration(
                    labelText: 'Service type',
                    hintText: 'Volunteer, Career, Combination…',
                  ),
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
                      child: _StateSelectorField(
                        code: _state,
                        onTap: () async {
                          final picked = await UsStatePickerSheet.pick(
                            context,
                            selectedCode: _state,
                          );
                          if (picked == null) return;
                          setState(() => _state = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _years,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Years of service',
                          hintText: '0+',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the certs you already hold. Add expiration dates later.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _certSearch,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search certs',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _addCustomCert,
                  icon: const Icon(Icons.add),
                  label: const Text('Add custom cert'),
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
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your Next Level. FireOps Career Road will build your starting Task Book. You can add department requirements later.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _addCustomGoal,
            icon: const Icon(Icons.add),
            label: const Text('Add custom goal'),
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if ((goal.subtitle ?? '').isNotEmpty)
                              Text(
                                goal.subtitle!,
                                style: Theme.of(context).textTheme.bodySmall
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
    if (_step == 1 && _roles.isEmpty) {
      _message('Choose at least one current role.');
      return;
    }
    if (_step == 1 && !_isStateValidForSetup()) {
      _message('Select your state to continue.');
      return;
    }
    if (_step < _totalSteps - 1) {
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

  bool _isStateValidForSetup() {
    if (_state == null || _state!.trim().isEmpty) return false;
    if (_state == FireOpsCatalog.otherStateCode) return true;
    return FireOpsCatalog.usStateOptions.any((e) => e.code == _state);
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
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) dialogContext.pop(value);
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

class _StateSelectorField extends StatelessWidget {
  final String? code;
  final VoidCallback onTap;
  const _StateSelectorField({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = FireOpsCatalog.stateNameForCode(code);
    final label = name ?? 'Select state';

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Icon(Icons.public, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'State',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Icon(Icons.expand_more, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
