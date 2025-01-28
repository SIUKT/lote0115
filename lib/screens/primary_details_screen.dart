import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/providers/user_data_provider.dart';
import 'package:lote0115/screens/note_details_screen.dart';
import 'package:lote0115/widgets/smart_selectable_text.dart';
import 'package:lote0115/providers/note_provider.dart';
import 'package:collection/collection.dart';

class PrimaryDetailsScreen extends ConsumerWidget {
  final Note note;
  const PrimaryDetailsScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(noteProvider);
    // 获取最新的note状态
    final currentNote =
        notes.firstWhere((n) => n.id == note.id, orElse: () => note);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: CustomScrollView(
        slivers: [
          _buildContextAndTags(context, currentNote),
          _buildAllLanguages(context, ref, currentNote),
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final language = sortedLanguages[index];
          final variant = variants.firstWhereOrNull(
            (v) => v.language?.toLowerCase() == language.toLowerCase(),
          );
          final isUserLanguage = userLanguages.contains(language);
          final isCurrentLanguageTranslating =
              translatingNotes[note.id] == language;

          return InkWell(
            onTap: () {
              if ( variant != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteDetailsScreen(
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
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
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
                      if (variant?.isPrimary == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.star,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      const Spacer(),
                      if (variant == null && !isCurrentLanguageTranslating)
                        TextButton(
                          onPressed: () {
                            final noteIndex =
                                ref.read(noteProvider).indexOf(note);
                            if (noteIndex != -1) {
                              ref
                                  .read(noteProvider.notifier)
                                  .switchVariant(note, language);
                            }
                          },
                          child: Text('Translate'.toUpperCase()),
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
                    const SizedBox(height: 4),
                    Consumer(
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
                        // return SmartSelectableText(
                        //   text: currentVariant?.content ?? '',
                        //   language: language,
                        // );
                        return Text(currentVariant?.content ?? '');
                      },
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
              color: Theme.of(context).dividerColor.withOpacity(0.1),
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
              // Text(
              //   'Tags',
              //   style: Theme.of(context).textTheme.titleSmall?.copyWith(
              //         color: Theme.of(context).colorScheme.primary,
              //       ),
              // ),
              // const SizedBox(height: 4),
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
                          .withOpacity(0.5),
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
