import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';

void main() => runApp(const RfisApp());

class RfisApp extends StatefulWidget {
  const RfisApp({super.key});

  @override
  State<RfisApp> createState() => _RfisAppState();
}

class _RfisAppState extends State<RfisApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: Builder(
        builder: (context) {
          final app = AppScope.of(context);
          return MaterialApp(
            title: 'RFIS',
            debugShowCheckedModeBanner: false,
            locale: Locale(app.isArabic ? 'ar' : 'en'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF3E7C3E),
              ),
              scaffoldBackgroundColor: const Color(0xFFF1F5F5),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF262B36),
                foregroundColor: Colors.white,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
              ),
            ),
            home: const RootGate(),
          );
        },
      ),
    );
  }
}

/// Shows the login screen until the demo sign-in succeeds, then the shell.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return context.app.loggedIn ? const AppShell() : const LoginScreen();
  }
}
