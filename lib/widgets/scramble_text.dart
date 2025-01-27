import 'package:flutter/material.dart';
import 'package:lote0115/services/tokenizer/tokenizer_service.dart';
import 'package:reorderables/reorderables.dart';
import 'dart:math' show pi, cos, sin;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tokenizer_provider.dart';

class ScrambleText extends ConsumerStatefulWidget {
  final String sentence;
  final String? translation;
  final List<String> collocations;
  final String language;
  final Function(bool)? onCheckResult;

  const ScrambleText({
    super.key,
    required this.sentence,
    this.translation,
    required this.collocations,
    required this.language,
    this.onCheckResult,
  });

  @override
  ConsumerState<ScrambleText> createState() => _ScrambleTextState();
}

class _ScrambleTextState extends ConsumerState<ScrambleText>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  List<String> _elements = []; // Initialize with empty list
  List<String> _originalElements = []; // Initialize with empty list
  bool? _isCorrect;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late final TokenizerService tokenizer;

  @override
  void initState() {
    super.initState();
    tokenizer = ref.read(tokenizerProvider);
    _initializeElements();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    // if (widget.elem.respondedAt != null && widget.elem.isUserWrong != true) {
    _animationController.value = 1.0;
    // }
  }

  void _initializeElements() async {
    _originalElements =
        (await tokenizer.tokenize(widget.sentence, widget.language));
    for (var e in _originalElements) {
      // 去掉/n
      // e = e.replaceAll('\n', '');
      print('e: $e');
    }
    setState(() {
      _elements = List.from(_originalElements)..shuffle();
      _isCorrect = null;
    });
  }

  List<String> _extractElements(String sentence, List<String> collocations) {
    List<String> elements = [];
    String workingSentence = sentence;
    int currentPosition = 0;

    while (currentPosition < workingSentence.length) {
      // 尝试在当前位置匹配词组
      bool foundCollocation = false;
      for (String collocation in collocations) {
        if (workingSentence
            .substring(currentPosition)
            .trimLeft()
            .startsWith(collocation)) {
          elements.add(collocation);
          currentPosition +=
              workingSentence.substring(currentPosition).indexOf(collocation) +
                  collocation.length;
          foundCollocation = true;
          break;
        }
      }

      // 如果没有找到词组，处理单个单词
      if (!foundCollocation) {
        // 跳过开头的空格
        while (currentPosition < workingSentence.length &&
            workingSentence[currentPosition].trim().isEmpty) {
          currentPosition++;
        }

        if (currentPosition < workingSentence.length) {
          // 找到下一个空格或句子结尾
          int nextSpace = workingSentence.indexOf(' ', currentPosition);
          if (nextSpace == -1) nextSpace = workingSentence.length;

          String word =
              workingSentence.substring(currentPosition, nextSpace).trim();
          if (word.isNotEmpty) {
            elements.add(word);
          }
          currentPosition = nextSpace + 1;
        }
      }
    }

    return elements;
  }

  void _checkOrder() {
    bool isMatch = _compareElements();

    if (isMatch && _isCorrect != true) {
      setState(() {
        _isCorrect = true;
      });

      // 播放动画
      _animationController.forward();

      // 更新 elem 的响应状态
      widget.onCheckResult?.call(true);
    }
  }

  bool _compareElements() {
    // 首先检查长度是否一致
    if (_elements.length != _originalElements.length) return false;

    // 创建一个临时字符串来重建句子
    String reconstructedSentence = _elements.join(' ');
    String originalSentence = _originalElements.join(' ');

    print('reconstructedSentence: $reconstructedSentence');
    print('originalSentence: $originalSentence');

    // 直接比较重建的句子和原始句子
    return reconstructedSentence == originalSentence;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.translation != null)
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade50,
                      Colors.blue.shade100.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade100,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.translation!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              margin:
                  const EdgeInsets.only(top: 0, bottom: 16), // 增加底部边距，为按钮留出空间
              // decoration: BoxDecoration(
              //   color: Colors.grey.shade50,
              //   borderRadius: BorderRadius.circular(12),
              //   border: Border.all(
              //     color: Colors.grey.shade200,
              //     width: 1,
              //   ),
              // ),
              child: ReorderableWrap(
                controller: _scrollController,
                spacing: 8.0,
                runSpacing: 12.0,
                padding: const EdgeInsets.all(16),
                needsLongPressDraggable: false,
                buildDraggableFeedback: (context, constraints, child) {
                  return Material(
                    elevation: 8.0,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: constraints,
                      child: child,
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  if (_isCorrect != true) {
                    // 添加检查，只有未完成时才允许重排序
                    setState(() {
                      final element = _elements.removeAt(oldIndex);
                      _elements.insert(newIndex, element);
                      _checkOrder(); // 每次重新排序后自动检查
                    });
                  }
                },
                children: List.generate(_elements.length, (index) {
                  return AnimatedContainer(
                    key: ValueKey(_elements[index]),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    child: DragTarget<int>(
                      onWillAccept: (data) =>
                          (_isCorrect ?? false) == false &&
                          data != null &&
                          data != index,
                      onAccept: (draggedIndex) {
                        if (_isCorrect != true) {
                          setState(() {
                            final temp = _elements[index];
                            _elements[index] = _elements[draggedIndex];
                            _elements[draggedIndex] = temp;
                            _checkOrder();
                          });
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return _buildWordCard(
                          _elements[index],
                          _isCorrect ?? false,
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),

        // 添加庆祝动画层
        if (_isCorrect == true && _animationController.isAnimating)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  // 发光效果
                  Opacity(
                    opacity: (1 - _animation.value).clamp(0, 0.3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // 星星动画
                  ...List.generate(6, (index) {
                    final angle = index * (pi / 3);
                    return Positioned(
                      left: MediaQuery.of(context).size.width / 2 +
                          cos(angle) * 100 * _animation.value,
                      top: MediaQuery.of(context).size.height / 2 +
                          sin(angle) * 100 * _animation.value,
                      child: Opacity(
                        opacity: (1 - _animation.value).clamp(0, 1),
                        child: Transform.scale(
                          scale: 1 + _animation.value,
                          child: const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildWordCard(String word, bool isCorrect) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color:
              isCorrect ? Colors.green.shade300 : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        word,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.2,
          color: isCorrect ? Colors.green.shade700 : Colors.black87,
        ),
      ),
    );
  }
}
