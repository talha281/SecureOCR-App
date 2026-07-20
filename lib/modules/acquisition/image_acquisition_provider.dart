import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MOD-02 — Image Acquisition State
/// Holds the currently acquired image path (from camera or gallery).
/// This is a session-scoped reference — no permanent storage.
class ImageAcquisitionState {
  final String? imagePath;
  final ImageSource? source;
  final bool isLoading;
  final String? error;

  const ImageAcquisitionState({
    this.imagePath,
    this.source,
    this.isLoading = false,
    this.error,
  });

  File? get imageFile => imagePath != null ? File(imagePath!) : null;

  bool get hasImage => imagePath != null;

  ImageAcquisitionState copyWith({
    String? imagePath,
    ImageSource? source,
    bool? isLoading,
    String? error,
    bool clearImage = false,
    bool clearError = false,
  }) {
    return ImageAcquisitionState(
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      source: clearImage ? null : (source ?? this.source),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

enum ImageSource { camera, gallery }

/// Riverpod state notifier for image acquisition
class ImageAcquisitionNotifier extends StateNotifier<ImageAcquisitionState> {
  ImageAcquisitionNotifier() : super(const ImageAcquisitionState());

  void setLoading() {
    state = state.copyWith(isLoading: true, clearError: true);
  }

  void setImage(String path, ImageSource source) {
    state = ImageAcquisitionState(
      imagePath: path,
      source: source,
      isLoading: false,
    );
  }

  void setError(String message) {
    state = state.copyWith(isLoading: false, error: message);
  }

  void clearImage() {
    state = const ImageAcquisitionState();
  }
}

/// Global provider — accessible from Home, Camera, Preview screens
final imageAcquisitionProvider =
    StateNotifierProvider<ImageAcquisitionNotifier, ImageAcquisitionState>(
  (ref) => ImageAcquisitionNotifier(),
);
