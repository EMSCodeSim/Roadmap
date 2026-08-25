import 'package:flutter/material.dart';

import 'package:firepath/models/prefill.dart';
import 'package:firepath/pages/career/quick_log_sheet.dart';
import 'package:firepath/pages/career/simple_quick_log_sheet.dart';

/// Unified entry point for Quick Log.
///
/// Common entries now start with six fixed choices: Training, Call, Skill,
/// Driving, Career, and Task Book. The full logger is still available for
/// mileage, hours, notes, outcomes, task links, apparatus details, or custom
/// fields.
class QuickLogLauncher {
  static Future<void> open(BuildContext context, {LogPrefill? prefill}) async {
    final result = await showModalBottomSheet<SimpleQuickLogResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => SimpleQuickLogSheet(prefill: prefill),
    );

    if (result != SimpleQuickLogResult.moreDetails || !context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => QuickLogSheet(prefill: prefill),
    );
  }
}
