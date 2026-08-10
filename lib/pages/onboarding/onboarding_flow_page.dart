import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final PageController _controller = PageController();
  int _step = 0;

  bool _isFinishing = false;

  final Set<String> _selectedRoles = {};
  final Set<String> _selectedCertNames = {};
  String? _goalId;

  String? _state;
  int? _yearsOfService;
  String? _serviceType;
  DateTime? _goalTargetDate;

  String _certQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0) {
      await _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      await _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
      setState(() => _step = 2);
      return;
    }

    if (_step == 2) {
      await _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
      setState(() => _step = 3);
      return;
    }

    if (_step == 3) {
      if (_isFinishing) return;
      if (_goalId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a career goal to continue.')));
        return;
      }

      setState(() => _isFinishing = true);
      debugPrint('[Onboarding] Finish tapped');
      debugPrint('[Onboarding] Selected goalId=$_goalId');
      debugPrint('[Onboarding] currentRoles=${_selectedRoles.toList()}');
      debugPrint('[Onboarding] serviceType=$_serviceType yearsOfService=$_yearsOfService state=$_state targetDate=$_goalTargetDate');
      debugPrint('[Onboarding] selectedCertCount=${_selectedCertNames.length}');

      try {
        final now = DateTime.now();
        debugPrint('[Onboarding] Building profile + certifications');
        final profile = UserProfile(
          currentRoles: _selectedRoles.toList()..sort(),
          primaryGoalId: _goalId,
          targetDate: null,
          careerPlan: CareerPlan(
            goalId: _goalId,
            startDate: now,
            targetDate: _goalTargetDate,
            timelineEnabled: _goalTargetDate != null,
            timelineStatus: _goalTargetDate == null ? TimelineStatus.noTargetDate : TimelineStatus.needsAttention,
          ),
          yearsOfService: _yearsOfService,
          serviceType: _serviceType,
          departmentName: null,
          state: _state,
          createdAt: now,
          updatedAt: now,
        );

        final certs = _selectedCertNames.map((name) {
          final id = name.toLowerCase().replaceAll('–', '-').replaceAll(RegExp(r'[^a-z0-9\- ]'), '').trim().replaceAll(' ', '_');
          final defId = FireOpsCatalog.matchCertificationDefinitionId(name);
          return Certification(
            id: id,
            name: name,
            certificationDefinitionId: defId,
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

        debugPrint('[Onboarding] Saving onboarding data + onboardingComplete');
        final appState = context.read<AppState>();
        await appState.completeOnboarding(profile: profile, certifications: certs);
        debugPrint('[Onboarding] Onboarding marked complete');

        // Force a roadmap computation now (helps debug if something is missing)
        final roadmap = appState.roadmap;
        debugPrint(
          '[Onboarding] Roadmap computed: goal=${roadmap?.goal.title} completed=${roadmap?.completed.length} missing=${roadmap?.missing.length} percent=${roadmap == null ? 'n/a' : (roadmap.percentComplete * 100).toStringAsFixed(1)} next=${roadmap?.nextStep?.requirement.name}',
        );

        if (!context.mounted) return;
        debugPrint('[Onboarding] Navigating to Home (route replacement)');
        context.go(AppRoutes.home);
      } catch (e, st) {
        debugPrint('[Onboarding] Finish failed: $e');
        debugPrint('$st');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("We couldn't finish setting up your path. Please try again."),
            action: SnackBarAction(label: 'TRY AGAIN', onPressed: () {}),
          ),
        );
        setState(() => _isFinishing = false);
      } finally {
        // Safety: if navigation didn’t happen (or failed), re-enable the button.
        if (mounted && _isFinishing) setState(() => _isFinishing = false);
      }
    }
  }

  Future<void> _back() async {
    if (_step == 0) return;
    await _controller.previousPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
    setState(() => _step -= 1);
  }

  Future<void> _addCustomRole() async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final insets = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: insets.bottom + AppSpacing.lg, top: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Custom Role', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: controller, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Role name')),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
    if (result == null || result.isEmpty) return;
    setState(() => _selectedRoles.add(result));
  }

  Future<void> _addCustomCert() async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final insets = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: insets.bottom + AppSpacing.lg, top: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Custom Certification', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: controller, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Certification name')),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Add')),
            ],
          ),
        );
      },
    );
    if (result == null || result.isEmpty) return;
    setState(() => _selectedCertNames.add(result));
  }

  Future<void> _createCustomGoal() async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final insets = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: insets.bottom + AppSpacing.lg, top: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create Custom Goal', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: controller, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Goal title')),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Save Goal')),
            ],
          ),
        );
      },
    );
    if (result == null || result.isEmpty) return;
    setState(() => _goalId = 'custom:$result');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final finishDisabled = _step == 3 && (_goalId == null || _isFinishing);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.horizontalMd.add(const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm)),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _step == 0 ? null : _back,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text('Setup', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  Text('${_step + 1}/4', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeStep(onPrimary: cs.onPrimary, primary: cs.primary, onNext: _next),
                  _RolesStep(
                    selected: _selectedRoles,
                    onToggle: (role) => setState(() => _selectedRoles.contains(role) ? _selectedRoles.remove(role) : _selectedRoles.add(role)),
                    onAddCustom: _addCustomRole,
                    selectedState: _state,
                    yearsOfService: _yearsOfService,
                    onStateChanged: (v) => setState(() => _state = v),
                    onYearsChanged: (v) => setState(() => _yearsOfService = v),
                    serviceType: _serviceType,
                    onServiceTypeChanged: (v) => setState(() => _serviceType = v),
                  ),
                  _CertsStep(
                    query: _certQuery,
                    onQueryChanged: (v) => setState(() => _certQuery = v),
                    selected: _selectedCertNames,
                    onToggle: (name) => setState(() => _selectedCertNames.contains(name) ? _selectedCertNames.remove(name) : _selectedCertNames.add(name)),
                    onAddCustom: _addCustomCert,
                  ),
                  _GoalStep(
                    goals: FireOpsCatalog.goals(),
                    selectedGoalId: _goalId,
                    onSelect: (id) => setState(() => _goalId = id),
                    onCreateCustomGoal: _createCustomGoal,
                    targetDate: _goalTargetDate,
                    onTargetDateChanged: (d) => setState(() => _goalTargetDate = d),
                  ),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.paddingMd,
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: finishDisabled ? null : _next,
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                  child: Text(
                    _step == 3
                        ? (_isFinishing ? 'SETTING UP YOUR PATH…' : 'Finish')
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
}

class _WelcomeStep extends StatelessWidget {
  final Color primary;
  final Color onPrimary;
  final VoidCallback onNext;

  const _WelcomeStep({required this.primary, required this.onPrimary, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [FireOpsSemanticColors.headerDark, primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FireOps Path', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: onPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "Know where you are.\nKnow where you're going.\nKnow what comes next.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: onPrimary.withValues(alpha: 0.92), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Your Fire Service Career Roadmap', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text('Answer three questions: where you are, where you’re going, and what to do next.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
          const Spacer(),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
              child: const Text('Build My Path'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolesStep extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onAddCustom;
  final String? selectedState;
  final int? yearsOfService;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<int?> onYearsChanged;
  final String? serviceType;
  final ValueChanged<String?> onServiceTypeChanged;

  const _RolesStep({
    required this.selected,
    required this.onToggle,
    required this.onAddCustom,
    required this.selectedState,
    required this.yearsOfService,
    required this.onStateChanged,
    required this.onYearsChanged,
    required this.serviceType,
    required this.onServiceTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = FireOpsCatalog.commonRoles;
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Where are you now?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        Text('Select one or more roles that fit your current position.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: selectedState,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Not set')),
                  ...FireOpsCatalog.usStates.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
                ],
                onChanged: onStateChanged,
                decoration: const InputDecoration(labelText: 'State (optional)'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                initialValue: yearsOfService?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Years of service (optional)'),
                onChanged: (v) => onYearsChanged(int.tryParse(v.trim())),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String?>(
          value: serviceType,
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('Not set')),
            DropdownMenuItem<String?>(value: 'Volunteer', child: Text('Volunteer')),
            DropdownMenuItem<String?>(value: 'Career', child: Text('Career')),
            DropdownMenuItem<String?>(value: 'Combination', child: Text('Combination')),
            DropdownMenuItem<String?>(value: 'Paid-on-Call', child: Text('Paid-on-Call')),
            DropdownMenuItem<String?>(value: 'Seasonal', child: Text('Seasonal')),
            DropdownMenuItem<String?>(value: 'Other', child: Text('Other')),
          ],
          onChanged: onServiceTypeChanged,
          decoration: const InputDecoration(labelText: 'Service type (optional)'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            ...roles.where((r) => r != 'Other / Custom Role').map((role) => _SelectCard(title: role, selected: selected.contains(role), icon: Icons.local_fire_department, onTap: () => onToggle(role))),
            _SelectCard(title: 'Other / Custom', selected: false, icon: Icons.add, onTap: onAddCustom),
            ...selected.where((r) => !roles.contains(r)).map((custom) => _SelectCard(title: custom, selected: true, icon: Icons.badge, onTap: () => onToggle(custom))),
          ],
        ),
        const SizedBox(height: 84),
      ],
    );
  }
}

class _CertsStep extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onAddCustom;

  const _CertsStep({
    required this.query,
    required this.onQueryChanged,
    required this.selected,
    required this.onToggle,
    required this.onAddCustom,
  });

  @override
  Widget build(BuildContext context) {
    final all = FireOpsCatalog.commonCertifications;
    final filtered = query.trim().isEmpty
        ? all
        : all.where((c) => c.toLowerCase().contains(query.trim().toLowerCase())).toList();

    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('My Certifications', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          Text('Pick what you already have. You can add expiration dates later.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search certifications…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => onQueryChanged(''),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: OutlinedButton.icon(
                      onPressed: onAddCustom,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Certification'),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)), minimumSize: const Size.fromHeight(48)),
                    ),
                  );
                }
                final name = filtered[index - 1];
                final isOn = selected.contains(name);
                return Card(
                  child: CheckboxListTile(
                    value: isOn,
                    onChanged: (_) => onToggle(name),
                    title: Text(name),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  final List goals;
  final String? selectedGoalId;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreateCustomGoal;
  final DateTime? targetDate;
  final ValueChanged<DateTime?> onTargetDateChanged;

  const _GoalStep({
    required this.goals,
    required this.selectedGoalId,
    required this.onSelect,
    required this.onCreateCustomGoal,
    required this.targetDate,
    required this.onTargetDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final typedGoals = goals.cast<dynamic>();
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Where do you want to go?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        Text('Choose one primary goal. We’ll show what you need and your next step.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
        const SizedBox(height: AppSpacing.lg),
        ...typedGoals.map((goal) {
          final id = goal.id as String;
          final selected = selectedGoalId == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _SelectRowCard(
              title: goal.title as String,
              subtitle: '${goal.category}${goal.subtitle == null ? '' : ' • ${goal.subtitle}'}',
              icon: Icons.flag,
              selected: selected,
              onTap: () => onSelect(id),
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _SelectRowCard(
            title: 'Create Custom Goal',
            subtitle: 'Add your own target role/path',
            icon: Icons.add,
            selected: selectedGoalId?.startsWith('custom:') ?? false,
            onTap: onCreateCustomGoal,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        Text('WHEN DO YOU WANT TO BE READY?', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.sm),
        _TargetReadyCard(targetDate: targetDate, onChange: onTargetDateChanged),
        const SizedBox(height: 84),
      ],
    );
  }
}

class _TargetReadyCard extends StatelessWidget {
  final DateTime? targetDate;
  final ValueChanged<DateTime?> onChange;
  const _TargetReadyCard({required this.targetDate, required this.onChange});

  static String _fmtMonthYear(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = targetDate == null ? 'No Target Date' : 'Target Ready Date: ${_fmtMonthYear(targetDate!)}';
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Row(
          children: [
            Icon(Icons.event, color: cs.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Career Readiness Goal', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        Widget option({required String title, required String subtitle, required VoidCallback onTap, IconData icon = Icons.flag}) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                child: Row(
                  children: [
                    Icon(icon, color: cs.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        DateTime withinYears(int years) {
          final now = DateTime.now();
          return DateTime(now.year + years, now.month, 1);
        }

        Future<void> chooseDate() async {
          Navigator.of(context).pop();
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: targetDate ?? now.add(const Duration(days: 365)),
            firstDate: DateTime(now.year, now.month, now.day),
            lastDate: DateTime(now.year + 10),
            helpText: 'Target Ready Date',
          );
          if (picked == null) return;
          onChange(DateTime(picked.year, picked.month, 1));
        }

        return Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('WHEN DO YOU WANT TO BE READY?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This is a career readiness target (not a promotion prediction).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.md),
              option(
                title: 'No Target Date',
                subtitle: 'Timeline planning stays optional.',
                icon: Icons.do_not_disturb_on,
                onTap: () {
                  onChange(null);
                  Navigator.of(context).pop();
                },
              ),
              option(
                title: 'Within 1 Year',
                subtitle: 'A focused timeline for near-term readiness.',
                icon: Icons.looks_one,
                onTap: () {
                  onChange(withinYears(1));
                  Navigator.of(context).pop();
                },
              ),
              option(
                title: 'Within 2 Years',
                subtitle: 'A balanced timeline with room for scheduling.',
                icon: Icons.looks_two,
                onTap: () {
                  onChange(withinYears(2));
                  Navigator.of(context).pop();
                },
              ),
              option(
                title: 'Within 3 Years',
                subtitle: 'A longer runway for experience and task books.',
                icon: Icons.looks_3,
                onTap: () {
                  onChange(withinYears(3));
                  Navigator.of(context).pop();
                },
              ),
              option(
                title: 'Choose Date',
                subtitle: 'Pick a specific month/year.',
                icon: Icons.event,
                onTap: chooseDate,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }
}

class _SelectCard extends StatelessWidget {
  final String title;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectCard({required this.title, required this.selected, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primaryContainer : cs.surface;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: (MediaQuery.sizeOf(context).width - AppSpacing.lg * 2 - AppSpacing.md) / 2,
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: selected ? 0.0 : 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SelectRowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SelectRowCard({required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: selected ? 0.0 : 0.16)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (selected ? cs.primary : cs.surfaceVariant).withValues(alpha: selected ? 0.12 : 1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: selected
                  ? Icon(Icons.check_circle, key: const ValueKey('on'), color: cs.primary)
                  : Icon(Icons.circle_outlined, key: const ValueKey('off'), color: cs.outline.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
