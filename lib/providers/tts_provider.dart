import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lote0115/services/tts/flutter_tts_service.dart';
import 'package:lote0115/services/tts/tts_service.dart';

final ttsServiceProvider = Provider<TTSService>((ref) {
  final tts = FlutterTTSService();
  ref.onDispose(() {
    tts.dispose();
  });
  return tts;
});

// Provider for TTS settings
final ttsSettingsProvider = StateProvider((ref) => const TTSSettings());

class TTSSettings {
  final double volume;
  final double rate;
  final double pitch;

  const TTSSettings({
    this.volume = 1.0,
    this.rate = 0.5,
    this.pitch = 1.0,
  });

  TTSSettings copyWith({
    double? volume,
    double? rate,
    double? pitch,
  }) {
    return TTSSettings(
      volume: volume ?? this.volume,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
    );
  }
}
