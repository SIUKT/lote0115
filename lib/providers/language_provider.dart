import 'package:flutter_riverpod/flutter_riverpod.dart';

class Language {
  final String code;
  final String name;
  final String nativeName;
  final String zhName;

  const Language(this.code, this.name, this.nativeName, {required this.zhName});
}

final languagesProvider = Provider<List<Language>>((ref) {
  return const [
    Language('zh', 'Chinese', '中文', zhName: '中文'),
    Language('en', 'English', 'English', zhName: '英语'),
    Language('ja', 'Japanese', '日本語', zhName: '日语'),
    Language('ko', 'Korean', '한국어', zhName: '韩语'),
    Language('es', 'Spanish', 'Español', zhName: '西班牙语'),
    Language('fr', 'French', 'Français', zhName: '法语'),
    Language('de', 'German', 'Deutsch', zhName: '德语'),
    Language('it', 'Italian', 'Italiano', zhName: '意大利语'),
    Language('ru', 'Russian', 'Русский', zhName: '俄语'),
    Language('th', 'Thai', 'ไทย', zhName: '泰语'),
    Language('vi', 'Vietnamese', 'Tiếng Việt', zhName: '越南语'),
    Language('id', 'Indonesian', 'Bahasa Indonesia', zhName: '印度尼西亚语'),
    Language('ms', 'Malay', 'Bahasa Melayu', zhName: '马来语'),
    Language('ar', 'Arabic', 'العربية', zhName: '阿拉伯语'),
    Language('hi', 'Hindi', 'हिन्दी', zhName: '印地语'),
    Language('ur', 'Urdu', 'اردو', zhName: '乌尔都语'),
    Language('bn', 'Bengali', 'বাংলা', zhName: '孟加拉语'),
    Language('pa', 'Punjabi', 'ਪੰਜਾਬੀ', zhName: '旁遮普语'),
    Language('te', 'Telugu', 'తెలుగు', zhName: '泰卢固语'),
    Language('pt', 'Portuguese', 'Português', zhName: '葡萄牙语'),
    Language('tr', 'Turkish', 'Türkçe', zhName: '土耳其语'),
    Language('da', 'Danish', 'Dansk', zhName: '丹麦语'),
    Language('nl', 'Dutch', 'Nederlands', zhName: '荷兰语'),
    Language('sv', 'Swedish', 'Svenska', zhName: '瑞典语'),
    Language('fi', 'Finnish', 'Suomi', zhName: '芬兰语'),
    Language('hu', 'Hungarian', 'Magyar', zhName: '匈牙利语'),
    Language('pl', 'Polish', 'Polski', zhName: '波兰语'),
    Language('el', 'Greek', 'Ελληνικά', zhName: '希腊语'),
  ];
});

// 输入code，返回name
final languageNameProvider = Provider.family<String, String>((ref, code) {
  final languages = ref.watch(languagesProvider);
  final language = languages.firstWhere((l) => l.code == code);
  return language.name;
});

// 输入code，返回nativeName
final languageNativeNameProvider = Provider.family<String, String>((ref, code) {
  final languages = ref.watch(languagesProvider);
  final language = languages.firstWhere((l) => l.code == code);
  return language.nativeName;
});
