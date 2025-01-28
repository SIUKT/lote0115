import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lote0115/models/note.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/providers/tts_provider.dart';
import 'package:lote0115/services/tts/tts_service.dart';

class QnASection extends ConsumerStatefulWidget {
  final List<QnA> qnas;
  final String? pendingQuestion;
  final String streamOutput;
  final bool isQuestion;
  final bool isLoading;
  final Function(QnA qna, String newQuestion)? onQuestionSave;
  final Function(QnA qna, String newQuestion)? onQuestionRegenerate;
  final Function(String question, bool isQuestion)? onSubmit;
  final String primaryLanguage;
  final String language;

  const QnASection({
    super.key,
    required this.qnas,
    this.pendingQuestion,
    required this.streamOutput,
    required this.isQuestion,
    required this.isLoading,
    this.onQuestionSave,
    this.onQuestionRegenerate,
    this.onSubmit,
    required this.primaryLanguage,
    required this.language,
  });

  @override
  ConsumerState<QnASection> createState() => _QnASectionState();
}

class _QnASectionState extends ConsumerState<QnASection> {
  final TextEditingController _questionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final bool _isTranslationMode = false;

  @override
  void dispose() {
    _questionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitQuestion({required bool isTranslation}) {
    final question = _questionController.text.trim();
    if (question.isNotEmpty) {
      widget.onSubmit?.call(question, !isTranslation);
      _questionController.clear();
      _focusNode.unfocus();
    }
  }

  void _showInputBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey), // 外框颜色
                          borderRadius: BorderRadius.circular(12), // 外框圆角
                        ),
                        child: TextField(
                          controller: _questionController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: '输入问题...',
                            border: InputBorder.none, // 取消边框
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 0), // 减少内边距
                            isDense: true, // 紧凑模式
                          ),
                          minLines: 1,
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (widget.primaryLanguage != widget.language) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _submitQuestion(isTranslation: true);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                                child: const Text('继续翻译'),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _submitQuestion(isTranslation: false);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('提问'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuestionEditSheet(BuildContext context, String question, QnA qna) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionEditSheet(
        initialQuestion: question,
        qna: qna,
        onQuestionRegenerate: widget.onQuestionRegenerate,
        onQuestionSave: widget.onQuestionSave,
      ),
    );
  }

  void _showAnswerOptionsSheet(BuildContext context, QnA qna) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('复制内容'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: qna.answer ?? ''));
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
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现编辑功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('重新生成'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现重新生成功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现删除功能
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tts = ref.read(ttsServiceProvider);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.fromLTRB(16, 160, 16, 8),
            itemCount:
                widget.qnas.length + (widget.pendingQuestion != null ? 1 : 0),
            itemBuilder: (context, index) {
              // 如果有 pending item，它应该是第一个（在底部）
              if (index == 0 && widget.pendingQuestion != null) {
                return Column(
                  children: [
                    _buildQnAItem(context, tts, widget.language,
                        isPending: true),
                    const SizedBox(height: 16),
                  ],
                );
              } else {
                // 对于其他项，需要减去 pending item 的偏移
                final qnaIndex =
                    widget.pendingQuestion != null ? index - 1 : index;
                final qna = widget.qnas[widget.qnas.length - 1 - qnaIndex];
                return Column(
                  children: [
                    _buildQnAItem(context, tts, widget.language, qna: qna),
                    const SizedBox(height: 16),
                  ],
                );
              }
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            child: InkWell(
              onTap: widget.isLoading ? null : _showInputBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Text(
                      '输入问题...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.send_rounded,
                      color: widget.isLoading
                          ? Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.5)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQnAItem(BuildContext context, TTSService tts, String language,
      {QnA? qna, bool isPending = false}) {
    final question = isPending ? widget.pendingQuestion : qna?.question;
    final answer = isPending ? widget.streamOutput : qna?.answer;
    final isQuestion = isPending ? widget.isQuestion : qna?.isQuestion ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question != null)
          Align(
            alignment:
                isQuestion ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              // onTap: !isPending && qna != null
              //     ? () => _showQuestionEditSheet(context, qna.question!, qna)
              //     : null,
              onTap: () async {
                await tts.speak(question, language);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // edit button small
                  if (!isPending && qna != null)
                    IconButton(
                      onPressed: () =>
                          _showQuestionEditSheet(context, qna.question!, qna),
                      icon: Icon(
                        Icons.edit,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 100,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isQuestion
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomRight: isQuestion
                            ? Radius.zero
                            : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      question,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (answer != null || isPending) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: !isPending && qna != null
                  ? () => _showAnswerOptionsSheet(context, qna)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPending &&
                            widget.isLoading &&
                            widget.streamOutput.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        Flexible(
                          child: SelectableText(
                            onTap: () async {
                              print('Speaking $answer in $language');
                              await tts.speak(answer ?? '', language);
                            },
                            answer ?? '',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start, // 将按钮靠左对齐
                    mainAxisSize: MainAxisSize.min, // 缩小 Row 的宽度
                    crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中对齐
                    children: [
                      IconButton(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {},
                      ),
                      IconButton(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.content_copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: answer ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已复制到剪贴板')),
                          );
                        },
                      ),
                      IconButton(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          // context
                          //     .read(ttsProvider.notifier)
                          //     .generateTTS(qna.question);
                        },
                      ),
                      IconButton(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {},
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuestionEditSheet extends StatefulWidget {
  final String initialQuestion;
  final QnA qna;
  final Function(QnA qna, String newQuestion)? onQuestionRegenerate;
  final Function(QnA qna, String newQuestion)? onQuestionSave;

  const _QuestionEditSheet({
    required this.initialQuestion,
    required this.qna,
    this.onQuestionRegenerate,
    this.onQuestionSave,
  });

  @override
  State<_QuestionEditSheet> createState() => _QuestionEditSheetState();
}

class _QuestionEditSheetState extends State<_QuestionEditSheet> {
  late final TextEditingController controller;
  bool canSubmit = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialQuestion);
    controller.addListener(_updateSubmitState);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _updateSubmitState() {
    final newCanSubmit = controller.text.trim() != widget.initialQuestion;
    if (newCanSubmit != canSubmit) {
      setState(() {
        canSubmit = newCanSubmit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '编辑问题...',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canSubmit
                              ? () {
                                  Navigator.pop(context);
                                  final newQuestion = controller.text.trim();
                                  if (newQuestion.isNotEmpty &&
                                      newQuestion != widget.initialQuestion) {
                                    widget.onQuestionRegenerate
                                        ?.call(widget.qna, newQuestion);
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('重新生成'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final newQuestion = controller.text.trim();
                            if (newQuestion.isNotEmpty &&
                                newQuestion != widget.initialQuestion) {
                              widget.onQuestionSave
                                  ?.call(widget.qna, newQuestion);
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                          child: const Text('仅保存'),
                        ),
                      ),
                    ],
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
