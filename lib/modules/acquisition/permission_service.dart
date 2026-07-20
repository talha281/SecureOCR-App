import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// MOD-02 — Permission Service
/// Handles camera and storage permission request flows for Android.
/// Provides status checks, request, and graceful denial handling.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  // ── Camera ───────────────────────────────────────────────────────────────

  Future<bool> isCameraGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<PermissionResult> requestCamera() async {
    final status = await Permission.camera.request();
    return _mapStatus(status, PermissionType.camera);
  }

  // ── Storage (gallery read) ────────────────────────────────────────────────
  // Android 13+ uses READ_MEDIA_IMAGES; below uses READ_EXTERNAL_STORAGE

  Future<bool> isGalleryGranted() async {
    // API 33+ uses photos permission
    final photosStatus = await Permission.photos.status;
    if (photosStatus != PermissionStatus.permanentlyDenied) {
      return photosStatus.isGranted;
    }
    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted;
  }

  Future<PermissionResult> requestGallery() async {
    PermissionStatus status = await Permission.photos.request();
    if (status == PermissionStatus.permanentlyDenied) {
      status = await Permission.storage.request();
    }
    return _mapStatus(status, PermissionType.gallery);
  }

  // ── Settings redirect ─────────────────────────────────────────────────────

  Future<void> openSettings() async {
    await openAppSettings();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  PermissionResult _mapStatus(PermissionStatus status, PermissionType type) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return PermissionResult.granted;
      case PermissionStatus.denied:
        return PermissionResult.denied;
      case PermissionStatus.permanentlyDenied:
        return PermissionResult.permanentlyDenied;
      default:
        return PermissionResult.denied;
    }
  }

  /// Shows a permission rationale dialog before making the system request.
  /// Returns true if user agreed to proceed.
  Future<bool> showRationale(
    BuildContext context, {
    required PermissionType type,
  }) async {
    final title = type == PermissionType.camera
        ? 'Camera Access Required'
        : 'Photo Library Access Required';
    final body = type == PermissionType.camera
        ? 'SecureCode OCR needs camera access to capture code images.\n\nAll processing stays on your device — nothing is uploaded.'
        : 'SecureCode OCR needs access to your photos to import code images.\n\nYour images stay on your device.';

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => _PermissionRationaleDialog(
            title: title,
            body: body,
            type: type,
          ),
        ) ??
        false;
  }
}

enum PermissionResult { granted, denied, permanentlyDenied }
enum PermissionType { camera, gallery }

/// Styled permission rationale dialog — matches dark theme
class _PermissionRationaleDialog extends StatelessWidget {
  final String title;
  final String body;
  final PermissionType type;

  const _PermissionRationaleDialog({
    required this.title,
    required this.body,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isCamera = type == PermissionType.camera;
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2D3748)),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x3300D4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCamera ? Icons.camera_alt_rounded : Icons.photo_library_rounded,
              color: const Color(0xFF00D4FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        body,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
          height: 1.6,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_permission_deny'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Not Now',
            style: TextStyle(color: Color(0xFF475569)),
          ),
        ),
        ElevatedButton(
          key: const Key('btn_permission_allow'),
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            foregroundColor: const Color(0xFF0D0F14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Allow Access',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
