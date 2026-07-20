import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../modules/ocr/ocr_provider.dart';
import '../modules/editor/editor_state.dart';
import '../modules/sharing/share_service.dart';

/// MOD-04 / MOD-05 / MOD-06 / MOD-07 / MOD-08 — Interactive Code Editor Screen
/// Includes live text editing, search & replace bar, Undo/Redo stack,
/// Word Wrap toggle, Language Badge, and Android Share Sheet integration.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _showCleaned = true;
  bool _showSearchBar = false;
  late TextEditingController _codeController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _searchController = TextEditingController();

    // Initialize editor text on post frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ocrState = ref.read(ocrProvider);
      final initialText = ocrState.finalCode;
      _codeController.text = initialText;
      ref.read(editorProvider.notifier).setText(initialText);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrProvider);
    final editorState = ref.watch(editorProvider);

    final detection = ocrState.detectionResult;
    final cleanup = ocrState.cleanupResult;

    final lines = editorState.text.split('\n');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimaryDark, size: 20),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Row(
          children: [
            const Text(
              'Code Editor',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            // MOD-05 Language & Framework badge
            _LanguageChip(
              label: detection?.displayName ?? 'Plain Text',
              confidencePct: ((detection?.confidence ?? 0.0) * 100).round(),
            ),
          ],
        ),
        actions: [
          // MOD-08 Share Action
          IconButton(
            key: const Key('btn_editor_share_action'),
            icon: const Icon(Icons.share_rounded, color: AppColors.accent, size: 20),
            onPressed: () async {
              final success = await ShareService.instance.shareCode(
                editorState.text,
                languageDisplayName: detection?.displayName,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.surfaceDark,
                    behavior: SnackBarBehavior.floating,
                    content: Text('Share Sheet opened successfully',
                        style: TextStyle(color: AppColors.textPrimaryDark)),
                  ),
                );
              }
            },
          ),
          IconButton(
            key: const Key('btn_editor_copy_action'),
            icon: const Icon(Icons.copy_rounded, color: AppColors.textSecondaryDark, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: editorState.text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  content: const Text('Copied code to clipboard!',
                      style: TextStyle(color: AppColors.textPrimaryDark)),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderDark),
        ),
      ),
      body: Column(
        children: [
          // Search Bar overlay
          if (_showSearchBar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceDark,
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search text in code...',
                        hintStyle: TextStyle(color: AppColors.textMutedDark),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) =>
                          ref.read(editorProvider.notifier).setSearchQuery(val),
                    ),
                  ),
                  if (editorState.searchQuery.isNotEmpty)
                    Text(
                      '${editorState.searchMatchLineIndexes.length} matches',
                      style: const TextStyle(color: AppColors.accent, fontSize: 11),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMutedDark, size: 18),
                    onPressed: () {
                      setState(() => _showSearchBar = false);
                      _searchController.clear();
                      ref.read(editorProvider.notifier).setSearchQuery('');
                    },
                  ),
                ],
              ),
            ),

          // Header Banner (Cleaned vs Raw switch)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.cardDark,
            child: Row(
              children: [
                Icon(
                  _showCleaned ? Icons.auto_fix_high_rounded : Icons.raw_on_rounded,
                  size: 16,
                  color: _showCleaned ? AppColors.accent : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _showCleaned
                        ? '${lines.length} lines • ${cleanup?.lineNumbersRemovedCount ?? 0} line numbers stripped'
                        : 'Showing Raw OCR Output (${lines.length} lines)',
                    style: const TextStyle(
                        color: AppColors.textSecondaryDark, fontSize: 12),
                  ),
                ),
                Text(
                  'Cleaned',
                  style: TextStyle(
                    color: _showCleaned ? AppColors.accent : AppColors.textMutedDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch(
                  key: const Key('switch_cleaned_toggle'),
                  value: _showCleaned,
                  onChanged: (val) {
                    setState(() => _showCleaned = val);
                    final newText = val
                        ? (ocrState.finalCode)
                        : (ocrState.rawResult?.rawText ?? '');
                    _codeController.text = newText;
                    ref.read(editorProvider.notifier).setText(newText);
                  },
                  activeColor: AppColors.accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          // Interactive Code Editing View
          Expanded(
            child: Container(
              color: AppColors.backgroundDark,
              child: SingleChildScrollView(
                scrollDirection: editorState.isWordWrapEnabled ? Axis.vertical : Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: editorState.isWordWrapEnabled ? MediaQuery.of(context).size.width - 32 : 800,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(lines.length, (index) {
                      final isUncertain = _showCleaned &&
                          (cleanup?.lowConfidenceLineIndexes.contains(index) ?? false);
                      final isSearchMatch = editorState.searchMatchLineIndexes.contains(index);

                      return _CodeLineRow(
                        lineNum: index + 1,
                        code: lines[index],
                        isUncertain: isUncertain,
                        isSearchMatch: isSearchMatch,
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Editor Action Toolbar
          _EditorBottomBar(
            canUndo: editorState.canUndo,
            canRedo: editorState.canRedo,
            isWordWrap: editorState.isWordWrapEnabled,
            onUndo: () {
              ref.read(editorProvider.notifier).undo();
              _codeController.text = ref.read(editorProvider).text;
            },
            onRedo: () {
              ref.read(editorProvider.notifier).redo();
              _codeController.text = ref.read(editorProvider).text;
            },
            onSearch: () => setState(() => _showSearchBar = !_showSearchBar),
            onToggleWrap: () => ref.read(editorProvider.notifier).toggleWordWrap(),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final int confidencePct;

  const _LanguageChip({
    required this.label,
    required this.confidencePct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.codePurple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.codePurple.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB995FF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (confidencePct > 0) ...[
            const SizedBox(width: 4),
            Text(
              '$confidencePct%',
              style: TextStyle(
                color: AppColors.accent.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CodeLineRow extends StatelessWidget {
  final int lineNum;
  final String code;
  final bool isUncertain;
  final bool isSearchMatch;

  const _CodeLineRow({
    required this.lineNum,
    required this.code,
    this.isUncertain = false,
    this.isSearchMatch = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: isSearchMatch
            ? AppColors.accentGlow
            : isUncertain
                ? AppColors.warningGlow.withOpacity(0.15)
                : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$lineNum',
              style: const TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              code,
              style: TextStyle(
                color: isSearchMatch
                    ? AppColors.accent
                    : isUncertain
                        ? AppColors.warning
                        : AppColors.textPrimaryDark,
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          if (isUncertain)
            const Tooltip(
              message: 'Check syntax (possible OCR misreading)',
              child: Icon(Icons.warning_amber_rounded,
                  size: 14, color: AppColors.warning),
            ),
        ],
      ),
    );
  }
}

class _EditorBottomBar extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final bool isWordWrap;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onSearch;
  final VoidCallback onToggleWrap;

  const _EditorBottomBar({
    required this.canUndo,
    required this.canRedo,
    required this.isWordWrap,
    required this.onUndo,
    required this.onRedo,
    required this.onSearch,
    required this.onToggleWrap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            enabled: canUndo,
            onTap: onUndo,
          ),
          _ActionButton(
            icon: Icons.redo_rounded,
            label: 'Redo',
            enabled: canRedo,
            onTap: onRedo,
          ),
          _ActionButton(
            icon: Icons.search_rounded,
            label: 'Search',
            enabled: true,
            onTap: onSearch,
          ),
          _ActionButton(
            icon: Icons.wrap_text_rounded,
            label: isWordWrap ? 'Wrap On' : 'Wrap Off',
            enabled: true,
            onTap: onToggleWrap,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondaryDark, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
