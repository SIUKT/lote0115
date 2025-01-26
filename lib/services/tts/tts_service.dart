abstract class TTSService {
  Future<void> init();
  Future<void> speak(String text, String language);
  Future<void> stop();
  Future<void> dispose();
  Future<List<String>> getLanguages();
  Future<void> setLanguage(String language);
  Future<void> setVolume(double volume);
  Future<void> setRate(double rate);
  Future<void> setPitch(double pitch);
}
