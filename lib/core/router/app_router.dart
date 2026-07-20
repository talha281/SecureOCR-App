import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home_screen.dart';
import '../../screens/preview_screen.dart';
import '../../screens/processing_screen.dart';
import '../../screens/editor_screen.dart';
import '../constants/app_constants.dart';

/// GoRouter configuration for SecureCode OCR
/// Defines all 4 navigation routes for v1.0
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
    GoRoute(
      path: AppRoutes.preview,
      name: 'preview',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PreviewScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
    GoRoute(
      path: AppRoutes.processing,
      name: 'processing',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProcessingScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
    GoRoute(
      path: AppRoutes.editor,
      name: 'editor',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EditorScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
  ],
  errorBuilder: (context, state) => _RouterErrorScreen(error: state.error),
);

/// Smooth fade + upward slide transition for all routes
Widget _fadeSlideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

/// Fallback error screen shown for invalid routes
class _RouterErrorScreen extends StatelessWidget {
  final Exception? error;
  const _RouterErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Navigation error: ${error?.toString() ?? "Unknown route"}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
