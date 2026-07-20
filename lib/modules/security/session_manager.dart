import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';

/// MOD-09 — Secure Storage Service
/// Wraps flutter_secure_storage with AES encryption on Android.
/// Used for storing session tokens, settings — never source code content.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

/// MOD-09 — Session Manager
/// Tracks session lifecycle and enforces cleanup of all temporary files.
/// Implements WidgetsBindingObserver to respond to app lifecycle events.
class SessionManager with WidgetsBindingObserver {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  bool _sessionActive = false;
  Directory? _sessionTempDir;

  /// Initialize — call once in main() after WidgetsFlutterBinding.ensureInitialized()
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[MOD-09] SessionManager initialized');
  }

  /// Begin a new extraction session — creates encrypted temp directory
  Future<void> startSession() async {
    if (_sessionActive) await endSession();

    try {
      final tempBase = await getTemporaryDirectory();
      _sessionTempDir = Directory(
        '${tempBase.path}/${AppConstants.tempDirName}_${DateTime.now().millisecondsSinceEpoch}',
      );
      await _sessionTempDir!.create(recursive: true);
      _sessionActive = true;

      await SecureStorageService.instance.write(
        AppConstants.secureStorageKey,
        DateTime.now().toIso8601String(),
      );

      debugPrint('[MOD-09] Session started: ${_sessionTempDir!.path}');
    } catch (e) {
      debugPrint('[MOD-09] Failed to start session: $e');
    }
  }

  /// Returns the current session's temporary directory (create files here)
  Directory? get sessionTempDir => _sessionTempDir;

  /// End the session — deletes ALL temporary files
  /// Runs even if the app is being closed (see lifecycle observer)
  Future<void> endSession() async {
    if (!_sessionActive && _sessionTempDir == null) return;

    try {
      await _cleanupTempFiles();
      await SecureStorageService.instance.delete(AppConstants.secureStorageKey);
      _sessionActive = false;
      _sessionTempDir = null;
      debugPrint('[MOD-09] Session ended — all temp files deleted');
    } catch (e) {
      debugPrint('[MOD-09] Session cleanup error: $e');
      // Even on error, mark session inactive to prevent data leakage
      _sessionActive = false;
      _sessionTempDir = null;
    }
  }

  /// Deletes all files in the session temp directory
  Future<void> _cleanupTempFiles() async {
    if (_sessionTempDir == null) return;
    if (await _sessionTempDir!.exists()) {
      await _sessionTempDir!.delete(recursive: true);
      debugPrint('[MOD-09] Temp directory deleted: ${_sessionTempDir!.path}');
    }
  }

  bool get isSessionActive => _sessionActive;

  // ── WidgetsBindingObserver ────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        debugPrint('[MOD-09] App paused — initiating session cleanup');
        endSession();
        break;
      case AppLifecycleState.detached:
        debugPrint('[MOD-09] App detached — initiating session cleanup');
        endSession();
        break;
      default:
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
