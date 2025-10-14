import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isAvailable = false;
  bool _isListening = false;

  /// Controls whether auto-restart after timeout is active.
  bool autoRestart = true;

  /// Allows pausing listening during TTS playback.
  bool _isTemporarilyPaused = false;

  Function(String)? onResult;

  Future<void> init() async {
    _isAvailable = await _speech.initialize(
      onStatus: (status) async {
        if (status == 'notListening' && _isAvailable && autoRestart) {
          await _handleTimeoutRestart();
        }
      },
      onError: (error) => print('Speech error: $error'),
    );

    if (_isAvailable) {
      await _startListening();
    } else {
      print("🚫 Speech recognition not available.");
    }
  }

  Future<void> _startListening() async {
    if (_isListening || _isTemporarilyPaused) return;

    _isListening = true;
    await _speech.listen(
      listenFor: const Duration(seconds: 20), // longer listening window
      pauseFor: const Duration(seconds: 5),  // stop after 5 sec silence
      cancelOnError: true,
      onResult: (result) {
        if (onResult != null && result.recognizedWords.isNotEmpty) {
          onResult!(result.recognizedWords);
        }
      },
    );
    print("🎤 Listening started...");
  }

  /// Handles restarting the listener after a timeout (if enabled)
  Future<void> _handleTimeoutRestart() async {
    _isListening = false;
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!_isListening && autoRestart && !_isTemporarilyPaused) {
      print("⏱️ Restarting listening after timeout...");
      await _startListening();
    }
  }

  /// Pauses listening during TTS speech
  Future<void> pauseDuringTTS() async {
    if (_isListening) {
      _isTemporarilyPaused = true;
      await _speech.stop();
      _isListening = false;
      print("🤫 Listening paused during TTS...");
    }
  }

  /// Resumes listening after TTS speech finishes
  Future<void> resumeAfterTTS() async {
    if (!_isListening && _isTemporarilyPaused) {
      _isTemporarilyPaused = false;
      print("🎤 Resuming listening after TTS...");
      await _startListening();
    }
  }

  Future<void> stop() async {
    await _speech.stop();
    _isListening = false;
    print("🛑 Listening stopped manually");
  }

  Future<void> uninitialize() async {
    await _speech.cancel();
    _isListening = false;
    _isAvailable = false;
    print("🔁 Speech service uninitialized");
  }
}
