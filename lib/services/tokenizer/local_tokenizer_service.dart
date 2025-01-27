import 'package:jieba_flutter/analysis/jieba_segmenter.dart';
import 'package:japanese_word_tokenizer/japanese_word_tokenizer.dart' as jw;
import 'package:ringo/ringo.dart';
import 'package:flutter/foundation.dart';
import 'tokenizer_service.dart';

class LocalTokenizerService implements TokenizerService {
  JiebaSegmenter? _jiebaSegmenter;
  bool _isInitialized = false;
  final _japaneseTokenizer = jw.tokenize;
  late Ringo _ringo;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await JiebaSegmenter.init();
      _ringo = await Ringo.init();
      _jiebaSegmenter = JiebaSegmenter();
      _isInitialized = true;
    }
  }

  @override
  Future<List<String>> tokenize(String text, String language) async {
    language = language.toLowerCase();

    try {
      if (language == 'zh') {
        // 中文分词
        await _ensureInitialized();
        final tokens = _jiebaSegmenter!.process(text, SegMode.SEARCH);
        return tokens.map((token) => token.word).toList();
      } else if (language == 'ja') {
        // 日语分词
        final tokens = _japaneseTokenizer(text);
        // final tokens = _ringo.tokenize(text);
        return tokens.map((token) => token).toList();
      } else {
        // 其他语言按空格分词
        // 先去掉换行符
        // text = text.replaceAll('\n', ' ');
        // text = text.replaceAll('  ', ' ');
        return text.split(' ');
      }
    } catch (e) {
      debugPrint('Tokenization error: $e');
      // 如果分词失败，回退到字符分词
      if (language == 'zh' || language == 'ja') {
        return text.split('');
      } else {
        return text.split(' ');
      }
    }
  }
}
