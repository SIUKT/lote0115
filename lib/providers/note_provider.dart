import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/providers/isar_provider.dart';
import 'package:lote0115/providers/user_data_provider.dart';
import 'package:lote0115/services/ai_service.dart';
import 'package:lote0115/services/isar_service.dart';

final noteProvider = StateNotifierProvider<NoteNotifier, List<Note>>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return NoteNotifier(isarService, ref);
});

// Provider for tracking notes that are currently being translated
final translatingNotesProvider = StateProvider<Map<int, String>>((ref) => {});

class NoteNotifier extends StateNotifier<List<Note>> {
  final IsarService isarService;
  final Ref ref;

  NoteNotifier(this.isarService, this.ref) : super([]) {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    state = (await isarService.getNotes()).reversed.toList();
  }

  Future<void> addNote({
    required String content,
    required String language,
    String? context,
    List<String>? tags,
  }) async {
    final note = Note()
      ..variants = [
        NoteVariant()
          ..language = language
          ..content = content
          ..isPrimary = true
          ..isCurrent = true,
      ]
      ..context = context
      ..tags = tags;

    await isarService.saveNote(note);
    await _loadNotes();
  }

  Future<void> regenerateVariant(Note note, String language) async {
    final noteIndex = state.indexWhere((n) => n.id == note.id);
    if (noteIndex == -1) return;

    final variants = List<NoteVariant>.from(note.variants ?? []);
    final targetVariant = variants.firstWhere((v) => v.language == language);
    targetVariant.content = '重新翻译中...';
    await isarService.saveNote(note);
    state = [
      ...state.sublist(0, noteIndex),
      note,
      ...state.sublist(noteIndex + 1),
    ];
    await streamTranslation(note, language, noteIndex);
  }

  Future<void> switchVariant(Note note, String language) async {
    final noteIndex = state.indexWhere((n) => n.id == note.id);
    if (noteIndex == -1) return;

    final variants = List<NoteVariant>.from(note.variants ?? []);
    final existingVariant =
        variants.where((v) => v.language == language).firstOrNull;

    // If variant doesn't exist, create a placeholder and start translation
    if (existingVariant == null) {
      final newVariant = NoteVariant()
        ..language = language
        ..content = '翻译中...'
        ..isCurrent = true;

      variants.add(newVariant);

      // Update all variants' isCurrent status
      for (var variant in variants) {
        variant.isCurrent = variant.language == language;
      }

      // Update note in database and state
      final updatedNote = note..variants = variants;
      await isarService.saveNote(updatedNote);
      state = [
        ...state.sublist(0, noteIndex),
        updatedNote,
        ...state.sublist(noteIndex + 1),
      ];

      await streamTranslation(note, language, noteIndex);
    } else {
      // Variant exists, just switch to it
      for (var variant in variants) {
        variant.isCurrent = variant.language == language;
      }

      final updatedNote = note..variants = variants;
      await isarService.saveNote(updatedNote);
      state = [
        ...state.sublist(0, noteIndex),
        updatedNote,
        ...state.sublist(noteIndex + 1),
      ];
    }
  }

  Future<void> updateNote(
    Note note, {
    required String content,
    required String language,
    String? context,
    List<String>? tags,
  }) async {
    note.updatedAt = DateTime.now();
    note.context = context;
    note.tags = tags;

    final variants = List<NoteVariant>.from(note.variants ?? []);
    if (note.language != language) {
      variants.removeWhere((v) => v.language == language);
    }
    final currentVariant =
        variants.firstWhere((v) => v.language == note.language);
    currentVariant
      ..content = content
      ..language = language;

    note.variants = variants;
    await isarService.saveNote(note);
    await _loadNotes();
  }

  Future<void> updateNoteQnA(Note note) async {
    final noteIndex = state.indexWhere((n) => n.id == note.id);
    if (noteIndex == -1) return;

    // Update note in database
    await isarService.saveNote(note);

    // Update note in state
    state = [
      ...state.sublist(0, noteIndex),
      note,
      ...state.sublist(noteIndex + 1),
    ];
  }

  Future<void> streamTranslation(
      Note note, String language, int noteIndex) async {
    // Start streaming translation
    ref.read(translatingNotesProvider.notifier).state = {
      ...ref.read(translatingNotesProvider),
      note.id: language,
    };

    final aiService = ref.read(aiServiceProvider);
    String translatedContent = '';

    // 创建一个新的 Note 实例来存储流式更新
    final streamingNote = Note.fromJson(note.toJson());
    final streamingVariant = streamingNote.variants!.firstWhere(
      (v) => v.language == language,
    );

    try {
      await for (final chunk in aiService.getTranslation(
        note.context,
        note.primaryContent,
        note.primaryLanguage,
        language,
      )) {
        translatedContent += chunk;
        streamingVariant.content = translatedContent;

        // 更新状态，但保持相同的Note实例
        state = [
          ...state.sublist(0, noteIndex),
          streamingNote,
          ...state.sublist(noteIndex + 1),
        ];
      }

      // 翻译完成后，更新原始note并保存到数据库
      final originalVariant = note.variants!.firstWhere(
        (v) => v.language == language,
      );
      originalVariant.content = translatedContent;
      await isarService.saveNote(note);

      // 从翻译中列表移除
      ref.read(translatingNotesProvider.notifier).state = {
        ...ref.read(translatingNotesProvider)..remove(note.id),
      };
    } catch (e) {
      // 发生错误时，从翻译中列表移除
      ref.read(translatingNotesProvider.notifier).state = {
        ...ref.read(translatingNotesProvider)..remove(note.id),
      };
      rethrow;
    }
  }

  Future<void> deleteNote(Note note) async {
    // Get index before removing from state
    final noteIndex = state.indexWhere((n) => n.id == note.id);
    if (noteIndex == -1) return;

    // Remove note from state
    state = [
      ...state.sublist(0, noteIndex),
      ...state.sublist(noteIndex + 1),
    ];

    // Find tags that are unique to this note
    final noteTags = note.tags ?? [];
    final otherNotesTags = state
        .where((n) => n.id != note.id)
        .expand((n) => n.tags ?? [])
        .toSet()
        .toList();

    final uniqueTags = noteTags.where((tag) => !otherNotesTags.contains(tag));

    // If there are unique tags, remove them from UserData
    if (uniqueTags.isNotEmpty) {
      final userData = ref.read(userDataProvider);
      if (userData != null) {
        final updatedTags =
            userData.tags?.where((tag) => !uniqueTags.contains(tag)).toList() ??
                [];
        ref.read(userDataProvider.notifier).updateTags(updatedTags);
      }
    }

    // Delete note from database
    await isarService.deleteNote(note);
    await removeEmptyTags();
  }

  Future<void> removeEmptyTags() async {
    final userData = ref.read(userDataProvider);
    if (userData == null) return;

    final originalTags = List<String>.from(userData.tags ?? []);

    // 检查tags的notes是否为空
    final notes = await isarService.getNotes();
    // final notesWithTags =
    //     notes.where((n) => n.tags?.isNotEmpty ?? false).toList();
    final existingTags = notes.expand((n) => n.tags ?? []).toSet().toList();
    print('fucking existingTags: $existingTags');

    // final updatedTags =
    //     tags.where((tag) => originalTags.contains(tag)).toList() ?? [];
    originalTags.retainWhere((tag) => existingTags.contains(tag));
    print('fucking updatedTags: $originalTags');
    ref.read(userDataProvider.notifier).updateTags(originalTags);
  }
}
