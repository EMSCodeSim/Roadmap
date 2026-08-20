import 'package:flutter/material.dart';
import 'package:firepath/pages/task_book/task_book_page.dart';

/// Entry page for the Task Book tab.
///
/// Keeps the legacy behavior: if no goal is selected, we show GoalPicker.
class TaskBookEntryPage extends StatelessWidget {
  const TaskBookEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We keep the legacy behavior (prompt for a goal) inside TaskBookPage's
    // empty-state, but we always enter the Task Book tab so custom Task Books
    // are accessible even before a Career Road goal is selected.
    return const TaskBookPage();
  }
}
