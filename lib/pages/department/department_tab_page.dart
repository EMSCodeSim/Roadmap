import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/department/department_training_home_page.dart';
import 'package:firepath/pages/department/my_department_page.dart';
import 'package:firepath/state/app_mode_controller.dart';

/// One focused department tab for the responder.
///
/// If the app is not connected to a department, show the existing connect/join
/// flow. Once connected, show only the user's department obligations and
/// review work that is specifically assigned to them.
class DepartmentTabPage extends StatelessWidget {
  const DepartmentTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppModeController>();
    if (mode.departmentLink == null) return const MyDepartmentPage();
    return const DepartmentTrainingHomePage();
  }
}
