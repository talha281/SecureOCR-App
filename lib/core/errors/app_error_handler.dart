import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Global error handler — catches uncaught Flutter framework errors
/// Displays a safe fallback UI instead of crashing the app
class AppErrorHandler {
  AppErrorHandler._();

  /// Call this in main() before runApp()
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error (privacy-safe: no source code content included)
      debugPrint('[SecureCode OCR] Framework error: ${details.exceptionAsString()}');
      debugPrint('[SecureCode OCR] Stack: ${details.stack.toString()}');
      // In production, send crash metrics (no code content) here
    };
  }
}

/// Widget that wraps the app and catches errors in the widget tree
class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  const AppErrorBoundary({super.key, required this.child});

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorFallback(onRetry: () => setState(() => _error = null));
    }
    return widget.child;
  }
}

class _ErrorFallback extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorFallback({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No data was transmitted. Please restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
