import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MOD-03 — Enhancement State
/// Tracks all user-configured enhancement parameters before applying them.
/// Parameters are non-destructive until the user taps "Apply".
class EnhancementState {
  // Rotation in degrees (multiple of 90 from quick buttons, or free value)
  final double rotationDegrees;

  // Brightness: -1.0 (darkest) to +1.0 (brightest), 0.0 = original
  final double brightness;

  // Contrast: -1.0 (flat) to +1.0 (high contrast), 0.0 = original
  final double contrast;

  // Noise reduction radius (0 = off, 1-3 = mild to heavy)
  final int noiseReductionRadius;

  // Crop rectangle as fractions of image (0.0–1.0)
  final CropRect? cropRect;

  // Whether the user has applied any changes
  final bool hasEdits;

  // Processing state
  final bool isProcessing;
  final String? processedImagePath; // path to enhanced image in temp dir
  final String? error;

  const EnhancementState({
    this.rotationDegrees = 0.0,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.noiseReductionRadius = 0,
    this.cropRect,
    this.hasEdits = false,
    this.isProcessing = false,
    this.processedImagePath,
    this.error,
  });

  bool get hasCrop => cropRect != null;
  bool get hasRotation => rotationDegrees != 0.0;
  bool get hasBrightnessOrContrast => brightness != 0.0 || contrast != 0.0;
  bool get hasNoise => noiseReductionRadius > 0;
  bool get anyEdits => hasRotation || hasBrightnessOrContrast || hasNoise || hasCrop;

  EnhancementState copyWith({
    double? rotationDegrees,
    double? brightness,
    double? contrast,
    int? noiseReductionRadius,
    CropRect? cropRect,
    bool? hasEdits,
    bool? isProcessing,
    String? processedImagePath,
    String? error,
    bool clearCrop = false,
    bool clearProcessed = false,
    bool clearError = false,
  }) {
    return EnhancementState(
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      noiseReductionRadius: noiseReductionRadius ?? this.noiseReductionRadius,
      cropRect: clearCrop ? null : (cropRect ?? this.cropRect),
      hasEdits: hasEdits ?? this.hasEdits,
      isProcessing: isProcessing ?? this.isProcessing,
      processedImagePath: clearProcessed ? null : (processedImagePath ?? this.processedImagePath),
      error: clearError ? null : (error ?? this.error),
    );
  }

  EnhancementState reset() => const EnhancementState();
}

/// Normalized crop rectangle (values 0.0–1.0 relative to image dimensions)
class CropRect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const CropRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  bool get isValid =>
      left >= 0.0 && top >= 0.0 &&
      right <= 1.0 && bottom <= 1.0 &&
      right > left + 0.05 && bottom > top + 0.05;

  @override
  String toString() =>
      'CropRect(left: $left, top: $top, right: $right, bottom: $bottom)';
}

/// Riverpod notifier
class EnhancementNotifier extends StateNotifier<EnhancementState> {
  EnhancementNotifier() : super(const EnhancementState());

  void setRotation(double degrees) => state = state.copyWith(
        rotationDegrees: degrees % 360,
        hasEdits: true,
      );

  void rotate90Clockwise() => setRotation(state.rotationDegrees + 90);
  void rotate90CounterClockwise() => setRotation(state.rotationDegrees - 90);

  void setBrightness(double value) => state = state.copyWith(
        brightness: value.clamp(-1.0, 1.0),
        hasEdits: true,
      );

  void setContrast(double value) => state = state.copyWith(
        contrast: value.clamp(-1.0, 1.0),
        hasEdits: true,
      );

  void setNoiseReduction(int radius) => state = state.copyWith(
        noiseReductionRadius: radius.clamp(0, 3),
        hasEdits: true,
      );

  void setCrop(CropRect rect) {
    if (rect.isValid) {
      state = state.copyWith(cropRect: rect, hasEdits: true);
    }
  }

  void clearCrop() => state = state.copyWith(clearCrop: true, hasEdits: true);

  void setProcessing() => state = state.copyWith(isProcessing: true, clearError: true);

  void setProcessed(String path) => state = state.copyWith(
        isProcessing: false,
        processedImagePath: path,
      );

  void setError(String message) => state = state.copyWith(
        isProcessing: false,
        error: message,
      );

  void resetAll() => state = const EnhancementState();
}

final enhancementProvider =
    StateNotifierProvider<EnhancementNotifier, EnhancementState>(
  (ref) => EnhancementNotifier(),
);
