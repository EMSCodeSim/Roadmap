import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/phone_theme.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: MaterialApp.router(
        title: 'FireOps Career Road',
        debugShowCheckedModeBanner: false,
        theme: phoneFriendlyTheme(lightTheme),
        darkTheme: phoneFriendlyTheme(darkTheme),
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
