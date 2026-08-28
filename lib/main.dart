import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/phone_theme.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..bootstrap()),
        ChangeNotifierProvider(create: (_) => PortalController()..bootstrap()),
      ],
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
