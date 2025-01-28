import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/providers/note_provider.dart';
import 'package:lote0115/providers/tts_provider.dart';
import 'package:lote0115/screens/note_details_screen.dart';
import 'package:lote0115/screens/primary_details_screen.dart';
import 'package:lote0115/widgets/note_input_sheet.dart';
import 'dart:ui' as ui;

class NoteItem extends ConsumerWidget {
  final Note note;
  final List<String> languages;
  final String searchQuery;

  NoteItem({
    super.key,
    required this.note,
    required List<String> languages,
    this.searchQuery = '',
  }) : languages = List.unmodifiable(languages);

  Widget _highlightText(
      BuildContext context, String text, String query, TextStyle style) {
    return HighlightedText(
      text: text,
      query: query,
      style: style,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.read(ttsServiceProvider);
    List<String> matchedLanguages = const [];
    if (searchQuery.isNotEmpty) {
      matchedLanguages = note.variants
              ?.where((variant) {
                return variant.content
                        ?.toLowerCase()
                        .contains(searchQuery.toLowerCase()) ??
                    false;
              })
              .map((variant) => variant.language) // 提取 language 字段
              .cast<String>() // 将 `String?` 转换为 `String`
              .toList() ??
          []; // 如果 note.variants 为 null，返回空列表
      debugPrint('matchedLanguages: $matchedLanguages');
    }

    return Card(
      elevation: 0,
      // margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      margin: const EdgeInsets.all(0),
      // clip splash
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            // await tts.speak(note.content, note.language);
            // navigate to note details screen
            if (note.language == note.primaryLanguage) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrimaryDetailsScreen(note: note),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetailsScreen(note: note),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          onLongPress: () {
            showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.content_copy),
                      title: const Text('复制内容'),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: note.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('内容已复制'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('编辑内容'),
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          builder: (context) => NoteInputSheet(note: note),
                        );
                      },
                    ),
                    if (note.primaryLanguage != note.language)
                      ListTile(
                        leading: const Icon(Icons.refresh),
                        title: const Text('重新生成翻译'),
                        onTap: () {
                          Navigator.pop(context);
                          ref
                              .read(noteProvider.notifier)
                              .regenerateVariant(note, note.language);
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title:
                          const Text('删除', style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('确认删除'),
                              content: const Text('你确定要删除该笔记吗？'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('删除'),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm) {
                          ref.read(noteProvider.notifier).deleteNote(note);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('笔记已删除')),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('yy/M/dd HH:mm:ss').format(note.createdAt!),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: languages.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 2),
                        itemBuilder: (context, index) {
                          final language = languages[index];

                          final isCurrentLanguage = note.language == language;
                          final isTranslating =
                              ref.watch(translatingNotesProvider)[note.id] ==
                                  language;
                          final hasTranslation = note.variants?.any(
                                  (variant) => variant.language == language) ??
                              false;
                          final int? qnasCount = note.variants
                              ?.where(
                                (variant) => variant.language == language,
                              )
                              .firstOrNull
                              ?.qnas
                              ?.length;
                          return Stack(
                            children: [
                              ActionChip(
                                side: matchedLanguages.isNotEmpty &&
                                        matchedLanguages.contains(language)
                                    ? const BorderSide(
                                        color: Colors.amber, width: 2)
                                    : BorderSide.none,
                                label: Text(
                                  language.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: matchedLanguages.isNotEmpty &&
                                            matchedLanguages.contains(language)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrentLanguage
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : !hasTranslation
                                            // ? Theme.of(context)
                                            //     .colorScheme
                                            //     .primary
                                            ? Colors.grey[500]
                                            : null,
                                  ),
                                ),
                                backgroundColor: isCurrentLanguage
                                    ? Theme.of(context).colorScheme.primary
                                    : !hasTranslation
                                        ? Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                avatar: isTranslating
                                    ? SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: isCurrentLanguage
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                        ),
                                      )
                                    : null,
                                onPressed: () async {
                                  if (!isCurrentLanguage) {
                                    ref
                                        .read(noteProvider.notifier)
                                        .switchVariant(note, language);
                                  } else {
                                    await tts.speak(
                                        note.content, note.language);
                                  }
                                },
                              ),
                              if (qnasCount != null && qnasCount > 0)
                                Positioned(
                                  top: 3,
                                  right: 8,
                                  child: Text(
                                    qnasCount.toString(),
                                    style: TextStyle(
                                      fontSize: 6,
                                      color: isCurrentLanguage
                                          ? Colors.white
                                          : null,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (note.context != null && note.context!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _highlightText(
                    context,
                    note.context!,
                    searchQuery,
                    Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.grey[600],
                        ),
                  )
                ],
                const SizedBox(height: 4),
                ExpandableText(
                  parentContext: context,
                  text: note.content,
                  searchQuery: searchQuery,
                  style: const TextStyle(color: Colors.black87),
                ),
                if (note.tags != null && note.tags!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: note.tags!.map((tag) {
                      return _highlightText(
                        context,
                        '#$tag',
                        searchQuery,
                        Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      );
                    }).toList(),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExpandableText extends StatefulWidget {
  final BuildContext parentContext;
  final String text;
  final String searchQuery;
  final TextStyle style;

  const ExpandableText({
    super.key,
    required this.parentContext,
    required this.text,
    required this.searchQuery,
    required this.style,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;
  bool _hasOverflow = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          children: _buildHighlightedSpans(
            widget.text,
            widget.searchQuery,
            widget.style,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
          maxLines: 5,
        );

        textPainter.layout(maxWidth: constraints.maxWidth);
        _hasOverflow = textPainter.didExceedMaxLines;

        if (!_hasOverflow) {
          return RichText(text: textSpan);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              maxLines: _isExpanded ? null : 5,
              overflow:
                  _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              text: textSpan,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _isExpanded ? '收起' : '展开',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<TextSpan> _buildHighlightedSpans(
    String text,
    String query,
    TextStyle style,
  ) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    final matches = query.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    List<TextSpan> spans = [];
    int start = 0;

    for (Match match in matches) {
      if (match.start != start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: style,
        ));
      }

      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style.copyWith(
          backgroundColor:
              Theme.of(widget.parentContext).primaryColor.withOpacity(0.2),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = match.end;
    }

    if (start != text.length) {
      spans.add(TextSpan(
        text: text.substring(start, text.length),
        style: style,
      ));
    }

    return spans;
  }
}

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: style.copyWith(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: spans,
      ),
    );
  }
}
