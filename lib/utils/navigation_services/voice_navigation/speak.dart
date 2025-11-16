import 'package:flutter_tts/flutter_tts.dart';

class SpeechFeedback {
  final FlutterTts _tts = FlutterTts();

  SpeechFeedback() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.awaitSpeakCompletion(true); 
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
  }

  Future<void> speak(String text) async {
    await _tts.stop(); 
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
