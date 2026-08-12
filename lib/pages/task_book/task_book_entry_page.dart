import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/path/goal_picker_page.dart';
import 'package:firepath/pages/task_book/task_book_page.dart';
import 'package:firepath/state/app_state.dart';

/// Entry page for the Task Book tab.
///
/// Keeps the legacy behavior: if no goal is selected, we show GoalPicker.
class TaskBookEntryPage extends StatelessWidget {
  const TaskBookEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.roadmap == null) return const GoalPickerPage();
    return const TaskBookPage();
  }
}
