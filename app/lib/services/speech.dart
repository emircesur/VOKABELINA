import 'package:speech_to_text/speech_to_text.dart';

const _sttLocales = {'de': 'de_DE', 'en': 'en_GB', 'tr': 'tr_TR'};

/// Thin wrapper around speech recognition. Every call is safe when the
/// platform has no recogniser (web without permission, tests, emulators).
class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool? _available;

  Future<bool> get available async {
    if (_available != null) return _available!;
    try {
      _available = await _stt.initialize();
    } catch (_) {
      _available = false;
    }
    return _available!;
  }

  Future<void> listen(String lang, void Function(String text, bool done) onResult) async {
    if (!await available) return;
    try {
      await _stt.listen(
        listenOptions: SpeechListenOptions(localeId: _sttLocales[lang], listenFor: const Duration(seconds: 12), pauseFor: const Duration(seconds: 3)),
        onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      );
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }
}

final speechService = SpeechService();
