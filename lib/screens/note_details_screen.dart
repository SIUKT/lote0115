import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/providers/user_data_provider.dart';
import 'package:lote0115/screens/immersion_screen.dart';
import 'package:lote0115/widgets/smart_selectable_text.dart';
import 'package:lote0115/providers/note_provider.dart';
import 'package:collection/collection.dart';

class NoteDetailsScreen extends ConsumerWidget {
  final Note note;
  const NoteDetailsScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(noteProvider);
    // 获取最新的note状态
    final currentNote =
        notes.firstWhere((n) => n.id == note.id, orElse: () => note);

    final languages = _getAllLanguages(context, ref, currentNote);
    final translatingNotes = ref.watch(translatingNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: CustomScrollView(
        slivers: [
          _buildContextAndTags(context, currentNote),
          SliverList.builder(
            itemCount: (currentNote.followUps?.length ?? 0) + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildELement(
                  context,
                  ref,
                  currentNote.primaryContent,
                  currentNote.variants ?? [],
                  languages,
                  translatingNotes,
                  isPrimary: true,
                );
              } else if (index == ((currentNote.followUps?.length ?? 0) + 1)) {
                return _AddFollowUpWidget(note: currentNote);
              } else {
                final followUp = currentNote.followUps![index - 1];
                return _buildELement(
                  context,
                  ref,
                  followUp.content ?? '',
                  followUp.variants ?? [],
                  languages,
                  translatingNotes,
                  followUpIndex: index - 1,
                );
              }
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildELement(
      BuildContext context,
      WidgetRef ref,
      String mainContent,
      List<NoteVariant> variants,
      List<String> languages,
      Map<String, String> translatingNotes,
      {bool isPrimary = false,
      int? followUpIndex}) {
    return Theme(
      data: ThemeData().copyWith(
        dividerColor: Colors.transparent, // 移除外框
      ),
      child: InkWell(
        onLongPress: !isPrimary
            ? () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Follow-up'),
                    content: const Text(
                        'Are you sure you want to delete this follow-up?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (followUpIndex != null) {
                            ref
                                .read(noteProvider.notifier)
                                .deleteFollowUp(note, followUpIndex);
                          }
                        },
                        child: Text(
                          'DELETE',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                );
              }
            : null,
        child: ExpansionTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          initiallyExpanded: true, // 默认展开
          tilePadding: EdgeInsets.zero, // 移除内边距
          showTrailingIcon: false,
          title: SizedBox(
            width: 45,
            child: Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      note.primaryLanguage.toUpperCase(),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      mainContent,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          children: [
            ...languages
                .where((language) => language != note.primaryLanguage)
                .map((language) {
              final variant = variants.firstWhereOrNull(
                (v) => v.language?.toLowerCase() == language.toLowerCase(),
              );
              final isCurrentLanguageTranslating =
                  translatingNotes[mainContent] == language;
              return InkWell(
                onTap: variant == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ImmersionScreen(
                              note: note,
                              language: language,
                            ),
                          ),
                        ),
                onLongPress: () => print('long pressed'),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 8, bottom: 8, right: 12), // 与标题保持一致的上间距
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 45,
                        child: Center(
                          child: Text(
                            language.toUpperCase(),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                      if (variant == null && !isCurrentLanguageTranslating)
                        GestureDetector(
                          onTap: () {
                            print('cccccc');
                            final noteIndex =
                                ref.read(noteProvider).indexOf(note);
                            final notes = ref.read(noteProvider);
                            print('notes: ${notes.map((n) => n.id)}');
                            print('note: ${note.toJson()}');
                            print('noteIndex: $noteIndex');
                            if (noteIndex != -1) {
                              if (isPrimary) {
                                print('nbbbbb');
                                ref
                                    .read(noteProvider.notifier)
                                    .switchVariant(note, language);
                              } else {
                                print('aaaaa');
                                final followUpIndex = ref
                                    .read(noteProvider)
                                    .firstWhere((n) => n.id == note.id)
                                    .followUps!
                                    .indexWhere(
                                        (f) => f.content == mainContent);
                                ref
                                    .read(noteProvider.notifier)
                                    .generateFollowUpVariant(
                                        note, followUpIndex, language);
                              }
                            }
                          },
                          child: Text(
                            '生成',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        )
                      else if (isCurrentLanguageTranslating)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      if (variant != null || isCurrentLanguageTranslating) ...[
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final notes = ref.watch(noteProvider);
                              final currentNote = notes.firstWhere(
                                (n) => n.id == note.id,
                                orElse: () => note,
                              );
                              final currentVariant =
                                  currentNote.variants?.firstWhereOrNull(
                                (v) =>
                                    v.language?.toLowerCase() ==
                                    language.toLowerCase(),
                              );
                              return Text(currentVariant?.content ?? '');
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            })
          ],
        ),
      ),
    );
  }

  List<String> _getAllLanguages(
      BuildContext context, WidgetRef ref, Note note) {
    final userData = ref.watch(userDataProvider);
    final userLanguages = userData?.languages ?? [];
    final variants = note.variants ?? [];
    final translatingNotes = ref.watch(translatingNotesProvider);

    // 创建一个包含所有语言的列表
    final allLanguages = {...userLanguages};
    for (var variant in variants) {
      if (variant.language != null) {
        allLanguages.add(variant.language!.toLowerCase());
      }
    }

    // 将语言列表转换为列表并排序
    final sortedLanguages = allLanguages.toList()
      ..sort((a, b) {
        final aInUserLanguages = userLanguages.contains(a);
        final bInUserLanguages = userLanguages.contains(b);
        if (aInUserLanguages && !bInUserLanguages) return -1;
        if (!aInUserLanguages && bInUserLanguages) return 1;
        final aIndex = userLanguages.indexOf(a);
        final bIndex = userLanguages.indexOf(b);
        if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
        return a.compareTo(b);
      });

    // 把primary language移到最前面
    final primaryLanguage = note.primaryLanguage.toLowerCase();
    if (primaryLanguage.isNotEmpty &&
        sortedLanguages.contains(primaryLanguage)) {
      sortedLanguages.remove(primaryLanguage);
      sortedLanguages.insert(0, primaryLanguage);
    }
    return sortedLanguages;
  }

  Widget _buildAllLanguages(BuildContext context, WidgetRef ref, Note note) {
    final userData = ref.watch(userDataProvider);
    final userLanguages = userData?.languages ?? [];
    final variants = note.variants ?? [];
    final translatingNotes = ref.watch(translatingNotesProvider);

    // 创建一个包含所有语言的列表
    final allLanguages = {...userLanguages};
    for (var variant in variants) {
      if (variant.language != null) {
        allLanguages.add(variant.language!.toLowerCase());
      }
    }

    // 将语言列表转换为列表并排序
    final sortedLanguages = allLanguages.toList()
      ..sort((a, b) {
        final aInUserLanguages = userLanguages.contains(a);
        final bInUserLanguages = userLanguages.contains(b);
        if (aInUserLanguages && !bInUserLanguages) return -1;
        if (!aInUserLanguages && bInUserLanguages) return 1;
        final aIndex = userLanguages.indexOf(a);
        final bIndex = userLanguages.indexOf(b);
        if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
        return a.compareTo(b);
      });

    // 把primary language移到最前面
    final primaryLanguage = note.primaryLanguage.toLowerCase();
    if (primaryLanguage.isNotEmpty &&
        sortedLanguages.contains(primaryLanguage)) {
      sortedLanguages.remove(primaryLanguage);
      sortedLanguages.insert(0, primaryLanguage);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final language = sortedLanguages[index];
          final variant = variants.firstWhereOrNull(
            (v) => v.language?.toLowerCase() == language.toLowerCase(),
          );
          final isUserLanguage = userLanguages.contains(language);
          final isCurrentLanguageTranslating =
              translatingNotes[note.primaryContent] == language;

          return InkWell(
            onTap: () {
              if (variant != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImmersionScreen(
                      note: note,
                      language: language,
                    ),
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        language.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isUserLanguage
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(width: 12),
                      if (variant == null && !isCurrentLanguageTranslating)
                        GestureDetector(
                          onTap: () {
                            final noteIndex =
                                ref.read(noteProvider).indexOf(note);
                            if (noteIndex != -1) {
                              ref
                                  .read(noteProvider.notifier)
                                  .switchVariant(note, language);
                            }
                          },
                          child: Text(
                            '生成'.toUpperCase(),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        )
                      else if (isCurrentLanguageTranslating)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  if (variant != null || isCurrentLanguageTranslating) ...[
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final notes = ref.watch(noteProvider);
                          final currentNote = notes.firstWhere(
                            (n) => n.id == note.id,
                            orElse: () => note,
                          );
                          final currentVariant =
                              currentNote.variants?.firstWhereOrNull(
                            (v) =>
                                v.language?.toLowerCase() ==
                                language.toLowerCase(),
                          );
                          return Text(currentVariant?.content ?? '');
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        childCount: sortedLanguages.length,
      ),
    );
  }

  Widget _buildContextAndTags(BuildContext context, Note note) {
    final hasContext = note.context != null && note.context!.isNotEmpty;
    final hasTags = note.tags != null && note.tags!.isNotEmpty;

    if (!hasContext && !hasTags) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasContext) ...[
              Text(
                'Context',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              SmartSelectableText(
                text: note.context!,
                language: note.language,
              ),
              if (hasTags) const SizedBox(height: 16),
            ],
            if (hasTags) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: note.tags!.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddFollowUpWidget extends ConsumerStatefulWidget {
  final Note note;

  const _AddFollowUpWidget({required this.note});

  @override
  _AddFollowUpWidgetState createState() => _AddFollowUpWidgetState();
}

class _AddFollowUpWidgetState extends ConsumerState<_AddFollowUpWidget> {
  bool _isEditing = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    _focusNode.requestFocus();
  }

  void _submitContent() {
    if (_controller.text.trim().isNotEmpty) {
      ref
          .read(noteProvider.notifier)
          .addFollowUp(widget.note, _controller.text.trim());
      _controller.clear();
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return InkWell(
        onTap: _startEditing,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Follow-up',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Enter follow-up content',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submitContent(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitContent,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _controller.clear();
              setState(() {
                _isEditing = false;
              });
            },
          ),
        ],
      ),
    );
  }
}
