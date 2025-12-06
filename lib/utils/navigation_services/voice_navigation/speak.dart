import 'dart:async';
import 'dart:ui';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechFeedback {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  Completer<void>? _currentSpeechCompleter;
  
  VoidCallback? onSpeechStarted;
  VoidCallback? onSpeechCompleted;

  SpeechFeedback() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Setup callbacks
    _tts.setStartHandler(() {
      _isSpeaking = true;
      if (onSpeechStarted != null) {
        onSpeechStarted!();
      }
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (_currentSpeechCompleter != null && !_currentSpeechCompleter!.isCompleted) {
        _currentSpeechCompleter!.complete();
      }
      if (onSpeechCompleted != null) {
        onSpeechCompleted!();
      }
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      if (_currentSpeechCompleter != null && !_currentSpeechCompleter!.isCompleted) {
        _currentSpeechCompleter!.completeError(msg);
      }
      if (onSpeechCompleted != null) {
        onSpeechCompleted!();
      }
    });
  }

  bool get isSpeaking => _isSpeaking;

  Future<void> speak(String text) async {
    try {
      if (_isSpeaking) {
        await stop();
      }
      
      _currentSpeechCompleter = Completer<void>();
      await _tts.speak(text);
      
      // Wait for speech to complete
      return _currentSpeechCompleter!.future;
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      if (_currentSpeechCompleter != null && !_currentSpeechCompleter!.isCompleted) {
        _currentSpeechCompleter!.complete();
      }
    } catch (e) {
      print("TTS Stop Error: $e");
    }
  }
}