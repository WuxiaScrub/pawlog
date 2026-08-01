import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SttState { idle, listening, done, error }

class SttService {
  final SpeechToText _speech = SpeechToText();
  Timer? _hardCutoff;
  bool _initialized = false;
  bool _delivered = false;

  SttState state = SttState.idle;
  String transcript = '';
  String errorMessage = '';

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (error) {
        if (error.errorMsg == 'error_speech_timeout' ||
            error.errorMsg == 'error_no_match') {
          state = SttState.done;
        } else {
          state = SttState.error;
          errorMessage = error.errorMsg;
        }
      },
    );
    return _initialized;
  }

  Future<void> startListening({
    required void Function(String partial) onPartial,
    required void Function(String final_) onFinal,
    required void Function(String error) onError,
  }) async {
    transcript = '';
    _delivered = false;
    state = SttState.listening;

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) async {
        transcript = result.recognizedWords;
        if (result.finalResult) {
          _cancelCutoff();
          if (!_delivered) {
            _delivered = true;
            state = SttState.done;
            // Release the recogniser before handing the transcript on. On iOS
            // the plugin otherwise keeps the shared AVAudioSession in a
            // recording category, which swallows the start of any TTS
            // confirmation the caller plays.
            await stop();
            onFinal(transcript);
          }
        } else {
          onPartial(transcript);
        }
      },
      pauseFor: const Duration(seconds: 2),
      listenMode: ListenMode.dictation,
    );

    _hardCutoff = Timer(const Duration(seconds: 30), () async {
      if (_delivered) return;
      _delivered = true;
      state = SttState.done;
      await stop();
      onFinal(transcript);
    });
  }

  Future<void> stop() async {
    _cancelCutoff();
    await _speech.stop();
  }

  void _cancelCutoff() {
    _hardCutoff?.cancel();
    _hardCutoff = null;
  }

  bool get isAvailable => _initialized;
}
