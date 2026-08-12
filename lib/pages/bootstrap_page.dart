import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/services/task_book_setup_store.dart';
import 'package:firepath/state/app_state.dart';

class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key});

  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<AppState>();
    if (_navigated || !state.bootstrapped) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _route(state));
  }

  Future<void> _route(AppState state) async {
    if (!mounted) return;
    if (!state.onboardingComplete) {
      context.go(AppRoutes.onboarding);
      return;
    }

    final reviewPending = await TaskBookSetupStore().isReviewPending();
    if (!mounted) return;
    context.go(reviewPending ? AppRoutes.taskBookReview : AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
