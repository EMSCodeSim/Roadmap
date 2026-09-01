import 'package:flutter/material.dart';

import 'package:firepath/models/prefill.dart';
import 'package:firepath/pages/career/production_quick_log_sheet.dart';
import 'package:firepath/pages/career/quick_log_sheet.dart';
import 'package:firepath/pages/career/simple_quick_log_sheet.dart';

/// Unified entry point for Quick Log.
///
/// Common entries now start with six fixed choices: Training, Call, Skill,
/// Driving, Career, and Task Book. The full logger is still available for
/// mileage, hours, notes, outcomes, task links, apparatus details, or custom
/// fields.
class QuickLogLauncher {
  /// Changes whenever a Quick Log flow closes.
  ///
  /// Long-lived tab pages can listen to this and reload their local career
  /// records. This matters because the indexed-stack navigation keeps the Log
  /// tab mounted while Quick Log is opened from Home, Task Book, or another
  /// screen.
  static final ValueNotifier<int> recordRevision = ValueNotifier<int>(0);

  static Future<void> open(BuildContext context, {LogPrefill? prefill}) async {
    try {
      final result = await showModalBottomSheet<SimpleQuickLogResult>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (sheetContext) => ProductionQuickLogSheet(prefill: prefill),
      );

      if (result != SimpleQuickLogResult.moreDetails || !context.mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (sheetContext) => QuickLogSheet(prefill: prefill),
      );
    } finally {
      // A dismissal may be a save or a cancel. Reloading on either is cheap and
      // guarantees that successful Quick Log entries immediately appear in the
      // persistent Log tab without requiring a pull-to-refresh.
      recordRevision.value++;
    }
  }
}
