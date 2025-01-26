import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;
  String? cloudId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? context;
  List<String>? tags;
  List<NoteVariant>? variants;

  Note() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  String get primaryLanguage =>
      variants
          ?.where((variant) => variant.isPrimary == true)
          .first
          .language
          ?.toLowerCase() ??
      '??';
  String get primaryContent =>
      variants?.where((variant) => variant.isPrimary == true).first.content ??
      '??';
  String get content =>
      variants?.where((variant) => variant.isCurrent == true).first.content ??
      '???';
  String get language =>
      variants
          ?.where((variant) => variant.isCurrent == true)
          .first
          .language
          ?.toLowerCase() ??
      '??';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cloudId': cloudId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'context': context,
      'tags': tags?.join(','),
      'variants': variants?.map((v) => v.toJson()).toList(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note()
      ..id = json['id']
      ..cloudId = json['cloudId']
      ..createdAt = json['createdAt'] is String
          ? DateTime.parse(json['createdAt']).toLocal()
          : json['createdAt']
      ..updatedAt = json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt']).toLocal()
          : json['updatedAt']
      ..context = json['context']
      ..tags = json['tags'] is String && json['tags']?.isNotEmpty == true
          ? json['tags']!.split(',')
          : json['tags'] is List
              ? json['tags']
              : null
      ..variants = (json['variants'] as List<dynamic>?)
          ?.map((e) => NoteVariant.fromJson(e))
          .toList();
  }

  List<dynamic> toCsvRow() {
    return [
      id,
      cloudId,
      createdAt,
      updatedAt,
      context,
      tags?.join(','),
      variants?.map((e) => e.toCsvRow()).toList(),
    ];
  }
}

@embedded
class NoteVariant {
  String? language;
  bool? isPrimary;
  bool? isCurrent;
  String? content;
  List<QnA>? qnas;
  String? audioUrl;
  String? explaination;
  int? reviewCount;
  DateTime? lastReviewAt;
  DateTime? createdAt;
  DateTime? editedAt;

  NoteVariant() {
    createdAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'isPrimary': isPrimary,
      'isCurrent': isCurrent,
      'content': content,
      'qnas': qnas?.map((q) => q.toJson()).toList(),
      'audioUrl': audioUrl,
      'explaination': explaination,
      'reviewCount': reviewCount,
      'lastReviewAt': lastReviewAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  factory NoteVariant.fromJson(Map<String, dynamic> json) {
    return NoteVariant()
      ..language = json['language']
      ..isPrimary = json['isPrimary']
      ..isCurrent = json['isCurrent']
      ..content = json['content']
      ..qnas =
          (json['qnas'] as List<dynamic>?)?.map((e) => QnA.fromJson(e)).toList()
      ..audioUrl = json['audioUrl']
      ..explaination = json['explaination']
      ..reviewCount = json['reviewCount']
      ..lastReviewAt = json['lastReviewAt'] is String
          ? DateTime.parse(json['lastReviewAt']).toLocal()
          : json['lastReviewAt']
      ..createdAt = json['createdAt'] is String
          ? DateTime.parse(json['createdAt']).toLocal()
          : json['createdAt']
      ..editedAt = json['editedAt'] is String
          ? DateTime.parse(json['editedAt']).toLocal()
          : json['editedAt'];
  }

  List<dynamic> toCsvRow() {
    return [
      language,
      isPrimary,
      isCurrent,
      content,
      qnas?.map((e) => e.toJson()).toList(),
      audioUrl,
      explaination,
      reviewCount,
      lastReviewAt,
      createdAt,
      editedAt,
    ];
  }
}

@embedded
class QnA {
  bool? isQuestion;
  String? question;
  String? answer;
  DateTime? createdAt;
  DateTime? updatedAt;

  QnA({this.isQuestion, this.question, this.answer}) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'isQuestion': isQuestion,
      'question': question,
      'answer': answer,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory QnA.fromJson(Map<String, dynamic> json) {
    return QnA()
      ..isQuestion = json['isQuestion']
      ..question = json['question']
      ..answer = json['answer']
      ..createdAt = json['createdAt'] is String
          ? DateTime.parse(json['createdAt']).toLocal()
          : json['createdAt']
      ..updatedAt = json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt']).toLocal()
          : json['updatedAt'];
  }
}
