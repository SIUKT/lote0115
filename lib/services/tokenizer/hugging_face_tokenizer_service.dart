import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'tokenizer_service.dart';

class HuggingFaceTokenizerService implements TokenizerService {
  final String _apiKey;
  final String _baseUrl = 'https://api-inference.huggingface.co/models/';
  
  final Map<String, String> _modelMap = {
    'zh': 'dslim/bert-base-NER-chinese',  // 更换为NER模型
    'ja': 'ku-nlp/deberta-v2-base-japanese',  // 更换为日语专用模型
  };

  HuggingFaceTokenizerService(this._apiKey);

  @override
  Future<List<String>> tokenize(String text, String language) async {
    language = language.toLowerCase();
    String modelName = _modelMap[language] ?? 'xlm-roberta-base';
    
    debugPrint('Tokenizing text with model: $modelName');
    debugPrint('Text to tokenize: $text');

    try {
      final url = Uri.parse('$_baseUrl$modelName');
      debugPrint('Request URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'inputs': text,
          'parameters': {
            'task': 'token-classification'
          }
        }),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          // 从NER结果中提取词
          final List<String> words = [];
          String currentWord = '';
          int lastEnd = 0;
          
          for (var item in data) {
            if (item is Map) {
              final start = item['start'] as int;
              final end = item['end'] as int;
              final word = text.substring(start, end);
              
              // 处理未被识别为实体的文本
              if (start > lastEnd) {
                final gap = text.substring(lastEnd, start).trim();
                if (gap.isNotEmpty) {
                  if (language == 'zh' || language == 'ja') {
                    words.addAll(gap.split(''));
                  } else {
                    words.addAll(gap.split(' '));
                  }
                }
              }
              
              words.add(word);
              lastEnd = end;
            }
          }
          
          // 处理最后一段文本
          if (lastEnd < text.length) {
            final remaining = text.substring(lastEnd).trim();
            if (remaining.isNotEmpty) {
              if (language == 'zh' || language == 'ja') {
                words.addAll(remaining.split(''));
              } else {
                words.addAll(remaining.split(' '));
              }
            }
          }
          
          debugPrint('Processed words: $words');
          return words;
        }
        throw Exception('Unexpected response format: $data');
      } else {
        debugPrint('Error response: ${response.body}');
        return _fallbackTokenize(text, language);
      }
    } catch (e, stackTrace) {
      debugPrint('Error during tokenization: $e');
      debugPrint('Stack trace: $stackTrace');
      return _fallbackTokenize(text, language);
    }
  }

  List<String> _fallbackTokenize(String text, String language) {
    debugPrint('Using fallback tokenization for language: $language');
    if (language == 'zh' || language == 'ja') {
      return text.split('');
    } else {
      return text.split(' ');
    }
  }
}
