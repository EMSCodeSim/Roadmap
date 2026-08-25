import 'package:flutter/material.dart';

import 'package:firepath/models/prefill.dart';
import 'package:firepath/pages/career/simple_quick_log_sheet.dart';

/// Scroll-safe production wrapper for the simplified Quick Log.
///
/// Bottom sheets can be short in landscape, on smaller phones, or when text
/// scaling is increased. Giving the simplified logger an outer scroll view
/// prevents category buttons from being pushed off-screen or overflowing.
class ProductionQuickLogSheet extends StatelessWidget {
  final LogPrefill? prefill;

  const ProductionQuickLogSheet({super.key, this.prefill});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: SimpleQuickLogSheet(prefill: prefill),
    );
  }
}
