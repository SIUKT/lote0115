import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final draftNoteProvider =
    StateNotifierProvider<DraftNoteNotifier, DraftNote>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return DraftNoteNotifier(prefs);
});

class DraftNote {
  final String content;
  final String context;
  final String selectedLanguage;
  final List<String> selectedTags;

  DraftNote({
    this.content = '',
    this.context = '',
    this.selectedLanguage = '',
    this.selectedTags = const [],
  });

  DraftNote copyWith({
    String? content,
    String? context,
    String? selectedLanguage,
    List<String>? selectedTags,
  }) {
    return DraftNote(
      content: content ?? this.content,
      context: context ?? this.context,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedTags: selectedTags ?? this.selectedTags,
    );
  }
}

class DraftNoteNotifier extends StateNotifier<DraftNote> {
  final SharedPreferences _prefs;
  static const _keyContent = 'draft_note_content';
  static const _keyContext = 'draft_note_context';
  static const _keyLanguage = 'draft_note_language';
  static const _keyTags = 'draft_note_tags';

  DraftNoteNotifier(this._prefs)
      : super(DraftNote(
          content: _prefs.getString(_keyContent) ?? '',
          context: _prefs.getString(_keyContext) ?? '',
          selectedLanguage: _prefs.getString(_keyLanguage) ?? '',
          selectedTags: _prefs.getStringList(_keyTags) ?? [],
        ));

  void updateContent(String content) {
    _prefs.setString(_keyContent, content);
    state = state.copyWith(content: content);
  }

  void updateContext(String context) {
    _prefs.setString(_keyContext, context);
    state = state.copyWith(context: context);
  }

  void updateLanguage(String language) {
    _prefs.setString(_keyLanguage, language);
    state = state.copyWith(selectedLanguage: language);
  }

  void updateTags(List<String> tags) {
    _prefs.setStringList(_keyTags, tags);
    state = state.copyWith(selectedTags: tags);
  }

  void clearDraft() {
    _prefs.remove(_keyContent);
    _prefs.remove(_keyContext);
    _prefs.remove(_keyTags);
    state = state.copyWith(
      content: '',
      context: '',
      selectedTags: [],
    );
  }
}
