import 'package:flutter_tts/flutter_tts.dart';

import '../data/models.dart';

final FlutterTts _tts = FlutterTts();
String? _lang;

/// Speaks [text] in [lang] ('de' | 'en' | 'tr'). Never throws: TTS may be
/// unavailable (web without voices, emulator, tests).
Future<void> speak(String text, [String lang = 'de', double rate = 0.45]) async {
  try {
    if (_lang != lang) {
      await _tts.setLanguage(ttsLocales[lang] ?? 'de-DE');
      _lang = lang;
    }
    await _tts.setSpeechRate(rate);
    await _tts.stop();
    await _tts.speak(text);
  } catch (_) {}
}
