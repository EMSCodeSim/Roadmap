import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Back navigation that never leaves a secondary screen stranded.
///
/// When the page was pushed normally, this pops back to the exact prior page.
/// When the page was opened directly or via `go()`, there may be no route to
/// pop, so a logical fallback destination is used instead.
class AppBackButton extends StatelessWidget {
  final String fallbackRoute;

  const AppBackButton({super.key, required this.fallbackRoute});

  const AppBackButton.toHome({super.key}) : fallbackRoute = '/home';
  const AppBackButton.toTaskBook({super.key}) : fallbackRoute = '/path';
  const AppBackButton.toLog({super.key}) : fallbackRoute = '/log';
  const AppBackButton.toAdvance({super.key}) : fallbackRoute = '/growth';
  const AppBackButton.toCareerIntelligence({super.key})
    : fallbackRoute = '/career-intelligence';
  const AppBackButton.toCertifications({super.key})
    : fallbackRoute = '/certifications';

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go(fallbackRoute);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () => _handleBack(context),
      icon: const Icon(Icons.arrow_back),
    );
  }
}
