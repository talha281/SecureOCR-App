import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MOD-07 — Editor State
/// Manages live text content, undo/redo history, search queries & highlights.
class EditorState {
  final String text;
  final List<String> undoStack;
  final List<String> redoStack;
  final String searchQuery;
  final List<int> searchMatchLineIndexes;
  final bool isWordWrapEnabled;

  const EditorState({
    required this.text,
    this.undoStack = const [],
    this.redoStack = const [],
    this.searchQuery = '',
    this.searchMatchLineIndexes = const [],
    this.isWordWrapEnabled = true,
  });

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  bool get isSearching => searchQuery.isNotEmpty;

  EditorState copyWith({
    String? text,
    List<String>? undoStack,
    List<String>? redoStack,
    String? searchQuery,
    List<int>? searchMatchLineIndexes,
    bool? isWordWrapEnabled,
  }) {
    return EditorState(
      text: text ?? this.text,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      searchQuery: searchQuery ?? this.searchQuery,
      searchMatchLineIndexes: searchMatchLineIndexes ?? this.searchMatchLineIndexes,
      isWordWrapEnabled: isWordWrapEnabled ?? this.isWordWrapEnabled,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState(text: ''));

  void setText(String initialText) {
    state = EditorState(text: initialText);
  }

  void updateText(String newText) {
    if (newText == state.text) return;

    final newUndo = [...state.undoStack, state.text];
    state = state.copyWith(
      text: newText,
      undoStack: newUndo,
      redoStack: const [], // Clear redo on new user typing
    );

    _updateSearchMatches(state.searchQuery);
  }

  void undo() {
    if (!state.canUndo) return;
    final previousText = state.undoStack.last;
    final newUndo = state.undoStack.sublist(0, state.undoStack.length - 1);
    final newRedo = [...state.redoStack, state.text];

    state = state.copyWith(
      text: previousText,
      undoStack: newUndo,
      redoStack: newRedo,
    );
  }

  void redo() {
    if (!state.canRedo) return;
    final nextText = state.redoStack.last;
    final newRedo = state.redoStack.sublist(0, state.redoStack.length - 1);
    final newUndo = [...state.undoStack, state.text];

    state = state.copyWith(
      text: nextText,
      undoStack: newUndo,
      redoStack: newRedo,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _updateSearchMatches(query);
  }

  void toggleWordWrap() {
    state = state.copyWith(isWordWrapEnabled: !state.isWordWrapEnabled);
  }

  void _updateSearchMatches(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchMatchLineIndexes: const []);
      return;
    }

    final lines = state.text.split('\n');
    final matches = <int>[];
    final lowerQuery = query.toLowerCase();

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(lowerQuery)) {
        matches.add(i);
      }
    }

    state = state.copyWith(searchMatchLineIndexes: matches);
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});
