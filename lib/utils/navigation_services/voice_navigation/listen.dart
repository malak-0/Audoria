import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isAvailable = false;
  bool _isListening = false;
  bool autoRestart = true;
  bool _isTemporarilyPaused = false;
  int _errorCount = 0;

  Function(String)? onResult;

  Future<void> init() async {
    _isAvailable = await _speech.initialize(
      onStatus: (status) async {
        if (status == 'notListening' && _isAvailable && autoRestart && !_isTemporarilyPaused) {
          await _handleTimeoutRestart();
        }
      },
      onError: (error) {
        print('Speech error: $error');
        _errorCount++;
        
        if (_errorCount > 3) {
          print("Too many errors, resetting speech service...");
          _errorCount = 0;
          _resetAndRestart();
        }
      },
    );

    if (_isAvailable) {
      await _startListening();
    } else {
      print("Speech recognition not available.");
    }
  }

  Future<void> _startListening() async {
    if (_isListening || _isTemporarilyPaused) return;

    _isListening = true;
    _errorCount = 0;
    
    await _speech.listen(
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      partialResults: false,
      onResult: (result) {
        if (onResult != null && result.recognizedWords.isNotEmpty) {
          _errorCount = 0;
          onResult!(result.recognizedWords);
        }
      },
    );
    print("VoiceService: Listening started...");
  }

  Future<void> _handleTimeoutRestart() async {
    _isListening = false;
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!_isListening && autoRestart && !_isTemporarilyPaused) {
      print("VoiceService: Restarting listening after timeout...");
      await _startListening();
    }
  }

  Future<void> _resetAndRestart() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!_isListening && autoRestart && !_isTemporarilyPaused) {
      print("VoiceService: Resetting and restarting speech service...");
      await _startListening();
    }
  }

  Future<void> pauseDuringTTS() async {
    if (_isListening) {
      _isTemporarilyPaused = true;
      await _speech.stop();
      _isListening = false;
      print("VoiceService: Listening paused during TTS...");
    } else if (!_isListening && !_isTemporarilyPaused) {
      _isTemporarilyPaused = true;
    }
  }

  Future<void> resumeAfterTTS() async {
    if (!_isListening && _isTemporarilyPaused) {
      _isTemporarilyPaused = false;
      print("VoiceService: Resuming listening after TTS...");
      await Future.delayed(const Duration(milliseconds: 500));
      await _startListening();
    }
  }

  Future<void> stop() async {
    await _speech.stop();
    _isListening = false;
    _isTemporarilyPaused = false;
    print("VoiceService: Listening stopped manually");
  }

  Future<void> uninitialize() async {
    await _speech.cancel();
    _isListening = false;
    _isAvailable = false;
    _isTemporarilyPaused = false;
    print("VoiceService: Speech service uninitialized");
  }

  // NEW METHOD: Complete reset
  Future<void> hardReset() async {
    print("VoiceService: Performing hard reset...");
    await uninitialize();
    await Future.delayed(const Duration(milliseconds: 500));
    _errorCount = 0;
  }
}