/// MOD-04 — OCR Models
/// Structured output data models from on-device text recognition.

class OcrElementModel {
  final String text;
  final double confidence; // 0.0 to 1.0 (estimated/calculated if ML Kit omits)

  const OcrElementModel({
    required this.text,
    required this.confidence,
  });
}

class OcrLineModel {
  final String text;
  final List<OcrElementModel> elements;
  final double confidence;

  const OcrLineModel({
    required this.text,
    required this.elements,
    required this.confidence,
  });
}

class OcrBlockModel {
  final String text;
  final List<OcrLineModel> lines;
  final double confidence;

  const OcrBlockModel({
    required this.text,
    required this.lines,
    required this.confidence,
  });
}

class OcrResult {
  final String rawText;
  final List<OcrBlockModel> blocks;
  final double averageConfidence;
  final Duration processingTime;
  final bool isSuccess;
  final String? errorMessage;

  const OcrResult({
    required this.rawText,
    required this.blocks,
    required this.averageConfidence,
    required this.processingTime,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory OcrResult.empty() => const OcrResult(
        rawText: '',
        blocks: [],
        averageConfidence: 0.0,
        processingTime: Duration.zero,
        isSuccess: true,
      );

  factory OcrResult.failure(String error) => OcrResult(
        rawText: '',
        blocks: const [],
        averageConfidence: 0.0,
        processingTime: Duration.zero,
        isSuccess: false,
        errorMessage: error,
      );

  bool get isEmpty => rawText.trim().isEmpty;
}
