import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Wrapper around [FlutterTts].
///
/// On iOS the recogniser and the synthesiser share one AVAudioSession. While
/// `speech_to_text` is listening that session sits in a recording category, and
/// anything spoken before it is handed back gets swallowed — the user hears
/// only the tail of the utterance. [initialize] claims the shared session for
/// playback, and [speak] resolves only once the utterance has actually
/// finished so callers can safely pop a screen or restart the mic afterwards.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  // defaultTargetPlatform rather than dart:io, so this stays importable from
  // the web build.
  static bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// How long the iOS audio session needs to leave the recording route before
  /// a spoken utterance is audible from its first syllable. Callers that have
  /// just stopped the mic should wait this out first — see [speakAfterMic].
  static const settleDelay = Duration(milliseconds: 300);

  Future<void> initialize() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    if (_isIos) {
      // Share the app-wide session with speech_to_text so the two plugins hand
      // it back and forth rather than racing for it. autoStopSharedSession
      // (on by default) then releases it again once we stop speaking.
      await _tts.setSharedInstance(true);
      // playback already routes to the loudspeaker; defaultToSpeaker is only
      // legal on playAndRecord, so it is deliberately not set here.
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.duckOthers],
      );
    }

    // Resolve `speak` on completion rather than on start. Mobile/desktop only —
    // the web implementation has no such method.
    if (!kIsWeb) await _tts.awaitSpeakCompletion(true);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    await initialize();
    await _tts.speak(text);
  }

  /// Speaks [text] just after the microphone has been released, waiting out
  /// [settleDelay] so the first words are not lost to the audio route switch.
  Future<void> speakAfterMic(String text) async {
    await initialize();
    await Future<void>.delayed(settleDelay);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
