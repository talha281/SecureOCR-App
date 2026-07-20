import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ocr_models.dart';
import 'ocr_engine_service.dart';
import '../detection/language_detector_service.dart';
import '../cleanup/code_cleanup_service.dart';

enum OcrStatus { idle, loadingImage, runningOcr, detectingLanguage, cleaningCode, complete, error }

class OcrState {
  final OcrStatus status;
  final String currentStepMessage;
  final double progress; // 0.0 to 1.0
  final OcrResult? rawResult;
  final LanguageDetectionResult? detectionResult;
  final CleanupResult? cleanupResult;
  final String? error;

  const OcrState({
    this.status = OcrStatus.idle,
    this.currentStepMessage = 'Initializing...',
    this.progress = 0.0,
    this.rawResult,
    this.detectionResult,
    this.cleanupResult,
    this.error,
  });

  bool get isProcessing =>
      status == OcrStatus.loadingImage ||
      status == OcrStatus.runningOcr ||
      status == OcrStatus.detectingLanguage ||
      status == OcrStatus.cleaningCode;

  bool get isSuccess => status == OcrStatus.complete && rawResult != null;

  String get finalCode => cleanupResult?.cleanedText ?? rawResult?.rawText ?? '';

  OcrState copyWith({
    OcrStatus? status,
    String? currentStepMessage,
    double? progress,
    OcrResult? rawResult,
    LanguageDetectionResult? detectionResult,
    CleanupResult? cleanupResult,
    String? error,
  }) {
    return OcrState(
      status: status ?? this.status,
      currentStepMessage: currentStepMessage ?? this.currentStepMessage,
      progress: progress ?? this.progress,
      rawResult: rawResult ?? this.rawResult,
      detectionResult: detectionResult ?? this.detectionResult,
      cleanupResult: cleanupResult ?? this.cleanupResult,
      error: error ?? this.error,
    );
  }
}

class OcrNotifier extends StateNotifier<OcrState> {
  OcrNotifier() : super(const OcrState());

  Future<void> runOcrPipeline(String imagePath) async {
    // Step 1: Loading image
    state = const OcrState(
      status: OcrStatus.loadingImage,
      currentStepMessage: 'Loading enhanced image...',
      progress: 0.15,
    );

    await Future.delayed(const Duration(milliseconds: 200));

    // Step 2: Running ML Kit OCR engine
    state = state.copyWith(
      status: OcrStatus.runningOcr,
      currentStepMessage: 'Extracting characters on-device...',
      progress: 0.45,
    );

    final rawResult = await OcrEngineService.instance.processImage(imagePath);

    if (!rawResult.isSuccess) {
      state = state.copyWith(
        status: OcrStatus.error,
        error: rawResult.errorMessage ?? 'OCR processing failed.',
        progress: 0.0,
      );
      return;
    }

    // Step 3: MOD-05 — Language & Framework Detection
    state = state.copyWith(
      status: OcrStatus.detectingLanguage,
      currentStepMessage: 'Detecting language & framework...',
      progress: 0.70,
    );

    final detectionResult = LanguageDetectorService.instance.detect(rawResult.rawText);

    // Step 4: MOD-06 — Code Cleanup & Post-Processing
    state = state.copyWith(
      status: OcrStatus.cleaningCode,
      currentStepMessage: 'Stripping noise & line numbers...',
      progress: 0.90,
    );

    final cleanupResult = CodeCleanupService.instance.clean(rawResult.rawText);

    await Future.delayed(const Duration(milliseconds: 150));

    // Step 5: Complete
    state = state.copyWith(
      status: OcrStatus.complete,
      currentStepMessage: 'Extraction & cleanup complete!',
      progress: 1.0,
      rawResult: rawResult,
      detectionResult: detectionResult,
      cleanupResult: cleanupResult,
    );
  }

  void reset() {
    state = const OcrState();
  }
}

final ocrProvider = StateNotifierProvider<OcrNotifier, OcrState>((ref) {
  return OcrNotifier();
});
