import 'package:flutter/material.dart';

import 'package:firepath/models/prefill.dart';
import 'package:firepath/pages/career/quick_log_sheet.dart';

/// Unified entry point for the fast-capture Quick Log flow.
///
/// This is intentionally independent from the bottom Log tab (Career Record).
/// Home and Task Book can log immediately without navigating away.
class QuickLogLauncher {
  static Future<void> open(BuildContext context, {LogPrefill? prefill}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => QuickLogSheet(prefill: prefill),
    );
  }
}
