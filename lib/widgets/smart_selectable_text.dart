import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tokenizer_provider.dart';
import '../providers/tts_provider.dart';

class SmartSelectableText extends ConsumerStatefulWidget {
  final String text;
  final TextStyle? style;
  final String language;
  final Function(String word)? onWordTap;

  const SmartSelectableText({
    super.key,
    required this.text,
    this.style,
    required this.language,
    this.onWordTap,
  });

  @override
  ConsumerState<SmartSelectableText> createState() =>
      _SmartSelectableTextState();
}

class _SmartSelectableTextState extends ConsumerState<SmartSelectableText> {
  late List<String> _words; // 分词结果，用于点击选择
  late List<String> _chars; // 单个字符，用于长按选择
  bool _isLoading = true;
  String? _error;
  String? _selectedWord; // 点击选中的词
  TextSelection? _selection; // 长按选择的范围
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _updateWords();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _selectedWord = null;
        _selection = null;
      });
    }
  }

  Future<void> _updateWords() async {
    if (widget.text.isEmpty) {
      setState(() {
        _words = [];
        _chars = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tokenizer = ref.read(tokenizerProvider);
      debugPrint('Starting tokenization for language: ${widget.language}');
      _words = await tokenizer.tokenize(widget.text, widget.language);
      _chars = widget.text.characters.toList(); // 使用 characters 以正确处理 Unicode
      print('Chars: $_chars');
      debugPrint('Tokenization completed. Words: $_words');
    } catch (e) {
      debugPrint('Error in SmartSelectableText: $e');
      setState(() => _error = e.toString());
      if (widget.language.toLowerCase().contains('zh') ||
          widget.language.toLowerCase().contains('ja')) {
        _words = widget.text.split('');
      } else {
        _words = widget.text.split(' ');
      }
      _chars = widget.text.characters.toList();
      print('Error Chars: $_chars');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(SmartSelectableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.language != widget.language) {
      _updateWords();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    _focusNode.requestFocus();
  }

  Future<void> _speakText(String text) async {
    final tts = ref.read(ttsServiceProvider);
    final settings = ref.read(ttsSettingsProvider);

    await tts.setVolume(settings.volume);
    await tts.setRate(settings.rate);
    await tts.setPitch(settings.pitch);

    // 设置语言
    String language = widget.language.toLowerCase();

    await tts.speak(text, language);
  }

  void _handleWordTap(String word) {
    setState(() {
      _selection = null; // 清除长按选择
      if (_selectedWord == word) {
        _selectedWord = null; // 再次点击取消选中
      } else {
        _selectedWord = word;
        _speakText(word); // 发音选中的词
      }
    });
    widget.onWordTap?.call(word);
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    setState(() {
      _selectedWord = null; // 清除词选中
      _selection = selection; // 更新选择范围
    });

    if (cause == SelectionChangedCause.longPress) {
      final selectedText = selection.textInside(widget.text);
      if (selectedText.isNotEmpty) {
        _speakText(selectedText); // 发音选中的文本
        widget.onWordTap?.call(selectedText);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_error != null) {
      debugPrint('Rendering with error: $_error');
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      behavior: HitTestBehavior.translucent,
      child: Focus(
        focusNode: _focusNode,
        child: SelectableText.rich(
          TextSpan(
            children: _buildTextSpans(),
          ),
          style: widget.style,
          onTap: () {
            setState(() {
              _selectedWord = null;
              _selection = null;
            });
          },
          onSelectionChanged: _handleSelectionChanged,
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans() {
    final defaultStyle = widget.style ?? Theme.of(context).textTheme.bodyLarge;

    if (_selection != null) {
      // 长按选择模式：完全按字符处理，忽略分词结果
      List<TextSpan> charSpans = [];
      String currentText = '';

      for (String char in _chars) {
        final isSelected = _selection!.start <= currentText.length &&
            currentText.length < _selection!.end;

        charSpans.add(
          TextSpan(
            text: char,
            style: defaultStyle?.copyWith(
              backgroundColor: isSelected ? Colors.yellow : null,
              color: isSelected ? Colors.black : null,
              // fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        );

        currentText += char;
      }

      return charSpans;
    } else {
      // 点击选择模式：使用分词结果
      List<TextSpan> wordSpans = [];

      for (int i = 0; i < _words.length; i++) {
        final word = _words[i];
        final isSelected = word == _selectedWord;

        wordSpans.add(
          TextSpan(
            text: word,
            style: defaultStyle?.copyWith(
              backgroundColor: isSelected ? Colors.yellow : null,
              color: isSelected ? Colors.black : null,
              // fontWeight: isSelected ? FontWeight.bold : null,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _handleWordTap(word),
          ),
        );

        // 在非最后一个词后添加空格（对于中日文不添加）
        if (i < _words.length - 1 &&
            !widget.language.toLowerCase().contains('zh') &&
            !widget.language.toLowerCase().contains('ja')) {
          wordSpans.add(const TextSpan(text: ' '));
        }
      }

      return wordSpans;
    }
  }
}
