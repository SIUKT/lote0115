import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/providers/note_provider.dart';
import 'package:lote0115/providers/user_data_provider.dart';
import 'package:lote0115/providers/shared_prefs_provider.dart';

class NoteInputSheet extends ConsumerStatefulWidget {
  final Note? note;
  const NoteInputSheet({super.key, this.note});

  @override
  ConsumerState<NoteInputSheet> createState() => _NoteInputSheetState();
}

class _NoteInputSheetState extends ConsumerState<NoteInputSheet> {
  final _contentController = TextEditingController();
  final _contextController = TextEditingController();
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _layerLink = LayerLink();
  final _tagFocusNode = FocusNode();
  List<String> _selectedTags = [];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _tagController.addListener(_onTagInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.note != null) {
        // If editing existing note, load its content
        _contentController.text = widget.note!.content;
        _contextController.text = widget.note!.context ?? '';
        _selectedTags = List<String>.from(widget.note!.tags ?? []);
      } else {
        // If creating new note, load draft
        final draft = ref.read(draftNoteProvider);
        _contentController.text = draft.content;
        _contextController.text = draft.context;
        _selectedTags = List<String>.from(draft.selectedTags);
      }
    });
  }

  @override
  void dispose() {
    _tagController.removeListener(_onTagInputChanged);
    _tagController.dispose();
    _contentController.dispose();
    _contextController.dispose();
    _tagFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTagInputChanged() {
    _removeOverlay();
    if (_tagController.text.isNotEmpty) {
      _showTagSuggestions();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showTagSuggestions() {
    final userData = ref.read(userDataProvider);
    final allTags = userData?.tags ?? [];
    final input = _tagController.text.toLowerCase();
    final suggestions =
        allTags.where((tag) => tag.toLowerCase().contains(input)).toList();
    if (!suggestions.any((tag) => tag.toLowerCase() == input)) {
      suggestions.add('添加：${_tagController.text}');
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 80, // 缩小宽度
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 16), // 调整偏移量，使其更靠近触发点
          child: Material(
            elevation: 2, // 减少阴影
            borderRadius: BorderRadius.circular(4), // 减少圆角
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120), // 缩小最大高度
              child: ListView.builder(
                padding: EdgeInsets.zero, // 移除 ListView 的内边距
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => _addTag(
                      suggestions[index].startsWith('添加')
                          ? suggestions[index].substring(3)
                          : suggestions[index],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ), // 最小化内边距
                      alignment: Alignment.centerLeft,
                      child: Text(
                        suggestions[index],
                        style: const TextStyle(fontSize: 12), // 减小字体大小
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty) {
      setState(() {
        _selectedTags.add(tag);
      });
      if (widget.note == null &&
          !ref.read(draftNoteProvider).selectedTags.contains(tag)) {
        final newTags =
            List<String>.from(ref.read(draftNoteProvider).selectedTags)
              ..add(tag);
        ref.read(draftNoteProvider.notifier).updateTags(newTags);
      }

      _tagController.clear();
      // Keep focus and don't hide input
      _tagFocusNode.requestFocus();
    }
  }

  // Calculate language frequencies from notes
  Map<String, int> _calculateLanguageFrequencies() {
    final notes = ref.read(noteProvider);
    final frequencies = <String, int>{};

    for (final note in notes) {
      final primaryLang = note.primaryLanguage;
      frequencies[primaryLang] = (frequencies[primaryLang] ?? 0) + 1;
    }

    return frequencies;
  }

  // Get sorted language buttons based on frequency
  List<Widget> _getLanguageButtons() {
    final frequencies = _calculateLanguageFrequencies();
    final userData = ref.read(userDataProvider);
    if (userData == null) return [];

    // Sort languages by frequency
    final sortedLanguages = userData.languages.toList()
      ..sort((a, b) => (frequencies[b] ?? 0).compareTo(frequencies[a] ?? 0));

    // Create buttons list
    final buttons = <Widget>[];
    final maxFreq =
        frequencies.values.fold(1, (max, freq) => freq > max ? freq : max);

    final double height = widget.note == null ? 50 : 40;

    // Add top 4 languages as direct buttons (second most frequent first)
    for (var i = min(3, sortedLanguages.length - 1);
        i >= 0 && i < sortedLanguages.length;
        i--) {
      buttons.add(const SizedBox(width: 8));

      final lang = sortedLanguages[i];
      final freq = frequencies[lang] ?? 0;
      final width = 60.0 +
          (freq / maxFreq) * 90.0; // Width between 60-100 based on frequency

      buttons.add(
        Expanded(
          flex: width.toInt(),
          child: SizedBox(
            width: width,
            height: height,
            child: ElevatedButton(
              onPressed: _contentController.text.trim().isNotEmpty
                  ? () => _submitNote(lang)
                  : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(mapValue(width, 60, 150, 0.6, 1.0)),
                // .withBlue((150 - width).toInt())
                // backgroundColor:
                //     Color(0xff8ace00).withBlue((150 - width).toInt()),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(lang.toUpperCase()),
            ),
          ),
        ),
      );
    }

    // Insert more button (leftmost)
    if (sortedLanguages.length > 4) {
      buttons.insert(
        0,
        SizedBox(
          width: 50,
          height: height,
          child: PopupMenuButton<String>(
            enabled: _contentController.text.isNotEmpty,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _contentController.text.isNotEmpty
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.more_horiz,
                color: _contentController.text.isNotEmpty
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
            onSelected: (String lang) => _submitNote(lang),
            itemBuilder: (BuildContext context) {
              return sortedLanguages.sublist(4).map((String lang) {
                return PopupMenuItem<String>(
                  value: lang,
                  child: Text(lang.toUpperCase()),
                );
              }).toList();
            },
          ),
        ),
      );
    } else {
      buttons.removeAt(0);
    }

    return buttons;
  }

  double mapValue(double value, double fromMin, double fromMax, double toMin,
      double toMax) {
    return (value - fromMin) * (toMax - toMin) / (fromMax - fromMin) + toMin;
  }

  // Submit note with selected language
  Future<void> _submitNote(String language) async {
    if (widget.note == null) {
      if (_formKey.currentState!.validate()) {
        ref.read(noteProvider.notifier).addNote(
              content: _contentController.text,
              context: _contextController.text,
              language: language,
              tags: ref.read(draftNoteProvider).selectedTags,
            );
        ref
            .read(userDataProvider.notifier)
            .addTags(ref.read(draftNoteProvider).selectedTags);
        ref.read(draftNoteProvider.notifier).clearDraft();
        Navigator.pop(context);
      }
    } else {
      _submitEdit(language);
    }
  }

  void _submitEdit(String? language) {
    if (!_formKey.currentState!.validate()) return;

    final content = _contentController.text;
    final theContext =
        _contextController.text.isEmpty ? null : _contextController.text;
    final tags = _selectedTags;

    // Update existing note
    ref.read(noteProvider.notifier).updateNote(
          widget.note!,
          content: content,
          language: language ?? widget.note!.language,
          context: theContext,
          tags: tags,
        );
    if (_selectedTags.isNotEmpty) {
      print('fucking _selectedTags: $_selectedTags');
      ref.read(userDataProvider.notifier).addTags(_selectedTags);
    }
    ref.read(noteProvider.notifier).removeEmptyTags();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final draft = ref.watch(draftNoteProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Input Area
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), // 外框颜色
                borderRadius: BorderRadius.circular(12), // 外框圆角
              ),
              child: Padding(
                padding: const EdgeInsets.all(12), // 减少内边距
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Context Input
                    TextFormField(
                      controller: _contextController,
                      style: TextStyle(
                        height: 1,
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        hintText: '添加语境...', // 将 labelText 改为 hintText
                        hintStyle: TextStyle(
                          height: 1,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        border: InputBorder.none, // 取消边框
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 0), // 减少内边距
                        isDense: true, // 紧凑模式
                      ),
                      maxLines: 2,
                      minLines: 1,
                      onChanged: (value) {
                        if (widget.note == null) {
                          ref
                              .read(draftNoteProvider.notifier)
                              .updateContext(value);
                        }
                      },
                    ),
                    // const SizedBox(height: 4), // 减少两个输入框之间的间距
                    // Content Input
                    TextFormField(
                      controller: _contentController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '写点什么...', // 将 labelText 改为 hintText
                        hintStyle: TextStyle(
                          height: 1,
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        border: InputBorder.none, // 取消边框
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8), // 减少内边距
                        isDense: true, // 紧凑模式
                      ),
                      minLines: 2,
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter content';
                        }
                        return null;
                      },
                      onChanged: (value) async {
                        if (widget.note == null) {
                          ref
                              .read(draftNoteProvider.notifier)
                              .updateContent(value);
                        }
                      },
                    ),
                    // const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0, // 标签之间的水平间距
                      runSpacing: 4.0, // 标签之间的垂直间距
                      children: [
                        // 框内标签列表
                        ..._selectedTags.map((tag) => GestureDetector(
                              onTap: () {
                                // 点击 Text 触发操作
                                setState(() {
                                  _selectedTags.remove(tag);
                                  // ref
                                  //     .read(userDataProvider.notifier)
                                  //     .removeTags([tag]);
                                });
                                if (widget.note == null) {
                                  final newTags =
                                      List<String>.from(draft.selectedTags)
                                        ..remove(tag);
                                  ref
                                      .read(draftNoteProvider.notifier)
                                      .updateTags(newTags);
                                }
                              },
                              child: Text(
                                '#$tag',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            )),
                        // 输入框
                        ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 500), // 限制输入框的最大宽度
                          child: CompositedTransformTarget(
                            link: _layerLink,
                            child: TextFormField(
                              controller: _tagController,
                              focusNode: _tagFocusNode,
                              autofocus: true,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                              decoration: const InputDecoration(
                                hintText: '添加标签...',
                                hintStyle: TextStyle(
                                  height: 0.76,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 0,
                                ),
                                border: InputBorder.none, // 无边框
                              ),
                              onFieldSubmitted: (value) {
                                _addTag(value);
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tags Section
            Row(
              children: [
                // const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...(userData?.tags ?? []).map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              showCheckmark: false,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              label: Text(
                                tag.length > 4
                                    ? '${tag.substring(0, 4)}...'
                                    : tag,
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                final newTags =
                                    List<String>.from(draft.selectedTags);
                                if (selected) {
                                  newTags.add(tag);
                                  _selectedTags.add(tag);
                                } else {
                                  newTags.remove(tag);
                                  _selectedTags.remove(tag);
                                }
                                setState(() {});
                                print('newTags2: $newTags');
                                if (widget.note == null) {
                                  ref
                                      .read(draftNoteProvider.notifier)
                                      .updateTags(newTags);
                                } else {
                                  print('selectedTags: ${_selectedTags}');
                                  // ref
                                  //     .read(userDataProvider.notifier)
                                  //     .updateTags(_selectedTags);
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Submit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _getLanguageButtons(),
            ),
            const SizedBox(height: 8),
            if (widget.note != null)
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _contentController.text.trim().isNotEmpty
                            ? () => _submitEdit(null)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          // backgroundColor:
                          //     Color(0xff8ace00).withBlue((150 - width).toInt()),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('保存'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
