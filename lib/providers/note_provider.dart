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
final translatingNotesProvider =
    StateProvider<Map<String, String>>((ref) => {});

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

  Future<void> addFollowUp(Note note, String content) async {
    final followUp = FollowUp()
      ..content = content
      ..variants = [
        NoteVariant()
          ..language = note.primaryLanguage
          ..content = content
          ..isPrimary = true
          ..isCurrent = true
      ];
    note.followUps = List<FollowUp>.from(note.followUps ?? [])..add(followUp);
    await isarService.saveNote(note);
    await _loadNotes();
  }

  Future<void> deleteFollowUp(Note note, int followUpIndex) async {
    if (note.followUps != null && followUpIndex < note.followUps!.length) {
      note.followUps = List<FollowUp>.from(note.followUps!)
        ..removeAt(followUpIndex);
      await isarService.saveNote(note);
      await _loadNotes();
    }
  }

  Future<void> generateFollowUpVariant(
      Note note, int followUpIndex, String language) async {
    final noteIndex = state.indexWhere((n) => n.id == note.id);
    if (noteIndex == -1) return;
    final followUp = note.followUps![followUpIndex];
    if (followUp.variants == null) return;

    final variants = List<NoteVariant>.from(followUp.variants ?? []);

    // If variant doesn't exist, create a placeholder and start translation
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
    final updatedNote = note..followUps![followUpIndex].variants = variants;
    await isarService.saveNote(updatedNote);
    state = [
      ...state.sublist(0, noteIndex),
      updatedNote,
      ...state.sublist(noteIndex + 1),
    ];

    await streamTranslation(note, language, noteIndex,
        followUpIndex: followUpIndex);
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

  Future<void> streamTranslation(Note note, String language, int noteIndex,
      {int? followUpIndex}) async {
    final isFollowUp = followUpIndex != null;
    final contentToTranslate = isFollowUp
        ? note.followUps![followUpIndex].content!
        : note.primaryContent;

    // Start streaming translation
    ref.read(translatingNotesProvider.notifier).state = {
      ...ref.read(translatingNotesProvider),
      contentToTranslate: language,
    };

    final aiService = ref.read(aiServiceProvider);
    String translatedContent = '';

    // Create a new Note instance for streaming updates
    final streamingNote = Note.fromJson(note.toJson());
    final streamingVariant = isFollowUp
        ? streamingNote.followUps![followUpIndex].variants!.firstWhere(
            (v) => v.language == language,
            orElse: () {
              final newVariant = NoteVariant()
                ..language = language
                ..content = ''
                ..isPrimary = false
                ..isCurrent = false;
              streamingNote.followUps![followUpIndex].variants ??= [];
              streamingNote.followUps![followUpIndex].variants!.add(newVariant);
              return newVariant;
            },
          )
        : streamingNote.variants!.firstWhere(
            (v) => v.language == language,
          );

    try {
      await for (final chunk in aiService.getTranslation(
        note.context,
        contentToTranslate,
        note.primaryLanguage, // For followUps we don't track primary language
        language,
      )) {
        translatedContent += chunk;
        streamingVariant.content = translatedContent;

        // Update state while keeping the same Note instance
        state = [
          ...state.sublist(0, noteIndex),
          streamingNote,
          ...state.sublist(noteIndex + 1),
        ];
      }

      // After translation is complete, update original note and save to database
      if (isFollowUp) {
        final originalVariant =
            note.followUps![followUpIndex].variants!.firstWhere(
          (v) => v.language == language,
          orElse: () {
            final newVariant = NoteVariant()
              ..language = language
              ..content = translatedContent
              ..isPrimary = false
              ..isCurrent = false;
            note.followUps![followUpIndex].variants ??= [];
            note.followUps![followUpIndex].variants!.add(newVariant);
            return newVariant;
          },
        );
        originalVariant.content = translatedContent;
      } else {
        final originalVariant = note.variants!.firstWhere(
          (v) => v.language == language,
        );
        originalVariant.content = translatedContent;
      }
      await isarService.saveNote(note);

      // Remove from translating list
      ref.read(translatingNotesProvider.notifier).state = {
        ...ref.read(translatingNotesProvider)..remove(contentToTranslate),
      };
    } catch (e) {
      // Remove from translating list on error
      ref.read(translatingNotesProvider.notifier).state = {
        ...ref.read(translatingNotesProvider)..remove(contentToTranslate),
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
