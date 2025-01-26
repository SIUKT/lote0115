import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lote0115/providers/language_provider.dart';
import 'dart:convert';
import 'package:lote0115/providers/user_data_provider.dart';

final aiServiceProvider = Provider((ref) => AiService(ref));

class AiService {
  final Ref ref;
  AiService(this.ref);

  String get _baseUrl {
    final customApi = ref.read(userDataProvider)?.currentApi;
    return customApi?.baseUrl ?? dotenv.env['AI_BASE_URL']!;
  }

  String get _apiKey {
    final customApi = ref.read(userDataProvider)?.currentApi;
    return customApi?.apiKey ?? dotenv.env['AI_API_KEY']!;
  }

  String _getPrompt(String? context, String content, String targetLanguage) {
    final String contextPrompt = 'And respect the following context: $context';
    final String targetLanguageName =
        ref.read(languageNameProvider(targetLanguage));
    final String header =
        "Please respect the original meaning, maintain the original format, keep vulgar meanings if any, and rewrite the following content in $targetLanguageName: $content";
    return [header, if (context != null && context.isNotEmpty) contextPrompt]
        .join("\n");
  }

  String _getShortPrompt(
      String? context, String content, String targetLanguage) {
    final String targetLanguageName =
        ref.read(languageNameProvider(targetLanguage));
    final String header = "Translate to $targetLanguageName: $content";
    return header;
  }

  Stream<String> getTranslation(String? context, String content,
      String primaryLanguage, String targetLanguage) async* {
    final url = Uri.parse('$_baseUrl/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final primaryLanguageName = ref.read(languageNameProvider(primaryLanguage));
    final targetLanguageName = ref.read(languageNameProvider(targetLanguage));

    // Define individual prompts as constants
    final String contextPrompt = 'And respect the following context: $context';
    final String targetLanguagePrompt =
        'Translate the original text to $targetLanguageName.';
    const String tonePrompt = "Maintain the original tone.";
    const String formatPrompt = "Preserve the formatting of the original text.";
    const String translationPrompt =
        "Provide only the translation, without adding extra information.";
    const String paraphrasingPrompt =
        "Rephrase appropriately to ensure the translation is natural and smooth.";
    const String stylePrompt =
        "Decide whether to use a casual or formal style based on the content. Keep vulgar words if any.";
    final String textPrompt = 'Original Text: $content';

    final String header = """
Translate the original text or word to $targetLanguageName.
Preserve the formatting of the original text.
Be casual or formal based on the content. Keep vulgar words if any.
Follow the context/instruction if provided.
Provide the translation only, without adding extra information.
Use common slangs or native expressions appropriately to sound natural.""";

    final String prompt2 = [
      header,
      textPrompt,
      if (context != null && context.isNotEmpty) contextPrompt
    ].join("\n");

    // Combine all prompts into one
    final String prompt = [
      targetLanguagePrompt,
      tonePrompt,
      formatPrompt,
      translationPrompt,
      paraphrasingPrompt,
      stylePrompt,
      if (context != null && context.isNotEmpty) contextPrompt,
      textPrompt
    ].join("\n");

    final String prompt3 = [
      "Please respect the original meaning, maintain the original format, keep vulgar meanings if any, and rewrite the following content in $targetLanguageName or $primaryLanguageName: $content",
      if (context != null && context.isNotEmpty) contextPrompt
    ].join("\n");
    const String systemPrompt = 'Only rewrite unless asked otherwise.';

    print(prompt3);

    final body = jsonEncode({
      'model': 'deepseek-chat',
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        {
          'role': 'user',
          'content': prompt3,
        }
      ],
      'stream': true,
    });

    try {
      final request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = body;

      final response = await http.Client().send(request);
      print('response content length: ${response.contentLength}');
      print('response: $response');
      final stream = response.stream.transform(utf8.decoder);

      await for (final chunk in stream) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ') && line != 'data: [DONE]') {
            final data = line.substring(6);
            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'];
              if (content != null) {
                yield content;
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      }
    } catch (e) {
      yield '翻译失败: $e';
    }
  }

  Stream<String> getAnswer(
      String? context,
      String primaryContent,
      String originalTranslation,
      String primaryLanguage,
      String targetLanguage,
      String question,
      List<Map<String, String?>> previousQnAs) async* {
    final primaryLanguageName = ref.read(languageNameProvider(primaryLanguage));
    final targetLanguageName = ref.read(languageNameProvider(targetLanguage));
    final url = Uri.parse('$_baseUrl/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    String systemPrompt;

    if (primaryLanguage != targetLanguage) {
      systemPrompt =
          'Respond succinctly in $primaryLanguageName or $targetLanguageName, depending on the language the last content uses.';
    } else {
      systemPrompt = 'Respond succinctly in $primaryLanguageName';
    }

    final messages = [
      {
        'role': 'system',
        'content': systemPrompt,
      },
    ];

    final messages1 = <Map<String, String>>[];

    messages1.add({
      'role': 'user',
      'content': _getShortPrompt(context, primaryContent, targetLanguage),
    });

    messages1.add({
      'role': 'assistant',
      'content': originalTranslation,
    });

    // 添加历史问答记录
    for (final qna in previousQnAs) {
      messages1.add({
        'role': 'user',
        'content': qna['question']!,
      });
      messages1.add({
        'role': 'assistant',
        'content': qna['answer']!,
      });
    }

    // 添加当前问题
    messages1.add({
      'role': 'user',
      'content': question,
    });

    // messages.add({
    //     'role': 'user',
    //     'content': messages1.toString(),
    //   },);
    messages.addAll(messages1);

    print('messages: $messages');

    final body = jsonEncode({
      'model': 'deepseek-chat',
      'messages': messages,
      'stream': true,
    });

    try {
      final request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = body;

      final response = await http.Client().send(request);
      print('response content length: ${response.contentLength}');
      print('response: $response');
      final stream = response.stream.transform(utf8.decoder);

      await for (final chunk in stream) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ') && line != 'data: [DONE]') {
            final data = line.substring(6);
            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'];
              if (content != null) {
                yield content;
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      }
    } catch (e) {
      yield '获取答案失败: $e';
    }
  }
}
