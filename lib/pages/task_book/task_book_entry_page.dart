import 'package:flutter/material.dart';

import 'package:firepath/pages/path/my_path_page.dart';

/// The My Roadmap tab opens the complete personal growth workspace.
///
/// Keeping the goal plan, progress timeline, and growth tools in one place
/// avoids sending users from a roadmap catalog into a second roadmap screen.
class TaskBookEntryPage extends StatelessWidget {
  const TaskBookEntryPage({super.key});

  @override
  Widget build(BuildContext context) => const MyPathPage();
}
