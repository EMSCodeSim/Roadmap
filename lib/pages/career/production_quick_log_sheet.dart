import 'package:flutter/material.dart';

import 'package:firepath/models/prefill.dart';
import 'package:firepath/pages/career/simple_quick_log_sheet.dart';

/// Scroll-safe production wrapper for the simplified Quick Log.
///
/// Bottom sheets can be short in landscape, on smaller phones, or when text
/// scaling is increased. The confirm step inside [SimpleQuickLogSheet] applies
/// keyboard viewInsets so Save Log stays reachable while typing.
class ProductionQuickLogSheet extends StatelessWidget {
  final LogPrefill? prefill;

  const ProductionQuickLogSheet({super.key, this.prefill});

  @override
  Widget build(BuildContext context) {
    // Do not nest another viewInsets pad here — confirm/detail steps already
    // scroll with MediaQuery.viewInsets so the primary action stays reachable.
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: SimpleQuickLogSheet(prefill: prefill),
    );
  }
}
