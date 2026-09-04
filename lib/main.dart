import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'package:firepath/nav.dart';
import 'package:firepath/phone_theme.dart';
import 'package:firepath/portal/state/portal_controller.dart';
import 'package:firepath/state/app_state.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/department_inbox_controller.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) debugPrint(details.stack.toString());
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('ErrorWidget: ${details.exceptionAsString()}');
    if (details.stack != null) debugPrint(details.stack.toString());
    return Material(
      color: Colors.red.shade900,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong.\n\n${details.exceptionAsString()}',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..bootstrap()),
        ChangeNotifierProvider(create: (_) => AppModeController()..bootstrap()),
        ChangeNotifierProvider(create: (_) => DepartmentInboxController()..bootstrap()),
        ChangeNotifierProvider(create: (_) => PortalController()..bootstrap()),
      ],
      child: MaterialApp.router(
        title: 'Responder Roadmap',
        debugShowCheckedModeBanner: false,
        theme: phoneFriendlyTheme(lightTheme),
        darkTheme: phoneFriendlyTheme(darkTheme),
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
