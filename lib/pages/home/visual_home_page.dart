import 'package:flutter/material.dart';

import 'package:firepath/pages/home/home_page.dart';

class VisualHomePage extends StatelessWidget {
  const VisualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: const HomePage(),
      ),
    );
  }
}
