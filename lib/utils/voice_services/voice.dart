// File 1 — lib/utils/voice_services/listen.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class Voice {
  Voice._internal();
  static final Voice instance = Voice._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final StreamController<String> _partialTextController = StreamController.broadcast();
  final StreamController<String> _finalTextController = StreamController.broadcast();
  final StreamController<bool> _isListeningController = StreamController.broadcast();
  final StreamController<bool> _isSpeakingController = StreamController.broadcast();

  Stream<String> get partialTextStream => _partialTextController.stream;
  Stream<String> get finalTextStream => _finalTextController.stream;
  Stream<bool> get isListeningStream => _isListeningController.stream;
  Stream<bool> get isSpeakingStream => _isSpeakingController.stream;

  bool _initialized = false;
  bool _listening = false;
  bool get isListening => _listening;
  bool _speaking = false;
  bool get isSpeaking => _speaking;

  /// Set these if you want automatic behavior changes
  Duration listenFor = const Duration(seconds: 12);
  Duration pauseFor = const Duration(seconds: 3); 
  bool autoResumeAfterTts = true;

  Future<void> initialize({String? ttsLanguage, String? ttsVoice}) async {
    if (_initialized) return;

    // request microphone permission (best practice before initializing)
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw Exception('Microphone permission denied');
    }

    final available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
      debugLogging: false,
    );

    if (!available) {
      throw Exception('Speech recognition not available on this device');
    }

    // configure TTS
    await _tts.setSharedInstance(true);
    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}

    if (ttsLanguage != null) {
      try {
        await _tts.setLanguage(ttsLanguage);
      } catch (_) {}
    }
    if (ttsVoice != null) {
      try {
        await _tts.setVoice({'name': ttsVoice});
      } catch (_) {}
    }

    // TTS callbacks
    _tts.setStartHandler(() {
      _setSpeaking(true);
      // ensure speech recognition is stopped when tts starts
      if (_listening) stopListening();
    });

    _tts.setCompletionHandler(() {
      _setSpeaking(false);
      // automatic resume is handled by caller (listen handler) if desired
    });

    _tts.setErrorHandler((msg) {
      _setSpeaking(false);
      if (kDebugMode) print('TTS error: $msg');
    });

    _initialized = true;
  }

  void _onSpeechStatus(String status) {
    if (kDebugMode) print('speech status: $status');
    if (status == 'listening') {
      _setListening(true);
    } else if (status == 'notListening' || status == 'done') {
      _setListening(false);
    }
  }

  void _onSpeechError(stt.SpeechRecognitionError err) {
    if (kDebugMode) print('speech error: ${err.errorMsg} permanent:${err.permanent}');
    _setListening(false);
  }

  void _setListening(bool v) {
    _listening = v;
    _isListeningController.add(v);
  }

  void _setSpeaking(bool v) {
    _speaking = v;
    _isSpeakingController.add(v);
  }

  Future<void> startListening({String? localeId}) async {
    if (!_initialized) await initialize();
    if (_speaking) {
      if (kDebugMode) print('Refusing to start listening: currently speaking');
      return;
    }

    if (_listening) return; 

    try {
      await _speech.listen(
        onResult: (result) {
          _partialTextController.add(result.recognizedWords);
          if (result.finalResult) {
            _finalTextController.add(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      );
    } catch (e) {
      if (kDebugMode) print('startListening error: $e');
      _setListening(false);
    }
  }

  Future<void> stopListening() async {
    if (!_initialized) return;
    if (!_listening) return;
    try {
      await _speech.stop();
    } catch (_) {}
    _setListening(false);
  }

  Future<void> cancelListening() async {
    if (!_initialized) return;
    try {
      await _speech.cancel();
    } catch (_) {}
    _setListening(false);
  }

  Future<void> speak(String text) async {
    if (!_initialized) await initialize();
    if (text.trim().isEmpty) return;
    if (_listening) await stopListening();

    try {
      await _tts.speak(text);
    } catch (e) {
      if (kDebugMode) print('TTS speak failed: $e');
      _setSpeaking(false);
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _setSpeaking(false);
  }

  void dispose() {
    _partialTextController.close();
    _finalTextController.close();
    _isListeningController.close();
    _isSpeakingController.close();
    try {
      _speech.stop();
      _tts.stop();
    } catch (_) {}
  }
}