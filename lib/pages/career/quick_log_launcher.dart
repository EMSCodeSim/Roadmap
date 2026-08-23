import 'package:flutter/material.dart';

import 'package:firepath/models/prefill.dart';
import 'package:firepath/pages/career/fast_quick_log_sheet.dart';
import 'package:firepath/pages/career/quick_log_sheet.dart';

/// Unified entry point for Quick Log.
///
/// Common entries use the fast 2–3 tap capture flow first. Users can still
/// open the full legacy form when they need miles, hours, notes, outcomes,
/// task links, apparatus details, or custom fields.
class QuickLogLauncher {
  static Future<void> open(BuildContext context, {LogPrefill? prefill}) async {
    final result = await showModalBottomSheet<FastQuickLogResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => FastQuickLogSheet(prefill: prefill),
    );

    if (result != FastQuickLogResult.moreDetails || !context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => QuickLogSheet(prefill: prefill),
    );
  }
}
