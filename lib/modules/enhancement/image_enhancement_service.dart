import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../security/session_manager.dart';
import 'enhancement_state.dart';

/// MOD-03 — Image Enhancement Service
/// Applies rotation, crop, brightness, contrast, and noise reduction
/// using the 'image' package (100% on-device, no network).
///
/// All operations run in a background Isolate to avoid blocking the UI.
/// Output is written to the MOD-09 session temp directory.
class ImageEnhancementService {
  ImageEnhancementService._();
  static final ImageEnhancementService instance = ImageEnhancementService._();

  /// Main entry point — apply all active enhancements and return temp path
  Future<String> applyEnhancements({
    required String sourcePath,
    required EnhancementState state,
  }) async {
    debugPrint('[MOD-03] Starting enhancement pipeline...');

    // Run heavy processing in background isolate to keep UI smooth
    final resultBytes = await Isolate.run(() => _processImage(
          sourcePath: sourcePath,
          rotationDegrees: state.rotationDegrees,
          brightness: state.brightness,
          contrast: state.contrast,
          noiseRadius: state.noiseReductionRadius,
          crop: state.cropRect,
        ));

    // Save result to session temp dir (MOD-09)
    final outputPath = await _saveToTemp(resultBytes);
    debugPrint('[MOD-03] Enhancement complete → $outputPath');
    return outputPath;
  }

  // ── Background isolate worker ─────────────────────────────────────────────

  static List<int> _processImage({
    required String sourcePath,
    required double rotationDegrees,
    required double brightness,
    required double contrast,
    required int noiseRadius,
    required CropRect? crop,
  }) {
    // 1. Decode source image
    final bytes = File(sourcePath).readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Cannot decode image at $sourcePath');

    // 2. Crop first (before rotate, so handles are on un-rotated image)
    if (crop != null && crop.isValid) {
      final x = (crop.left * image.width).round();
      final y = (crop.top * image.height).round();
      final w = ((crop.right - crop.left) * image.width).round();
      final h = ((crop.bottom - crop.top) * image.height).round();
      image = img.copyCrop(image, x: x, y: y, width: w, height: h);
    }

    // 3. Rotate
    if (rotationDegrees != 0.0) {
      image = img.copyRotate(image, angle: rotationDegrees);
    }

    // 4. Brightness & Contrast
    if (brightness != 0.0 || contrast != 0.0) {
      // Map -1..1 to the img package scale
      // brightness: -255..255
      // contrast: 0..2 (1.0 = original)
      final brightnessInt = (brightness * 128).round();
      final contrastScale = 1.0 + contrast; // -1→0 (flat), 0→1 (orig), +1→2 (high)
      image = img.adjustColor(
        image,
        brightness: brightnessInt.toDouble(),
        contrast: contrastScale,
      );
    }

    // 5. Noise reduction (Gaussian blur with small radius)
    if (noiseRadius > 0) {
      image = img.gaussianBlur(image, radius: noiseRadius);
    }

    // 6. Encode as JPEG (high quality for OCR accuracy)
    return img.encodeJpg(image, quality: 95);
  }

  // ── Save to MOD-09 session temp dir ──────────────────────────────────────

  Future<String> _saveToTemp(List<int> bytes) async {
    Directory targetDir;
    if (SessionManager.instance.isSessionActive &&
        SessionManager.instance.sessionTempDir != null) {
      targetDir = SessionManager.instance.sessionTempDir!;
    } else {
      targetDir = await getTemporaryDirectory();
    }

    final filename = 'enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outputPath = p.join(targetDir.path, filename);
    await File(outputPath).writeAsBytes(bytes);
    return outputPath;
  }

  // ── Quick auto-enhance (auto-contrast + mild denoise) ────────────────────

  /// Auto-enhance: applies slight contrast boost + noise reduction for OCR.
  /// Used as a one-tap "Optimize for OCR" shortcut.
  Future<String> autoEnhance(String sourcePath) async {
    return applyEnhancements(
      sourcePath: sourcePath,
      state: const EnhancementState(
        contrast: 0.25,     // Mild contrast boost
        brightness: 0.05,   // Very slight brightness
        noiseReductionRadius: 1, // Light denoise
      ),
    );
  }
}
