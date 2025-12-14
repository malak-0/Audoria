import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isAvailable = false;
  bool _isListening = false;
  bool autoRestart = true;
  bool _isTemporarilyPaused = false;
  int _errorCount = 0;
  bool _isRestarting = false;

  Function(String)? onResult;

  Future<void> init() async {
    _isAvailable = await _speech.initialize(
      onStatus: (status) async {
        print("🎙️ VoiceService status: $status");
        print(
          "  autoRestart: $autoRestart, paused: $_isTemporarilyPaused, listening: $_isListening",
        );
        if (status == 'notListening' &&
            _isAvailable &&
            autoRestart &&
            !_isTemporarilyPaused) {
          print("  ✅ Triggering restart (notListening)");
          await _handleTimeoutRestart();
        } else if (status == 'done' &&
            _isAvailable &&
            autoRestart &&
            !_isTemporarilyPaused) {
          print("  ✅ Triggering restart (done)");
          await _handleTimeoutRestart();
        }
        _isListening = (status == 'listening');
      },
      onError: (error) {
        print("❌ Speech error: ${error.errorMsg}");
        if (error.errorMsg == 'error_no_match') {
          print("  🔄 No match - will restart after delay");
          _errorCount = 0;
          _isListening = false;
          Future.delayed(const Duration(milliseconds: 1000), () async {
            print("  Checking restart conditions...");
            print(
              "    listening: $_isListening, restarting: $_isRestarting, autoRestart: $autoRestart, paused: $_isTemporarilyPaused",
            );
            if (!_isListening &&
                !_isRestarting &&
                autoRestart &&
                !_isTemporarilyPaused &&
                _isAvailable) {
              print("  ✅ Restarting after no match");
              await _startListening();
            } else {
              print("  ❌ Cannot restart - conditions not met");
            }
          });
          return;
        }

        _errorCount++;
        if (_errorCount > 3) {
          _errorCount = 0;
          _resetAndRestart();
        }
      },
    );

    if (_isAvailable) {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_isListening || _isRestarting) {
      return;
    }

    if (_isTemporarilyPaused) {
      _isTemporarilyPaused = false;
    }

    _isListening = true;
    _errorCount = 0;
    _isRestarting = false;

    try {
      await _speech.listen(
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: false,
        onResult: (result) {
          if (onResult != null && result.recognizedWords.isNotEmpty) {
            _errorCount = 0;
            onResult!(result.recognizedWords);
          } else {
            _errorCount = 0;
          }
        },
      );
    } catch (e) {
      _isListening = false;
      if (autoRestart && !_isTemporarilyPaused) {
        await Future.delayed(const Duration(milliseconds: 1000));
        await _startListening();
      }
    }
  }

  Future<void> _handleTimeoutRestart() async {
    if (_isRestarting) {
      return;
    }

    _isRestarting = true;

    if (_isListening) {
      _isListening = false;
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!_isListening && autoRestart && !_isTemporarilyPaused && _isAvailable) {
      await _startListening();
    }

    _isRestarting = false;
  }

  Future<void> _resetAndRestart() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }

    _isRestarting = true;
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!_isListening && autoRestart && !_isTemporarilyPaused) {
      await _startListening();
    }
    _isRestarting = false;
  }

  Future<void> pauseDuringTTS() async {
    if (_isListening) {
      _isTemporarilyPaused = true;
      await _speech.stop();
      _isListening = false;
    } else if (!_isListening && !_isTemporarilyPaused) {
      _isTemporarilyPaused = true;
    }
  }

  Future<void> resumeAfterTTS() async {
    _isTemporarilyPaused = false;
    await Future.delayed(const Duration(milliseconds: 800));

    if (!_isListening && _isAvailable && autoRestart) {
      await _startListening();
    }
  }

  Future<void> stop() async {
    await _speech.stop();
    _isListening = false;
    _isTemporarilyPaused = false;
  }

  Future<void> uninitialize() async {
    await _speech.cancel();
    _isListening = false;
    _isAvailable = false;
    _isTemporarilyPaused = false;
  }

  Future<void> hardReset() async {
    await uninitialize();
    await Future.delayed(const Duration(milliseconds: 500));
    _errorCount = 0;
    _isTemporarilyPaused = false;
  }

  bool get isActive => _isAvailable && (_isListening || !_isTemporarilyPaused);

  Future<void> forceRestart() async {
    await stop();
    await Future.delayed(const Duration(milliseconds: 300));
    _isTemporarilyPaused = false;
    if (_isAvailable && autoRestart) {
      await _startListening();
    }
  }
}
