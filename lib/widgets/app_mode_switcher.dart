import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/state/app_mode_controller.dart';

class AppModeSwitcher extends StatelessWidget {
  const AppModeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppModeController>();
    return Row(
      key: const Key('home_quick_access_row'),
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: mode.isDepartment
                ? OutlinedButton.icon(
                    onPressed: mode.selectPersonal,
                    icon: const Icon(Icons.person_outline_rounded),
                    label: const Text('Personal'),
                  )
                : FilledButton.icon(
                    onPressed: mode.selectPersonal,
                    icon: const Icon(Icons.person_rounded),
                    label: const Text('Personal'),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: mode.isDepartment
                ? FilledButton.icon(
                    onPressed: mode.selectDepartment,
                    icon: const Icon(Icons.apartment_rounded),
                    label: const Text('Department'),
                  )
                : OutlinedButton.icon(
                    onPressed: mode.selectDepartment,
                    icon: const Icon(Icons.apartment_outlined),
                    label: const Text('Department'),
                  ),
          ),
        ),
      ],
    );
  }
}
