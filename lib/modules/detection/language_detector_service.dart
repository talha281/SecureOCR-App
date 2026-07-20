/// MOD-05 — Language & Framework Detection Result Model
class LanguageDetectionResult {
  final String language;
  final String? framework;
  final double confidence; // 0.0 to 1.0
  final List<String> detectedKeywords;

  const LanguageDetectionResult({
    required this.language,
    this.framework,
    required this.confidence,
    this.detectedKeywords = const [],
  });

  factory LanguageDetectionResult.unknown() => const LanguageDetectionResult(
        language: 'Plain Text',
        confidence: 0.0,
      );

  String get displayName {
    if (framework != null && framework!.isNotEmpty) {
      return '$language · $framework';
    }
    return language;
  }
}

/// MOD-05 — Language & Framework Detector Service
/// Fast (< 1 sec), rule-based classification engine for 10+ languages & frameworks.
class LanguageDetectorService {
  LanguageDetectorService._();
  static final LanguageDetectorService instance = LanguageDetectorService._();

  /// Analyze raw OCR text and return language/framework detection result
  LanguageDetectionResult detect(String rawText) {
    if (rawText.trim().isEmpty) return LanguageDetectionResult.unknown();

    final text = rawText.trim();

    // ── 1. Check for Stack Traces / Logs first ──────────────────────────────
    if (RegExp(r'(at\s+[\w\.\$<>]+\(|Exception|Error:|Traceback|NullPointerException|System\.)', caseSensitive: true).hasMatch(text)) {
      return const LanguageDetectionResult(
        language: 'Logs & Diagnostics',
        framework: 'Stack Trace',
        confidence: 0.95,
        detectedKeywords: ['Stack Trace', 'Exception'],
      );
    }

    // ── 2. Check JSON / XML / HTML / YAML ────────────────────────────────────
    if (text.startsWith('{') && text.endsWith('}') && text.contains('"')) {
      return const LanguageDetectionResult(
        language: 'JSON',
        confidence: 0.98,
        detectedKeywords: ['{ }', 'JSON'],
      );
    }
    if (text.startsWith('<') && (text.contains('<!DOCTYPE html>') || text.contains('<html') || text.contains('<div'))) {
      return const LanguageDetectionResult(
        language: 'HTML',
        confidence: 0.95,
        detectedKeywords: ['<!DOCTYPE>', '<html>'],
      );
    }
    if (text.startsWith('<?xml') || (text.startsWith('<') && text.endsWith('>') && text.contains('xmlns='))) {
      return const LanguageDetectionResult(
        language: 'XML',
        confidence: 0.95,
        detectedKeywords: ['xml'],
      );
    }

    // ── 3. Check SQL ────────────────────────────────────────────────────────
    final sqlRegex = RegExp(r'\b(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|JOIN|GROUP BY|ORDER BY|HAVING|CREATE TABLE)\b', caseSensitive: false);
    final sqlMatches = sqlRegex.allMatches(text);
    if (sqlMatches.length >= 2) {
      return LanguageDetectionResult(
        language: 'SQL',
        confidence: (sqlMatches.length * 0.25).clamp(0.70, 0.98),
        detectedKeywords: sqlMatches.map((m) => m.group(0)!).toSet().toList(),
      );
    }

    // ── 4. Language & Framework Heuristics ──────────────────────────────────

    // C# & .NET
    int csharpScore = 0;
    if (RegExp(r'\busing\s+System').hasMatch(text)) csharpScore += 4;
    if (RegExp(r'\b(namespace|public\s+class|private\s+readonly|async\s+Task|Console\.WriteLine)\b').hasMatch(text)) csharpScore += 3;
    if (RegExp(r'\b(var|string|int|bool|IEnumerable|List<)\b').hasMatch(text)) csharpScore += 1;

    // React / JSX / TSX
    int reactScore = 0;
    if (RegExp(r'\b(useState|useEffect|useContext|useReducer|useCallback|useMemo)\b').hasMatch(text)) reactScore += 5;
    if (RegExp(r'<\w+\s+className=|<[\w\.]+\/>').hasMatch(text)) reactScore += 4;

    // TypeScript
    int tsScore = 0;
    if (RegExp(r'\b(interface|type\s+\w+\s*=|:\s*string|:\s*number|:\s*boolean|as\s+const)\b').hasMatch(text)) tsScore += 3;
    if (RegExp(r'\b(import\s+\{.*\}\s+from)\b').hasMatch(text)) tsScore += 2;

    // JavaScript
    int jsScore = 0;
    if (RegExp(r'\b(const|let|var|function|console\.log|export\s+default|async\s+function)\b').hasMatch(text)) jsScore += 2;
    if (RegExp(r'=>').hasMatch(text)) jsScore += 1;

    // Angular
    int angularScore = 0;
    if (RegExp(r'@Component|@Injectable|@NgModule|\*ngIf|\*ngFor|\[ngClass\]').hasMatch(text)) angularScore += 5;

    // Python
    int pythonScore = 0;
    if (text.contains('def ') || text.contains('import ') || text.contains('from ') || text.contains('__main__')) pythonScore += 4;
    if (text.contains('self.') || text.contains('elif ') || text.contains('print(')) pythonScore += 2;

    // Dart / Flutter
    int dartScore = 0;
    if (RegExp(r'\b(StatelessWidget|StatefulWidget|Widget\s+build|BuildContext|setState|final\s+Widget)\b').hasMatch(text)) dartScore += 5;

    // ── 5. Evaluate Highest Score ───────────────────────────────────────────
    if (angularScore >= 3) {
      return const LanguageDetectionResult(
        language: 'TypeScript',
        framework: 'Angular',
        confidence: 0.92,
        detectedKeywords: ['@Component', 'Angular'],
      );
    }

    if (reactScore >= 3) {
      final isTs = tsScore > 0;
      return LanguageDetectionResult(
        language: isTs ? 'TypeScript' : 'JavaScript',
        framework: 'React',
        confidence: 0.93,
        detectedKeywords: const ['React', 'Hooks'],
      );
    }

    if (csharpScore >= 3) {
      final isDotNet = text.contains('Microsoft.AspNetCore') || text.contains('ControllerBase');
      return LanguageDetectionResult(
        language: 'C#',
        framework: isDotNet ? 'ASP.NET Core' : '.NET',
        confidence: (csharpScore * 0.15).clamp(0.75, 0.98),
        detectedKeywords: const ['C#', '.NET'],
      );
    }

    if (dartScore >= 3) {
      return const LanguageDetectionResult(
        language: 'Dart',
        framework: 'Flutter',
        confidence: 0.95,
        detectedKeywords: ['Widget', 'Flutter'],
      );
    }

    if (pythonScore >= 3) {
      return LanguageDetectionResult(
        language: 'Python',
        confidence: (pythonScore * 0.2).clamp(0.75, 0.95),
        detectedKeywords: const ['def', 'import'],
      );
    }

    if (tsScore >= 2) {
      return const LanguageDetectionResult(
        language: 'TypeScript',
        confidence: 0.85,
        detectedKeywords: ['interface', 'type'],
      );
    }

    if (jsScore >= 2) {
      return const LanguageDetectionResult(
        language: 'JavaScript',
        confidence: 0.80,
        detectedKeywords: ['const', 'function'],
      );
    }

    return LanguageDetectionResult.unknown();
  }
}
