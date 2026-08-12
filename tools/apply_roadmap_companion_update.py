from pathlib import Path

TASK_DETAIL = Path('lib/pages/task_book/task_detail_page.dart')
TASK_LIBRARY = Path('lib/services/task_book_library.dart')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        print(f'{label}: already applied')
        return text
    if old not in text:
        raise SystemExit(f'{label}: expected anchor not found; refusing partial patch')
    print(f'{label}: applied')
    return text.replace(old, new, 1)


# --- Task detail: external companion actions + working reference links ---
text = TASK_DETAIL.read_text()
text = replace_once(
    text,
    "import 'package:provider/provider.dart';\n\nimport 'package:firepath/models/prefill.dart';",
    "import 'package:provider/provider.dart';\nimport 'package:url_launcher/url_launcher.dart';\n\nimport 'package:firepath/models/prefill.dart';",
    'task detail url_launcher import',
)

text = replace_once(
    text,
    "    final status = state.taskStatusFor(\n        goalId: goalId, requirementId: requirementId, taskId: task.id);\n\n    return Scaffold(",
    "    final status = state.taskStatusFor(\n        goalId: goalId, requirementId: requirementId, taskId: task.id);\n\n    String? certificationDefinitionId;\n    final roadmap = state.roadmap;\n    if (roadmap != null) {\n      for (final item in roadmap.included) {\n        if (item.requirement.id == requirementId) {\n          certificationDefinitionId = item.requirement.certificationDefinitionId;\n          break;\n        }\n      }\n    }\n\n    return Scaffold(",
    'resolve certification id for companion links',
)

text = replace_once(
    text,
    "            _PracticeCard(tools: task.practiceTools),",
    "            _CompanionCard(\n              certificationDefinitionId: certificationDefinitionId,\n              taskId: task.id,\n              stateCode: state.profile.state,\n            ),\n            const SizedBox(height: AppSpacing.md),\n            _PracticeCard(tools: task.practiceTools),",
    'insert companion action card',
)

companion_class = r'''class _CompanionCard extends StatelessWidget {
  final String? certificationDefinitionId;
  final String taskId;
  final String? stateCode;

  const _CompanionCard({
    required this.certificationDefinitionId,
    required this.taskId,
    required this.stateCode,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cert = certificationDefinitionId?.trim();
    final state = stateCode?.trim().toUpperCase();

    final taskQuery = <String, String>{
      'task': taskId,
      'source': 'roadmap',
      if (cert != null && cert.isNotEmpty) 'cert': cert,
      if (state != null && state.isNotEmpty) 'state': state,
    };
    final taskUri = Uri.https(
      'fireopssim.com',
      '/taskbook-resources.html',
      taskQuery,
    );

    final studyUri = cert == null || cert.isEmpty
        ? taskUri
        : Uri.https(
            'fireopssim.com',
            '/study-guides.html',
            {'cert': cert},
          );

    const emsCerts = {
      'emt',
      'aemt',
      'paramedic',
      'bls',
      'acls',
      'pals',
    };
    final finderQuery = <String, String>{
      'path': emsCerts.contains(cert) ? 'ems' : 'fire',
      if (cert != null && cert.isNotEmpty) 'cert': cert,
      if (state != null && state.isNotEmpty) 'state': state,
    };
    final finderUri = Uri.https(
      'fireopssim.com',
      '/school-finder.html',
      finderQuery,
    );

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'FIREOPSSIM COMPANION',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Free study, practice tools, class-finder links, and official sources for this Task Book item.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => _openExternalUrl(studyUri.toString()),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Study this task'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _openExternalUrl(taskUri.toString()),
              icon: const Icon(Icons.fitness_center_outlined),
              label: const Text('Practice / tools'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _openExternalUrl(finderUri.toString()),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Find a class'),
            ),
          ),
        ],
      ),
    );
  }
}

'''
text = replace_once(
    text,
    'class _PracticeCard extends StatelessWidget {',
    companion_class + 'class _PracticeCard extends StatelessWidget {',
    'add companion action widget',
)

text = replace_once(
    text,
    "                  onTap: r.url == null\n                      ? null\n                      : () => context.push(AppRoutes.resources, extra: {\n                          'url': r.url,\n                          'title': r.title,\n                        }),",
    "                  onTap: r.url == null\n                      ? null\n                      : () => _openExternalUrl(r.url!),",
    'open Task Book references directly',
)

helper = r'''Future<void> _openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    debugPrint('Invalid URL: $url');
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) debugPrint('launchUrl failed for $url');
}

'''
text = replace_once(
    text,
    'class TaskDetailPage extends StatelessWidget {',
    helper + 'class TaskDetailPage extends StatelessWidget {',
    'add external URL helper',
)
TASK_DETAIL.write_text(text)


# --- Built-in task library: populate the resources field with stable FireOpsSim links ---
text = TASK_LIBRARY.read_text()
text = replace_once(
    text,
    "    if (defId == 'driver_operator_pumper') return _driverOperatorPumper();\n    final name = r.name.trim().toLowerCase();\n    if (name.contains('driver operator') && name.contains('pumper')) {\n      return _driverOperatorPumper();\n    }",
    "    if (defId == 'driver_operator_pumper') {\n      return _withCompanionResources(\n        _driverOperatorPumper(),\n        certificationId: 'driver_operator_pumper',\n      );\n    }\n    final name = r.name.trim().toLowerCase();\n    if (name.contains('driver operator') && name.contains('pumper')) {\n      return _withCompanionResources(\n        _driverOperatorPumper(),\n        certificationId: 'driver_operator_pumper',\n      );\n    }",
    'attach companion resources to Driver Operator Pumper tasks',
)

resource_helper = r'''  static List<TaskBookTaskDefinition> _withCompanionResources(
    List<TaskBookTaskDefinition> tasks, {
    required String certificationId,
  }) {
    return tasks
        .map(
          (task) => TaskBookTaskDefinition(
            id: task.id,
            title: task.title,
            section: task.section,
            goalId: task.goalId,
            requirementId: task.requirementId,
            isCustom: task.isCustom,
            fireOpsObjective: task.fireOpsObjective,
            whatToKnow: task.whatToKnow,
            performanceTasks: task.performanceTasks,
            safetyPoints: task.safetyPoints,
            commonMistakes: task.commonMistakes,
            practiceTools: task.practiceTools,
            resources: [
              ...task.resources,
              TaskBookResourceLink(
                title: 'FireOpsSim: study, practice, and training help',
                url:
                    'https://fireopssim.com/taskbook-resources.html?cert=$certificationId&task=${task.id}&source=roadmap',
                type: TaskBookTaskResourceType.fireOpsGuide,
                issuingSource: 'FireOpsSim',
                notes:
                    'Free companion study material, practice tools, class finder, and official source links.',
                fileRef: null,
              ),
            ],
          ),
        )
        .toList(growable: false);
  }

'''
text = replace_once(
    text,
    '  static List<TaskBookTaskDefinition> _driverOperatorPumper() {',
    resource_helper + '  static List<TaskBookTaskDefinition> _driverOperatorPumper() {',
    'add companion resource population helper',
)
TASK_LIBRARY.write_text(text)

print('Roadmap companion integration patch complete.')
