import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/path/goal_picker_page.dart';
import 'package:firepath/pages/path/my_path_page.dart';
import 'package:firepath/state/app_state.dart';

class RoadmapEntryPage extends StatelessWidget {
  const RoadmapEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.roadmap == null) {
      return const GoalPickerPage();
    }
    return const MyPathPage();
  }
}
