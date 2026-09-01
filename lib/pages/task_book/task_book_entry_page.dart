import 'package:flutter/material.dart';

import 'package:firepath/pages/task_book/task_book_page.dart';

/// Entry page for the Task Book tab.
///
/// The first App Store release intentionally presents the personal Task Book
/// experience only. Department Task Book support remains in the codebase for a
/// future release, but it is not exposed from this tab during initial review.
class TaskBookEntryPage extends StatelessWidget {
  const TaskBookEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TaskBookPage();
  }
}
