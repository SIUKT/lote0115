import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/models/note.dart';
import 'package:lote0115/screens/primary_details_screen.dart';
import 'package:lote0115/widgets/smart_selectable_text.dart';
import 'package:lote0115/services/ai_service.dart';
import 'package:lote0115/providers/note_provider.dart';
import 'package:lote0115/widgets/qna_section.dart';
import 'package:lote0115/services/tts/tts_service.dart';
import 'package:lote0115/providers/tts_provider.dart';

class NoteDetailsScreen extends ConsumerStatefulWidget {
  final Note note;
  final String? language;

  const NoteDetailsScreen({super.key, required this.note, this.language});

  @override
  ConsumerState<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends ConsumerState<NoteDetailsScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  String _streamOutput = '';
  bool _isLoading = false;
  String? _pendingQuestion;
  bool _isQuestion = true;
  late final NoteVariant? currentVariant;
  bool _isExpanded = true;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  late String speakingLanguage;

  @override
  void initState() {
    super.initState();
    if (widget.language != null) {
      currentVariant = widget.note.variants
          ?.firstWhere((v) => v.language == widget.language);
      speakingLanguage = widget.language!;
    } else {
      currentVariant =
          widget.note.variants?.firstWhere((v) => v.isCurrent == true);
      speakingLanguage = currentVariant!.language!;
    }
    print('==============currentVariant: ${currentVariant!.content}');
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation =
        Tween<double>(begin: 0, end: 0.5).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutCubic,
    ));
    if (!_isExpanded) {
      _rotationController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _handleQuestionSave(QnA qna, String newQuestion) async {
    setState(() {});
    // final currentVariant =
    //     widget.note.variants?.firstWhere((v) => v.isCurrent == true);

    if (currentVariant != null) {
      // 更新问题
      qna.question = newQuestion;

      // 保存更新到数据库
      await ref.read(noteProvider.notifier).updateNoteQnA(widget.note);
    }
  }

  void _handleQuestionRegenerate(QnA qna, String newQuestion) async {
    // final currentVariant =
    //     widget.note.variants?.firstWhere((v) => v.isCurrent == true);

    if (currentVariant != null) {
      // 先找到要删除的QnA在列表中的位置
      final qnaIndex = currentVariant!.qnas?.indexOf(qna) ?? -1;
      if (qnaIndex == -1) return; // 如果找不到原QnA，直接返回

      // 从列表中移除原QnA
      final qnas = List<QnA>.from(currentVariant!.qnas ?? []);
      qnas.removeAt(qnaIndex);
      currentVariant!.qnas = qnas;

      setState(() {
        _isLoading = true;
        _streamOutput = '';
        _pendingQuestion = newQuestion;
        _isQuestion = qna.isQuestion ?? true;
      });

      try {
        final aiService = ref.read(aiServiceProvider);
        final stream = qna.isQuestion ?? true
            ? aiService.getAnswer(
                widget.note.context,
                widget.note.primaryContent,
                currentVariant!.content!,
                widget.note.primaryLanguage,
                currentVariant!.language!,
                newQuestion,
                [
                  ...currentVariant!.qnas
                          ?.map((q) => {
                                'question': q.question,
                                'answer': q.answer,
                              })
                          .toList() ??
                      []
                ],
              )
            : aiService.getTranslation(widget.note.context, newQuestion,
                widget.note.primaryLanguage, currentVariant!.language!);

        await for (final chunk in stream) {
          if (mounted) {
            setState(() {
              _streamOutput += chunk;
            });
          }
        }

        if (mounted) {
          // 创建新的QnA并插入到原来的位置
          final newQnA = QnA()
            ..question = newQuestion
            ..answer = _streamOutput
            ..isQuestion = qna.isQuestion;

          qnas.insert(qnaIndex, newQnA);
          currentVariant!.qnas = qnas;

          // 保存更新到数据库
          await ref.read(noteProvider.notifier).updateNoteQnA(widget.note);

          setState(() {
            _isLoading = false;
            _pendingQuestion = null;
            _streamOutput = '';
          });
        }
      } catch (e) {
        if (mounted) {
          // 发生错误时恢复原QnA
          qnas.insert(qnaIndex, qna);
          currentVariant!.qnas = qnas;

          setState(() {
            _isLoading = false;
            _pendingQuestion = null;
            _streamOutput = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _submitQuestion(String question, bool isQuestion) async {
    if (question.isEmpty) return;

    if (currentVariant != null) {
      final qna = QnA()
        ..question = question
        ..answer = ''
        ..isQuestion = isQuestion;

      setState(() {
        _isLoading = true;
        _streamOutput = '';
        _pendingQuestion = question;
        _isQuestion = isQuestion;
      });

      try {
        final aiService = ref.read(aiServiceProvider);
        final stream = isQuestion
            ? aiService.getAnswer(
                widget.note.context,
                widget.note.primaryContent,
                currentVariant!.content!,
                widget.note.primaryLanguage,
                currentVariant!.language!,
                question,
                [
                  ...currentVariant!.qnas?.map((q) => {
                            'question': q.question,
                            'answer': q.answer,
                          }) ??
                      []
                ],
              )
            : aiService.getTranslation(
                widget.note.context,
                question,
                widget.note.primaryLanguage,
                currentVariant!.language!,
              );

        await for (final chunk in stream) {
          if (mounted) {
            setState(() {
              _streamOutput += chunk;
            });
          }
        }

        if (mounted) {
          // 准备数据
          qna.answer = _streamOutput;

          // 先清除 pending 状态
          setState(() {
            _isLoading = false;
            _pendingQuestion = null;
            _streamOutput = '';
          });

          // 等待下一帧，确保 pending item 已经消失
          await Future.microtask(() {});

          // 然后添加新的 QnA 并保存
          if (mounted) {
            currentVariant!.qnas = [...currentVariant!.qnas ?? [], qna];
            await ref.read(noteProvider.notifier).updateNoteQnA(widget.note);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _pendingQuestion = null;
            _streamOutput = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

    void _openRandomNote(List<Note> notes) {
    if (notes.isEmpty) return;

    // Collect all variants except the primary one from each note
    List<(Note, NoteVariant)> allVariants = [];
    for (var note in notes) {
      if (note.variants != null) {
        for (var variant in note.variants!) {
          if (!(variant.isPrimary == true)) {
            allVariants.add((note, variant));
          }
        }
      }
    }

    if (allVariants.isEmpty) return;

    // Get a random variant
    final random = Random();
    final randomPair = allVariants[random.nextInt(allVariants.length)];

    Widget destination = NoteDetailsScreen(
      note: randomPair.$1,
      language: randomPair.$2.language,
    );

    // Navigate to note details screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => destination,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tts = ref.read(ttsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionChip(
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              label: Text(
                widget.note.primaryLanguage.toUpperCase(),
                style: TextStyle(
                    color: speakingLanguage == widget.note.primaryLanguage
                        ? Colors.white
                        : null),
              ),
              backgroundColor: speakingLanguage == widget.note.primaryLanguage
                  ? Theme.of(context).primaryColor
                  : null,
              onPressed: () {
                if (speakingLanguage != widget.note.primaryLanguage) {
                  setState(() {
                    speakingLanguage = widget.note.primaryLanguage;
                  });
                } else {
                  tts.speak(widget.note.primaryContent, speakingLanguage);
                }
              },
            ),
            if (widget.note.primaryLanguage != currentVariant!.language) ...[
              const SizedBox(width: 8),
              ActionChip(
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                label: Text(
                  currentVariant!.language!.toUpperCase(),
                  style: TextStyle(
                      color: speakingLanguage == currentVariant!.language
                          ? Colors.white
                          : null),
                ),
                backgroundColor: speakingLanguage == currentVariant!.language
                    ? Theme.of(context).primaryColor
                    : null,
                onPressed: () {
                  if (speakingLanguage != currentVariant!.language) {
                    setState(() {
                      speakingLanguage = currentVariant!.language!;
                    });
                  } else {
                    tts.speak(currentVariant!.content!, speakingLanguage);
                  }
                },
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border_outlined),
            onPressed: () {
              final notes = ref.read(noteProvider);
              _openRandomNote(notes);
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrimaryDetailsScreen(
                    note: widget.note,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            currentVariant == null
                ? const Center(child: CircularProgressIndicator())
                : QnASection(
                    qnas: currentVariant!.qnas ?? [],
                    pendingQuestion: _pendingQuestion,
                    streamOutput: _streamOutput,
                    isQuestion: _isQuestion,
                    isLoading: _isLoading,
                    onQuestionSave: _handleQuestionSave,
                    onQuestionRegenerate: _handleQuestionRegenerate,
                    onSubmit: _submitQuestion,
                    primaryLanguage: widget.note.primaryLanguage,
                    language: speakingLanguage,
                  ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  elevation: 0,
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.95),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      constraints: BoxConstraints(
                        maxHeight: _isExpanded
                            ? MediaQuery.of(context).size.height * 0.6
                            : 56,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 展开/收起按钮区域
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                              if (_isExpanded) {
                                _rotationController.forward();
                              } else {
                                _rotationController.reverse();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    currentVariant!.createdAt
                                        .toString()
                                        .split('.')
                                        .first,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                  RotationTransition(
                                    turns: _rotationAnimation,
                                    child: Icon(
                                      Icons.expand_more,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 分隔线
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _isExpanded ? 1.0 : 0.0,
                            child: Container(
                              height: 1,
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.1),
                            ),
                          ),
                          // 内容区域
                          if (_isExpanded)
                            Flexible(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: _isExpanded ? 1.0 : 0.0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget.note.context != null &&
                                          widget.note.context!.isNotEmpty) ...[
                                        Text(
                                          widget.note.context!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.left,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      if (currentVariant!.content! !=
                                          widget.note.primaryContent) ...[
                                        SmartSelectableText(
                                          text: widget.note.primaryContent,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant),
                                          language: widget.note.primaryLanguage,
                                          onWordTap: (word) {
                                            debugPrint('Tapped word: $word');
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      SmartSelectableText(
                                        text: currentVariant!.content!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                        language: currentVariant!.language!,
                                        onWordTap: (word) {
                                          debugPrint('Tapped word: $word');
                                        },
                                      ),
                                      if (widget.note.tags != null &&
                                          widget.note.tags!.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: widget.note.tags!
                                              .map(
                                                (tag) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    '#$tag',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
