import 'package:flutter_tts/flutter_tts.dart';
import 'tts_service.dart';

class FlutterTTSService implements TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _currentText;
  String? _currentLanguage;

  FlutterTTSService() {
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _currentText = null;
      _currentLanguage = null;
    });
  }

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _isInitialized = true;
  }

  @override
  Future<void> speak(String text, String language) async {
    if (!_isInitialized) await init();

    if (_isSpeaking && text == _currentText && language == _currentLanguage) {
      await stop();
      return;
    }

    // Convert language code to TTS language code
    final ttsLanguage = _convertToTTSLanguage(language);
    await _tts.setLanguage(ttsLanguage);
    _isSpeaking = true;
    _currentText = text;
    _currentLanguage = language;
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    _currentText = null;
    _currentLanguage = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
  }

  @override
  Future<List<String>> getLanguages() async {
    if (!_isInitialized) await init();
    final languages = await _tts.getLanguages;
    return languages.cast<String>();
  }

  @override
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) await init();
    final ttsLanguage = _convertToTTSLanguage(language);
    await _tts.setLanguage(ttsLanguage);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) await init();
    await _tts.setVolume(volume);
  }

  @override
  Future<void> setRate(double rate) async {
    if (!_isInitialized) await init();
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) await init();
    await _tts.setPitch(pitch);
  }

  String _convertToTTSLanguage(String language) {
    // Map language codes to TTS language codes
    final languageMap = {
      'en': 'en-US',
      'zh': 'zh-CN',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'it': 'it-IT',
      'ru': 'ru-RU',
      'pt': 'pt-PT',
      'tr': 'tr-TR',
      'da': 'da-DK',
      'nl': 'nl-NL',
      'sv': 'sv-SE',
      'fi': 'fi-FI',
      'hu': 'hu-HU',
      'pl': 'pl-PL',
      'el': 'el-GR',
    };

    return languageMap[language] ?? 'en-US';
  }
}
