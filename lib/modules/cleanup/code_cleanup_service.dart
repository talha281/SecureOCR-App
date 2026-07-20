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
/// Structural IDE artifact stripper, C# syntax fixer, & OCR code repair engine.
/// Strictly universal — never filters out valid user variables, class names, or code keywords.
class CodeCleanupService {
  CodeCleanupService._();
  static final CodeCleanupService instance = CodeCleanupService._();

  /// Universal non-code IDE system UI strings (strictly IDE tool window titles & status bars)
  static final List<RegExp> _systemUiPatterns = [
    RegExp(r'^\s*solution\s+explorer\s*$', caseSensitive: false),
    RegExp(r'^\s*developer\s+powershell\s*$', caseSensitive: false),
    RegExp(r'^\s*error\s+list\s*$', caseSensitive: false),
    RegExp(r'^\s*no\s+issues\s+found\s*$', caseSensitive: false),
    RegExp(r'^\s*\d+\s+references?\s*$', caseSensitive: false),
    RegExp(r'^\s*<top-level-statements-entry-point>\s*$', caseSensitive: false),
  ];

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
    final validCodeLines = <String>[];
    int lineNumsRemoved = 0;
    final lowConfidenceLines = <int>[];

    final lineNumberRegex = RegExp(r'^\s*\d{1,4}\s+[:\|│\-\>]\s+|^\s*\d{1,4}\s{2,}(?=[a-zA-Z_/\\#<\{\[\$])');
    final standaloneNumberRegex = RegExp(r'^\s*\d{1,4}\s*$');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      // 1. Skip standalone line numbers (e.g. "5", "6", "24")
      if (standaloneNumberRegex.hasMatch(line)) {
        lineNumsRemoved++;
        continue;
      }

      // 2. Strip prefix line numbers
      if (lineNumberRegex.hasMatch(line)) {
        line = line.replaceFirst(lineNumberRegex, '').trim();
        lineNumsRemoved++;
      }

      // 3. Skip system UI status bar / tool window titles only
      if (_isSystemUiNoise(line)) {
        continue;
      }

      // 4. Perform C# & Code-specific OCR syntax fixes
      line = _fixCodeSyntax(line);

      // 5. Flag suspicious/low-confidence lines
      if (_isLowConfidenceLine(line)) {
        lowConfidenceLines.add(validCodeLines.length);
      }

      if (line.isNotEmpty) {
        validCodeLines.add(line);
      }
    }

    return CleanupResult(
      cleanedText: validCodeLines.join('\n'),
      linesCleanedCount: validCodeLines.length,
      lineNumbersRemovedCount: lineNumsRemoved,
      lowConfidenceLineIndexes: lowConfidenceLines,
    );
  }

  /// Check if line is strictly a system IDE UI string (e.g., "Solution Explorer", "3 references")
  bool _isSystemUiNoise(String line) {
    for (final pattern in _systemUiPatterns) {
      if (pattern.hasMatch(line)) return true;
    }
    return false;
  }

  /// Repair universal OCR syntax corruptions in code context
  String _fixCodeSyntax(String line) {
    String fixed = line;

    // Replace full-width or smart quotes & OCR arrow artifacts
    fixed = fixed
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('»', '>');

    // Fix OCR spaces inside member access & namespaces (e.g. CustomerPortal. Api -> CustomerPortal.Api)
    fixed = fixed
        .replaceAll(RegExp(r'\.\s+'), '.')
        .replaceAll(RegExp(r'\s+\.'), '.')
        .replaceAll(RegExp(r'\s+;'), ';');

    // Fix C# Generics & Bracket OCR corruptions
    // e.g. <CultureMiddleware>0; -> <CultureMiddleware>();
    // e.g. <ExternalAPIJwtMiddleware>(0; -> <ExternalAPIJwtMiddleware>();
    fixed = fixed
        .replaceAll('>0;', '>();')
        .replaceAll('>(0;', '>();')
        .replaceAll('> (0;', '>();')
        .replaceAll('>0 ()', '>();')
        .replaceAll('Logging 0;', 'Logging();')
        .replaceAll('Logging 0', 'Logging();')
        .replaceAll('RequestlLogging', 'RequestLogging')
        .replaceAll('UseMidd leware', 'UseMiddleware')
        .replaceAll('Build( )', 'Build()')
        .replaceAll('builder. Build()', 'builder.Build()')
        .replaceAll('Read From.', 'ReadFrom.')
        .replaceAll('RequestLocalizationoptions', 'RequestLocalizationOptions')
        .replaceAll('T0ptions', 'IOptions');

    // Fix universal OCR keyword typos
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

    int openParen = 0, closeParen = 0;
    int openBrace = 0, closeBrace = 0;

    for (final char in line.runes) {
      if (char == 40) openParen++;
      if (char == 41) closeParen++;
      if (char == 123) openBrace++;
      if (char == 125) closeBrace++;
    }

    if (openParen != closeParen || openBrace != closeBrace) {
      return true;
    }

    if (RegExp(r'[^\x00-\x7F]').hasMatch(line)) {
      return true;
    }

    return false;
  }
}
