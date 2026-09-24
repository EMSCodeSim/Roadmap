import 'package:flutter/material.dart';

/// Shared keyboard-aware padding for forms and bottom sheets.
///
/// Ensures primary actions stay reachable when the soft keyboard is open by
/// combining [MediaQuery.viewInsets] with optional extra bottom padding.
class KeyboardAwarePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool includeViewInsets;

  const KeyboardAwarePadding({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.includeViewInsets = true,
  });

  @override
  Widget build(BuildContext context) {
    final base = padding.resolve(Directionality.of(context));
    final inset =
        includeViewInsets ? MediaQuery.viewInsetsOf(context).bottom : 0.0;
    return Padding(
      padding: base.copyWith(bottom: base.bottom + inset),
      child: child,
    );
  }
}

/// Scrollable form body that keeps focused fields and bottom actions reachable
/// while the keyboard is open.
class KeyboardAwareFormBody extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const KeyboardAwareFormBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 18),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final resolved = padding.resolve(Directionality.of(context));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: resolved.copyWith(bottom: resolved.bottom + bottomInset),
        child: Column(
          mainAxisSize: mainAxisSize,
          crossAxisAlignment: crossAxisAlignment,
          children: children,
        ),
      ),
    );
  }
}
