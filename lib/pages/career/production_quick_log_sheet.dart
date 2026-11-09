import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/models/prefill.dart';
import 'package:firepath/nav.dart';
import 'package:firepath/pages/career/simple_quick_log_sheet.dart';
import 'package:firepath/state/app_mode_controller.dart';

/// Scroll-safe production wrapper for the simplified Quick Add experience.
///
/// Department instructors/admins get a direct Training Sheet action here so
/// field workflows start from the universal Quick Add button rather than from
/// a separate Department-page shortcut.
class ProductionQuickLogSheet extends StatelessWidget {
  final LogPrefill? prefill;

  const ProductionQuickLogSheet({super.key, this.prefill});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppModeController>();
    final canCreateTrainingSheet =
        mode.departmentLink != null && (mode.isInstructor || mode.isAdmin);

    // Do not nest another viewInsets pad here — confirm/detail steps already
    // scroll with MediaQuery.viewInsets so the primary action stays reachable.
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...[
                    FilledButton.icon(
                        key: const Key('quick_add_training_sheet'),
                        onPressed: () async {
                          final router = GoRouter.of(context);
                          router.pop();
                          // Give the sheet dismissal a tick to settle.
                          await Future<void>.delayed(Duration.zero);
                          if (canCreateTrainingSheet) {
                            router.push('${AppRoutes.departmentTrainingSheets}?create=1');
                          } else {
                            router.push(AppRoutes.department);
                          }
                        },
                        icon: const Icon(Icons.assignment_add),
                        label: const Text(
                          'Create Training Sheet',
                          textAlign: TextAlign.center,
                        ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (mode.departmentLink != null) OutlinedButton.icon(
                      key: const Key('quick_add_scan_class_qr'),
                      onPressed: () =>
                          context.push(AppRoutes.departmentQrScan),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text(
                        'Scan Training Sheet',
                        textAlign: TextAlign.center,
                      ),
                  ),
                ],
              ),
            ),
          ],
          SimpleQuickLogSheet(
            prefill: prefill,
            showDepartmentQrAction: mode.departmentLink == null,
          ),
        ],
      ),
    );
  }
}
