import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/career/growth_overview_page.dart';
import 'package:firepath/pages/department/department_review_page.dart';
import 'package:firepath/pages/department/department_classes_page.dart';
import 'package:firepath/pages/department/my_department_page.dart';
import 'package:firepath/state/app_mode_controller.dart';

class ModeAwareAdvancePage extends StatelessWidget {
  const ModeAwareAdvancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppModeController>();
    if (!mode.isDepartment) return const GrowthOverviewPage();
    if (mode.isInstructor) return const DepartmentClassesPage();
    if (mode.isEvaluator || mode.isAdmin) return const DepartmentReviewPage();
    return const MyDepartmentPage();
  }
}
