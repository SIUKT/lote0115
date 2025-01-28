import 'package:collection/collection.dart';
import 'package:isar/isar.dart';

part 'word.g.dart';

@collection
class Word {
  Id id = Isar.autoIncrement;

  String? text;
  String? language;
  List<WordDefinition>? definitions;
  List<ExampleSentence>? exampleSentences;
  String? pronunciation;
  String? audioUrl;
  String? imageUrl;
  String? source;

  // 输入语言参数获得对应定义
  static String? getDefinition(Word word, String language) {
    return word.definitions!
        .firstWhereOrNull(
            (definition) => (definition.language ?? '') == language)
        ?.definition;
  }
}

@embedded
class ExampleSentence {
  String? sentence;
  List<SentenceTranslation>? translations;

  static String? getTranslation(ExampleSentence sentence, String language) {
    return sentence.translations!
        .firstWhereOrNull((translation) => (translation.language ?? '') == language)
        ?.translation;
  }
}

@embedded
class SentenceTranslation {
  String? translation;
  String? language;
}

@embedded
class WordDefinition {
  String? definition;
  String? language;
}

