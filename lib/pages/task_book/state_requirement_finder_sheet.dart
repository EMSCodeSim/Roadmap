import 'package:flutter/material.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/state_fire_authority_catalog.dart';
import 'package:url_launcher/url_launcher.dart';

Future<Requirement?> showStateRequirementFinderSheet(
  BuildContext context, {
  required String requirementScopeId,
  required int currentCount,
  required String? currentStateCode,
}) {
  return showModalBottomSheet<Requirement>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _StateRequirementFinderSheet(
      requirementScopeId: requirementScopeId,
      currentCount: currentCount,
      currentStateCode: currentStateCode,
    ),
  );
}

enum _StateRequirementArea { fire, ems }

class _StateRequirementFinderSheet extends StatefulWidget {
  final String requirementScopeId;
  final int currentCount;
  final String? currentStateCode;

  const _StateRequirementFinderSheet({
    required this.requirementScopeId,
    required this.currentCount,
    required this.currentStateCode,
  });

  @override
  State<_StateRequirementFinderSheet> createState() =>
      _StateRequirementFinderSheetState();
}

class _StateRequirementFinderSheetState
    extends State<_StateRequirementFinderSheet> {
  String? _stateCode;
  _StateRequirementArea _area = _StateRequirementArea.fire;
  RequirementType _type = RequirementType.certification;
  late final TextEditingController _name;
  late final TextEditingController _details;
  late final TextEditingController _sourceTitle;
  late final TextEditingController _sourceUrl;

  @override
  void initState() {
    super.initState();
    final validStates = FireOpsCatalog.usStateOptions
        .where((item) => item.code != FireOpsCatalog.otherStateCode)
        .map((item) => item.code)
        .toSet();
    final profileState = FireOpsCatalog.stateCodeFromLegacyValue(
      widget.currentStateCode,
    );
    _stateCode = profileState != null && validStates.contains(profileState)
        ? profileState
        : null;
    _name = TextEditingController();
    _details = TextEditingController();
    _sourceTitle = TextEditingController();
    _sourceUrl = TextEditingController();
    _syncSource();
  }

  @override
  void dispose() {
    _name.dispose();
    _details.dispose();
    _sourceTitle.dispose();
    _sourceUrl.dispose();
    super.dispose();
  }

  String get _sourceLink {
    final stateCode = _stateCode;
    if (stateCode == null) return '';
    if (_area == _StateRequirementArea.fire) {
      return StateFireAuthorityCatalog.forState(stateCode)?.sourceUrl ?? '';
    }
    return 'https://www.nremt.org/maps';
  }

  String get _sourceLabel {
    if (_area == _StateRequirementArea.fire) {
      final stateCode = _stateCode;
      if (stateCode == null) return 'Choose a state';
      return StateFireAuthorityCatalog.forState(stateCode)?.sourceTitle ??
          'State fire training authority';
    }
    return 'National Registry State EMS Office Map';
  }

  void _syncSource() {
    _sourceTitle.text = _sourceLabel;
    _sourceUrl.text = _sourceLink;
  }

  Future<void> _openSource() async {
    final uri = Uri.tryParse(_sourceLink);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the authority resource.')),
      );
    }
  }

  void _save() {
    final name = _name.text.trim();
    final title = _sourceTitle.text.trim();
    final url = _sourceUrl.text.trim();
    final stateCode = _stateCode;
    final uri = Uri.tryParse(url);
    if (stateCode == null || name.isEmpty || title.isEmpty || uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a requirement name and a valid source link.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final stateName = FireOpsCatalog.stateNameForCode(stateCode) ?? stateCode;
    final requirement = Requirement(
      id: '${widget.requirementScopeId}::state_${now.microsecondsSinceEpoch}',
      name: name,
      category: 'State — ' + stateName,
      priority: RequirementPriority.state,
      description: _details.text.trim().isEmpty
          ? 'Personal planning item added from a state resource. Confirm the current rule and whether it applies to your role.'
          : _details.text.trim(),
      type: _type,
      requirementSource: RequirementSource.stateRequirement,
      defaultRequired: true,
      stateDependent: true,
      departmentDependent: false,
      completed: false,
      progressCurrent: null,
      progressRequired: null,
      progressUnit: null,
      experienceValue: null,
      experienceUnit: null,
      certificationReference: _type == RequirementType.certification ? name : null,
      certificationDefinitionId: _type == RequirementType.certification
          ? FireOpsCatalog.matchCertificationDefinitionId(name)
          : null,
      allowExpiredCertification: false,
      prerequisiteRequirementIds: const [],
      resourceIds: const [],
      resourceLinks: [ResourceLink(title: title, url: url)],
      sortOrder: widget.currentCount + 1,
      sourceStateCode: stateCode,
      sourceTitle: title,
      sourceUrl: url,
      sourceNotes:
          'User-added source. Responder Roadmap has not verified this rule or its applicability.',
      estimatedDurationDays: null,
      recommendedLeadTimeDays: null,
      canRunConcurrent: true,
      timelineCategory: TimelineCategory.development,
      suggestedStartDate: null,
      suggestedCompletionDate: null,
      createdAt: now,
      updatedAt: now,
    );
    Navigator.of(context).pop(requirement);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authority = _area == _StateRequirementArea.fire && _stateCode != null
        ? StateFireAuthorityCatalog.forState(_stateCode!)
        : null;
    final validStates = FireOpsCatalog.usStateOptions
        .where((item) => item.code != FireOpsCatalog.otherStateCode)
        .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Find State Requirements',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Check the official source for your state, then add the item that applies to your career goal. Roadmap does not determine whether a rule applies to your job or department.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _stateCode,
              hint: const Text('Choose a state'),
              decoration: const InputDecoration(labelText: 'State'),
              items: validStates
                  .map((item) => DropdownMenuItem(
                        value: item.code,
                        child: Text(item.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _stateCode = value;
                  _syncSource();
                });
              },
            ),
            const SizedBox(height: 8),
            SegmentedButton<_StateRequirementArea>(
              segments: const [
                ButtonSegment(
                  value: _StateRequirementArea.fire,
                  label: Text('Fire'),
                  icon: Icon(Icons.local_fire_department_outlined),
                ),
                ButtonSegment(
                  value: _StateRequirementArea.ems,
                  label: Text('EMS'),
                  icon: Icon(Icons.medical_services_outlined),
                ),
              ],
              selected: {_area},
              onSelectionChanged: (value) {
                setState(() {
                  _area = value.first;
                  _syncSource();
                });
              },
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authority?.sourceTitle ?? _sourceLabel,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stateCode == null
                        ? 'Select your state to open its fire authority or the EMS office directory.'
                        : _area == _StateRequirementArea.fire
                            ? authority?.guidance ??
                                'Use your state fire training authority and confirm any department-specific requirement.'
                            : 'Use the state EMS office map to find your state licensing authority. Check licensure, renewal, education, scope, and reciprocity rules.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _sourceLink.isEmpty ? null : _openSource,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open source directory'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Look for certification level, prerequisites, renewal or continuing education, reciprocity, and role-specific requirements.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Requirement to add',
                      hintText: 'Example: Colorado EMT certification',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<RequirementType>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Requirement type'),
                    items: const [
                      DropdownMenuItem(
                        value: RequirementType.certification,
                        child: Text('Certification or license'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.trainingCourse,
                        child: Text('Training or course'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.experience,
                        child: Text('Experience'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.numericProgress,
                        child: Text('Hours or repetitions'),
                      ),
                      DropdownMenuItem(
                        value: RequirementType.custom,
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _details,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Add the exact level, renewal cycle, or rule you found.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _sourceTitle,
                    decoration: const InputDecoration(labelText: 'Source name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _sourceUrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'State requirement page URL',
                      hintText: 'Paste the exact state page you checked.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved as a state-sourced item for your personal book. It will be marked “verify” because Roadmap has not independently validated it.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.playlist_add),
                label: const Text('Add to Personal Task Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
