/// SecureCode OCR — App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'SecureCode OCR';
  static const String appTagline = 'Privacy-First Code Extraction';
  static const String appVersion = '1.0.0';

  // Privacy badge text
  static const String privacyBadge = '100% On-Device  •  Zero Cloud';

  // Performance thresholds (milliseconds)
  static const int ocrTimeoutMs = 3000;
  static const int detectionTimeoutMs = 1000;
  static const int editorOpenTargetMs = 500;

  // Security
  static const String tempDirName = 'sco_session';
  static const String secureStorageKey = 'sco_session_active';
}

/// Named route paths used by GoRouter
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String preview = '/preview';
  static const String processing = '/processing';
  static const String editor = '/editor';
}
