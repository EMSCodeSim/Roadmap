import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/department/my_department_page.dart';
import 'package:firepath/pages/task_book/task_book_page.dart';
import 'package:firepath/state/app_mode_controller.dart';

/// Entry page for the Task Book tab.
///
class TaskBookEntryPage extends StatelessWidget {
  const TaskBookEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppModeController>();
    return mode.isDepartment
        ? const MyDepartmentPage(taskBooksOnly: true)
        : const TaskBookPage();
  }
}
