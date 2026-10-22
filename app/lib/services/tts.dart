import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts _tts = FlutterTts();
bool _ready = false;

/// Speaks German text. Never throws: TTS may be unavailable (web, emulator, tests).
Future<void> speak(String text) async {
  try {
    if (!_ready) {
      await _tts.setLanguage('de-DE');
      await _tts.setSpeechRate(0.45);
      _ready = true;
    }
    await _tts.stop();
    await _tts.speak(text);
  } catch (_) {}
}
