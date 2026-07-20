/// MOD-06 — Cleanup Result Model
class CleanupResult {
  final String cleanedText;
  final int linesCleanedCount;
  final int lineNumbersRemovedCount;
  final List<int> lowConfidenceLineIndexes;

  const CleanupResult({
    required this.cleanedText,
    required this.linesCleanedCount,
    required this.lineNumbersRemovedCount,
    this.lowConfidenceLineIndexes = const [],
  });
}

/// MOD-06 — Code Cleanup & Post-Processing Service
/// Intelligent cleanup pipeline: strips IDE line numbers, gutter noise,
/// fixes common OCR typos in code context, and flags uncertain lines.
class CodeCleanupService {
  CodeCleanupService._();
  static final CodeCleanupService instance = CodeCleanupService._();

  /// Main cleanup function
  CleanupResult clean(String rawText) {
    if (rawText.trim().isEmpty) {
      return const CleanupResult(
        cleanedText: '',
        linesCleanedCount: 0,
        lineNumbersRemovedCount: 0,
      );
    }

    final lines = rawText.split('\n');
    final cleanedLines = <String>[];
    int lineNumsRemoved = 0;
    final lowConfidenceLines = <int>[];

    // Regex patterns for line numbers & IDE gutter artifacts
    // Matches "1  ", " 12 | ", " 100: ", "10 -> " (strictly line numbers with gutter padding/separators)
    final lineNumberRegex = RegExp(r'^\s*\d{1,4}\s+[:\|│\-\>]\s+|^\s*\d{1,4}\s{2,}(?=[a-zA-Z_/\\#<\{\[\$])');
    // Matches gutter noise characters like "• ", "· ", "► ", "v "
    final gutterNoiseRegex = RegExp(r'^\s*[•·►v>]\s*');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // 1. Strip IDE line numbers
      if (lineNumberRegex.hasMatch(line)) {
        line = line.replaceFirst(lineNumberRegex, '');
        lineNumsRemoved++;
      }

      // 2. Strip IDE gutter noise
      if (gutterNoiseRegex.hasMatch(line)) {
        line = line.replaceFirst(gutterNoiseRegex, '');
      }

      // 3. Fix OCR code typos
      line = _fixCodeTypos(line);

      // 4. Flag suspicious/low-confidence lines (unbalanced brackets, unusual symbols)
      if (_isLowConfidenceLine(line)) {
        lowConfidenceLines.add(i);
      }

      cleanedLines.add(line);
    }

    return CleanupResult(
      cleanedText: cleanedLines.join('\n'),
      linesCleanedCount: cleanedLines.length,
      lineNumbersRemovedCount: lineNumsRemoved,
      lowConfidenceLineIndexes: lowConfidenceLines,
    );
  }

  /// Fix common OCR substitutions in code context
  String _fixCodeTypos(String line) {
    String fixed = line;

    // Replace full-width or smart quotes with standard code quotes
    fixed = fixed
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");

    // Replace common OCR keyword misreadings
    // "public" -> "public", "fnction" -> "function", "c1ass" -> "class"
    fixed = fixed
        .replaceAll(RegExp(r'\bpublic\b'), 'public')
        .replaceAll(RegExp(r'\bc1ass\b'), 'class')
        .replaceAll(RegExp(r'\bfnction\b'), 'function')
        .replaceAll(RegExp(r'\bStrmg\b'), 'String')
        .replaceAll(RegExp(r'\bStnng\b'), 'String');

    return fixed;
  }

  /// Check if line contains probable OCR artifacts or bracket imbalance
  bool _isLowConfidenceLine(String line) {
    if (line.trim().isEmpty) return false;

    // Check bracket balance
    int openParen = 0, closeParen = 0;
    int openBrace = 0, closeBrace = 0;

    for (final char in line.runes) {
      if (char == 40) openParen++; // (
      if (char == 41) closeParen++; // )
      if (char == 123) openBrace++; // {
      if (char == 125) closeBrace++; // }
    }

    if (openParen != closeParen || openBrace != closeBrace) {
      return true;
    }

    // Check for weird non-ASCII OCR noise
    if (RegExp(r'[^\x00-\x7F]').hasMatch(line)) {
      return true;
    }

    return false;
  }
}
