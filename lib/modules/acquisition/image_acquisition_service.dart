import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../security/session_manager.dart';
import 'permission_service.dart';
import 'image_acquisition_provider.dart';

/// MOD-02 — Image Acquisition Service
/// Orchestrates camera capture and gallery import.
/// All images are written ONLY to the MOD-09 session temp directory.
/// No permanent copy is ever made.
class ImageAcquisitionService {
  ImageAcquisitionService._();
  static final ImageAcquisitionService instance = ImageAcquisitionService._();

  final _picker = picker.ImagePicker();

  // ── Camera Capture ────────────────────────────────────────────────────────

  /// Request camera permission → capture → return session-scoped temp path
  Future<AcquisitionResult> captureFromCamera(BuildContext context) async {
    // Check / request permission
    final granted = await _ensureCameraPermission(context);
    if (!granted) return AcquisitionResult.permissionDenied();

    try {
      final xFile = await _picker.pickImage(
        source: picker.ImageSource.camera,
        preferredCameraDevice: picker.CameraDevice.rear,
      );

      if (xFile == null) return AcquisitionResult.cancelled();

      // Copy to session temp dir — no permanent storage
      final tempPath = await _copyToSessionTemp(xFile.path, 'camera');
      return AcquisitionResult.success(tempPath, ImageSource.camera);
    } catch (e) {
      debugPrint('[MOD-02] Camera capture error: $e');
      return AcquisitionResult.error('Failed to capture image. Please try again.');
    }
  }

  // ── Gallery Import ────────────────────────────────────────────────────────

  /// Request gallery permission → pick → return session-scoped temp path
  Future<AcquisitionResult> importFromGallery(BuildContext context) async {
    // Check / request permission
    final granted = await _ensureGalleryPermission(context);
    if (!granted) return AcquisitionResult.permissionDenied();

    try {
      final xFile = await _picker.pickImage(
        source: picker.ImageSource.gallery,
      );

      if (xFile == null) return AcquisitionResult.cancelled();

      // Copy to session temp dir — original gallery image is NOT modified
      final tempPath = await _copyToSessionTemp(xFile.path, 'gallery');
      return AcquisitionResult.success(tempPath, ImageSource.gallery);
    } catch (e) {
      debugPrint('[MOD-02] Gallery import error: $e');
      return AcquisitionResult.error('Failed to import image. Please try again.');
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<String> _copyToSessionTemp(String sourcePath, String prefix) async {
    // Ensure session is active (MOD-09)
    if (!SessionManager.instance.isSessionActive) {
      await SessionManager.instance.startSession();
    }

    final sessionDir = SessionManager.instance.sessionTempDir;
    final tempBase = await getTemporaryDirectory();
    final targetDir = sessionDir ?? tempBase;

    final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(targetDir.path, filename);
    await File(sourcePath).copy(targetPath);

    debugPrint('[MOD-02] Image copied to session temp: $targetPath');
    return targetPath;
  }

  Future<bool> _ensureCameraPermission(BuildContext context) async {
    if (await PermissionService.instance.isCameraGranted()) return true;
    // ignore: use_build_context_synchronously
    if (!context.mounted) return false;

    // Show rationale synchronously, then await result
    final proceedFuture = PermissionService.instance.showRationale(
      context,
      type: PermissionType.camera,
    );
    final proceed = await proceedFuture;
    if (!proceed) return false;

    final result = await PermissionService.instance.requestCamera();
    if (result == PermissionResult.permanentlyDenied) {
      if (context.mounted) _showSettingsPrompt(context, 'camera');
    }
    return result == PermissionResult.granted;
  }

  Future<bool> _ensureGalleryPermission(BuildContext context) async {
    if (await PermissionService.instance.isGalleryGranted()) return true;
    // ignore: use_build_context_synchronously
    if (!context.mounted) return false;

    final proceedFuture = PermissionService.instance.showRationale(
      context,
      type: PermissionType.gallery,
    );
    final proceed = await proceedFuture;
    if (!proceed) return false;

    final result = await PermissionService.instance.requestGallery();
    if (result == PermissionResult.permanentlyDenied) {
      if (context.mounted) _showSettingsPrompt(context, 'photo library');
    }
    return result == PermissionResult.granted;
  }

  void _showSettingsPrompt(BuildContext context, String permissionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Enable $permissionName access in Settings to continue.',
          style: const TextStyle(color: Color(0xFFF1F5F9)),
        ),
        action: SnackBarAction(
          label: 'Open Settings',
          textColor: const Color(0xFF00D4FF),
          onPressed: PermissionService.instance.openSettings,
        ),
      ),
    );
  }
}

/// Result type returned from acquisition operations
class AcquisitionResult {
  final String? imagePath;
  final ImageSource? source;
  final AcquisitionStatus status;
  final String? errorMessage;

  const AcquisitionResult._({
    this.imagePath,
    this.source,
    required this.status,
    this.errorMessage,
  });

  factory AcquisitionResult.success(String path, ImageSource source) =>
      AcquisitionResult._(
        imagePath: path,
        source: source,
        status: AcquisitionStatus.success,
      );

  factory AcquisitionResult.cancelled() =>
      const AcquisitionResult._(status: AcquisitionStatus.cancelled);

  factory AcquisitionResult.permissionDenied() =>
      const AcquisitionResult._(status: AcquisitionStatus.permissionDenied);

  factory AcquisitionResult.error(String message) => AcquisitionResult._(
        status: AcquisitionStatus.error,
        errorMessage: message,
      );

  bool get isSuccess => status == AcquisitionStatus.success;
}

enum AcquisitionStatus { success, cancelled, permissionDenied, error }
