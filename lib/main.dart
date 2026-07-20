import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/errors/app_error_handler.dart';
import 'modules/security/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MOD-01 — Force portrait orientation (code screenshots are typically vertical)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // MOD-01 — Initialize global error handler
  AppErrorHandler.initialize();

  // MOD-09 — Initialize session manager with lifecycle observer
  SessionManager.instance.initialize();

  runApp(
    // Riverpod provider scope wraps the entire app
    const ProviderScope(
      child: SecureCodeOCRApp(),
    ),
  );
}

/// Root application widget
class SecureCodeOCRApp extends ConsumerWidget {
  const SecureCodeOCRApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SecureCode OCR',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark, // Dark by default (enterprise-focused)

      // Navigation
      routerConfig: appRouter,
    );
  }
}
