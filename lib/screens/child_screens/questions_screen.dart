import 'package:audoria/utils/ai_services/gemini.dart';
import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/commands_handler.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:flutter/material.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final GeminiService _geminiService = GeminiService();
  
  bool isProcessing = false;
  bool isListening = false;
  bool isSpeaking = false; 
  late SpeechFeedback tts;
  late CommandHandler commandHandler;
  final voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeVoiceSystem();
  }

  Future<void> _initializeVoiceSystem() async {
    tts = SpeechFeedback();
    commandHandler = CommandHandler(tts: tts);

    voiceService.onResult = (question) async {
      print("User said: $question");
      await _handleConversation(question);
      return question;
    };

    await tts.speak('Wait 2 seconds to start the conversation');
    await voiceService.init();

    voiceService.autoRestart = true;
    isListening = true;

    print("Voice system initialized and listening...");
  }

  Future<void> _handleConversation(String question) async {
    print('enter _handleConversation');

    // Ignore empty results
    if (question.trim().isEmpty) return;

    voiceService.pauseDuringTTS();
    print('listening paused');

    // Handle stop commands
    if (_isStopCommand(question)) {
      await _endSession();
      return;
    }
    await commandHandler.handleCommand(context, 'questions', question);

    try {
      print("Sending question to Gemini: $question");
      final answer = await _geminiService.generateText(question);
      print("Gemini returned: $answer");

      await tts.speak(answer);
    } catch (e, st) {
      print("Error generating text: $e\n$st");
      await tts.speak("Sorry, I could not process your question.");
    }

    voiceService.resumeAfterTTS();
    print("listening resumed");
  }


  bool _isStopCommand(String text) {
    final stopPhrases = ['stop', 'finish', 'end', 'goodbye', 'bye', 'exit', 'quit'];
    final normalizedText = text.toLowerCase();
    return stopPhrases.any((phrase) => normalizedText.contains(phrase));
  }

  Future<void> _endSession() async {
      await tts.speak("Ending the conversation.");
      Navigator.pop(context);
    }
    
    @override
    void dispose() {
      _animationController.dispose();
      voiceService.uninitialize();
      super.dispose();
    }  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/back.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Ask Any Question' ,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: bgColor.withOpacity(0.5),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(Icons.mic,
                                    size: 80,
                                    color: bgColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20)
                        ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }