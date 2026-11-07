import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';

/// Personal growth is the primary experience; department task books remain
/// accessible from the separate Department workspace.
class TaskBookEntryPage extends StatefulWidget {
  const TaskBookEntryPage({super.key});

  @override
  State<TaskBookEntryPage> createState() => _TaskBookEntryPageState();
}

class _TaskBookEntryPageState extends State<TaskBookEntryPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roadmap = app.roadmap;
    final cs = Theme.of(context).colorScheme;
    final percent = roadmap == null ? 0 : (roadmap.percentComplete * 100).round().clamp(0, 100);
    final completed = roadmap?.completedCount ?? 0;
    final total = roadmap?.totalCount ?? 0;
    final goal = roadmap?.goal.title ?? 'Choose your career goal';

    return Scaffold(
      appBar: AppBar(title: const Text('My Roadmap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Build your future, one milestone at a time.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const Icon(Icons.flag_rounded, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('MY CAREER GOAL', style: Theme.of(context).textTheme.labelSmall),
                    Text(goal, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ])),
                  IconButton(
                    tooltip: 'Edit career goal',
                    onPressed: () => context.push(AppRoutes.goalSetup),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Overall progress'),
                  Text('$percent%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: percent / 100, minHeight: 9,
                    color: Colors.green, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 8),
                Text('$completed of $total requirements complete',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Next Steps')),
              ButtonSegment(value: 1, label: Text('My Path')),
              ButtonSegment(value: 2, label: Text('Completed')),
            ],
            selected: {_tab},
            onSelectionChanged: (selection) => setState(() => _tab = selection.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 16),
          if (_tab == 0) ...[
            Text('Up next', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(roadmap == null ? 'Start your personal roadmap' :
                    roadmap.missing.isEmpty ? 'Your current goal is complete' : 'Keep building toward $goal',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(roadmap == null ? 'Choose a goal to get started.' :
                    roadmap.missing.isEmpty ? 'Explore your next career goal.' :
                    '${roadmap.missing.length} requirements remaining.',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.push(roadmap == null ? AppRoutes.goalSetup : AppRoutes.myPathLegacy),
                  child: Text(roadmap == null ? 'Choose a goal' : 'Continue milestone'),
                ),
              ]),
            )),
          ] else if (_tab == 1) ...[
            Text('My career journey', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (roadmap == null)
              const Card(child: ListTile(title: Text('Your journey starts with a goal')))
            else
              Card(child: Column(children: [
                ExpansionTile(
                  leading: const Icon(Icons.flag_outlined, color: Colors.blue),
                  title: Text(goal),
                  subtitle: Text('$completed of $total requirements complete'),
                  children: [
                    ListTile(
                      title: const Text('Explore requirements and milestones'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.myPathLegacy),
                    ),
                  ],
                ),
              ])),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.goalSetup),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Update my career goal'),
            ),
          ] else ...[
            Text('My completed milestones', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(child: ListTile(
              leading: const Icon(Icons.verified_outlined, color: Colors.green),
              title: const Text('Qualifications and certificates'),
              subtitle: Text(completed == 0 ? 'Your achievements will appear as you progress.' :
                  '$completed requirements completed toward your current goal'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.certifications),
            )),
          ],
        ],
      ),
    );
  }
}
