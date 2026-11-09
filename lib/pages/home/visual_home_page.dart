import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/widgets/firefighter_roadmap_wordmark.dart';

/// A personal-first home. Department workflows remain in the Department tab.
class VisualHomePage extends StatefulWidget {
  const VisualHomePage({super.key});

  @override
  State<VisualHomePage> createState() => _VisualHomePageState();
}

class _VisualHomePageState extends State<VisualHomePage> {
  static const _preferenceKey = 'personal_home_expanded_v1';
  final Set<String> _expanded = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _expanded.addAll(prefs.getStringList(_preferenceKey) ?? const []);
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _toggle(String key) async {
    setState(() {
      if (!_expanded.add(key)) _expanded.remove(key);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_preferenceKey, _expanded.toList());
    } catch (_) {
      // Expansion remains usable if local persistence is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roadmap = app.roadmap;
    final theme = Theme.of(context);
    final departmentName = (app.profile.departmentName ?? '').trim();
    final percent = roadmap == null
        ? null
        : (roadmap.percentComplete * 100).round().clamp(0, 100);

    return Scaffold(
      appBar: AppBar(
        title: FirefighterRoadmapWordmark(
          iconSize: 24,
          textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings and profile',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text('My Roadmap', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Your journey. Your progress.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.spa_outlined, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text('My growth', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                      Text(percent == null ? 'Not started' : '$percent%', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: percent == null ? 0 : percent / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    Text(roadmap?.goal.title ?? 'Choose your first career goal', maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.myPath),
                      child: Text(roadmap == null ? 'Start my roadmap' : 'Continue my roadmap'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _GrowthTile(
              title: 'My Progress',
              subtitle: 'Your personal growth',
              icon: Icons.trending_up_rounded,
              color: Colors.blue,
              expanded: _loaded && _expanded.contains('progress'),
              onToggle: () => _toggle('progress'),
              details: roadmap == null
                  ? 'Start a roadmap to see your progress.'
                  : '${roadmap.completedCount} of ${roadmap.totalCount} requirements completed',
              onOpen: () => context.go(AppRoutes.myPath),
            ),
            _GrowthTile(
              title: 'My Goals',
              subtitle: 'What I am working toward',
              icon: Icons.track_changes_rounded,
              color: Colors.deepPurple,
              expanded: _loaded && _expanded.contains('goals'),
              onToggle: () => _toggle('goals'),
              details: roadmap?.goal.title ?? 'Set your next career goal.',
              onOpen: () => context.go(AppRoutes.myPath),
            ),
            _GrowthTile(
              title: 'My Learning',
              subtitle: 'Keep building your skills',
              icon: Icons.menu_book_rounded,
              color: Colors.teal,
              expanded: _loaded && _expanded.contains('learning'),
              onToggle: () => _toggle('learning'),
              details: 'Review your personal training and activity history.',
              // Use push() so a user can always get back to Home with the back button.
              onOpen: () => context.push(AppRoutes.personalLog),
            ),
            _GrowthTile(
              title: 'My Achievements',
              subtitle: 'Qualifications and milestones',
              icon: Icons.workspace_premium_rounded,
              color: Colors.deepOrange,
              expanded: _loaded && _expanded.contains('achievements'),
              onToggle: () => _toggle('achievements'),
              details: 'View your qualifications and certificates.',
              onOpen: () => context.go(AppRoutes.certifications),
            ),
            if (departmentName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.apartment_rounded),
                  title: const Text('Department'),
                  subtitle: const Text('Updates and department workspace'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.department),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GrowthTile extends StatelessWidget {
  const _GrowthTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.expanded,
    required this.onToggle,
    required this.details,
    required this.onOpen,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool expanded;
  final VoidCallback onToggle;
  final String details;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          ListTile(
            onTap: onToggle,
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(details),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: onOpen, child: Text('Open $title')),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
