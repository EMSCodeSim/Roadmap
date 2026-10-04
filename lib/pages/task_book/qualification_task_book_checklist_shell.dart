import 'package:flutter/material.dart';

import 'package:firepath/pages/task_book/qualification_task_book_page.dart'
    as guided;

/// Compatibility wrapper retained for existing routes.
///
/// Certification preparation, national skills/JPR objectives, testing, and
/// credential steps now live in one guided Task Book screen. There is no
/// separate bottom "skills checklist" destination competing with that flow.
class QualificationTaskBookChecklistShell extends StatelessWidget {
  final Object? requirement;

  const QualificationTaskBookChecklistShell({
    super.key,
    required this.requirement,
  });

  @override
  Widget build(BuildContext context) {
    return guided.QualificationTaskBookPage(requirement: requirement);
  }
}
