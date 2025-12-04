// import 'package:audoria/utils/ai_services/gemini.dart';
// import 'package:audoria/utils/constants.dart';
// import 'package:audoria/utils/navigation_services/voice_navigation/commands_handler.dart';
// import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';
// import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
// import 'package:flutter/material.dart';

// class QuestionsScreen extends StatefulWidget {
//   const QuestionsScreen({super.key});

//   @override
//   State<QuestionsScreen> createState() => _QuestionsScreenState();
// }

// class _QuestionsScreenState extends State<QuestionsScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   final GeminiService _geminiService = GeminiService();
  
//   bool isProcessing = false;
//   bool isListening = false;
//   bool isSpeaking = false; 
//   late SpeechFeedback tts;
//   late CommandHandler commandHandler;
//   final voiceService = VoiceService();

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat(reverse: true);

//     _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//     _initializeVoiceSystem();
//   }

//   Future<void> _initializeVoiceSystem() async {
//     tts = SpeechFeedback();
//     commandHandler = CommandHandler(tts: tts);

//     voiceService.onResult = (question) async {
//       print("User said: $question");
//       await _handleConversation(question);
//       return question;
//     };

//     await tts.speak('Wait 2 seconds to start the conversation');
//     await voiceService.init();

//     voiceService.autoRestart = true;
//     isListening = true;

//     print("Voice system initialized and listening...");
//   }

//   Future<void> _handleConversation(String question) async {
//     print('enter _handleConversation');

//     // Ignore empty results
//     if (question.trim().isEmpty) return;

//     voiceService.pauseDuringTTS();
//     print('listening paused');

//     // Handle stop commands
//     if (_isStopCommand(question)) {
//       await _endSession();
//       return;
//     }
//     await commandHandler.handleCommand(context, 'questions', question);

//     try {
//       print("Sending question to Gemini: $question");
//       final answer = await _geminiService.generateText(question);
//       print("Gemini returned: $answer");

//       await tts.speak(answer);
//     } catch (e, st) {
//       print("Error generating text: $e\n$st");
//       await tts.speak("Sorry, I could not process your question.");
//     }

//     voiceService.resumeAfterTTS();
//     print("listening resumed");
//   }


//   bool _isStopCommand(String text) {
//     final stopPhrases = ['stop', 'finish', 'end', 'goodbye', 'bye', 'exit', 'quit'];
//     final normalizedText = text.toLowerCase();
//     return stopPhrases.any((phrase) => normalizedText.contains(phrase));
//   }

//   Future<void> _endSession() async {
//       await tts.speak("Ending the conversation.");
//       Navigator.pop(context);
//     }
    
//     @override
//     void dispose() {
//       _animationController.dispose();
//       voiceService.uninitialize();
//       super.dispose();
//     }  
//     @override
//     Widget build(BuildContext context) {
//       return Scaffold(
//         backgroundColor: bgColor,
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
//             child: Column(
//               children: [
//                 // Back Button
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: textColor.withOpacity(0.1),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Image.asset(
//                       'assets/images/back.png',
//                       width: 20,
//                       height: 20,
//                     ),
//                   ),
//                 ),
                
//                 // Main Content
//                 Expanded(
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text('Ask Any Question' ,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: textColor,
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         AnimatedBuilder(
//                           animation: _scaleAnimation,
//                           builder: (context, child) {
//                             return Transform.scale(
//                               scale: _scaleAnimation.value,
//                               child: Container(
//                                 width: 180,
//                                 height: 180,
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: Colors.white,
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: bgColor.withOpacity(0.5),
//                                       blurRadius: 30,
//                                       spreadRadius: 10,
//                                     ),
//                                   ],
//                                 ),
//                                 child: Center(
//                                   child: Icon(Icons.mic,
//                                     size: 80,
//                                     color: bgColor,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                         const SizedBox(height: 20)
//                         ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//   }







import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audoria/utils/ai_services/gemini.dart';
import 'package:audoria/utils/voice_services/voice.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({Key? key}) : super(key: key);

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class Message {
  final String text;
  final bool fromUser;
  Message(this.text, this.fromUser);
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final Voice _voice = Voice.instance;
  final GeminiService geminiService = GeminiService();
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  late final StreamSubscription<String> _partialSub;
  late final StreamSubscription<String> _finalSub;
  late final StreamSubscription<bool> _speakingSub;

  String _partialText = '';
  bool _speaking = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    
    _partialSub = _voice.partialTextStream.listen((text) {
      if (mounted) {
        setState(() => _partialText = text);
      }
    });

    _finalSub = _voice.finalTextStream.listen((text) async {
      if (mounted && text.trim().isNotEmpty && !_isProcessing) {
        await _processQuestion(text);
      }
    });

    _speakingSub = _voice.isSpeakingStream.listen((isSpeaking) {
      if (mounted) {
        setState(() => _speaking = isSpeaking);
      }
      
      // When speaking stops, restart listening
      if (!isSpeaking && !_voice.isListening && !_isProcessing && mounted) {
        _startContinuousListening();
      }
    });

    _startContinuousListening();
  }

  Future<void> _startContinuousListening() async {
    if (!_voice.isListening && !_speaking && !_isProcessing && mounted) {
      await _voice.startListening();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _processQuestion(String question) async {
    if (question.trim().isEmpty || _isProcessing || !mounted) return;
    
    _isProcessing = true;
    
    // Stop listening while processing
    if (_voice.isListening) {
      await _voice.stopListening();
    }
    
    if (mounted) {
      setState(() {
        _partialText = "";
        _messages.insert(0, Message(question, true));
      });
    }

    String answer;
    try {
      answer = await geminiService.generateText(question);
    } catch (e) {
      answer = 'Sorry, I failed to get an answer.';
    }

    if (mounted) {
      setState(() {
        _messages.insert(0, Message(answer, false));
      });
    }

    // Speak the answer
    await _voice.speak(answer);
    
    // Reset processing flag
    _isProcessing = false;
    
    // Restart listening after speaking (handled by speakingSub)
  }

  Future<void> _sendTextQuestion(String question) async {
    if (question.trim().isEmpty || _isProcessing) return;
    
    // Temporarily stop listening
    if (_voice.isListening) {
      await _voice.stopListening();
    }
    
    await _processQuestion(question);
  }

  @override
  void dispose() {
    _textController.dispose();
    _partialSub.cancel();
    _finalSub.cancel();
    _speakingSub.cancel();
    _voice.dispose();
    super.dispose();
  }

  Widget _buildMessageTile(Message m) => Semantics(
    label: m.fromUser ? 'You said: ${m.text}' : 'Answer: ${m.text}',
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: m.fromUser ? Colors.blue.shade700 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        m.text,
        style: TextStyle(
          color: m.fromUser ? Colors.white : Colors.black87,
          fontSize: 20,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Questions'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      _partialText.isNotEmpty
                          ? _partialText
                          : 'Speak to ask a question... I\'m listening',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, idx) =>
                        _buildMessageTile(_messages[idx]),
                  ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Or type your question here...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: _sendTextQuestion,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _sendTextQuestion(_textController.text),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isProcessing
                      ? 'Processing...'
                      : (_speaking
                          ? 'Speaking...'
                          : (_voice.isListening ? 'Listening...' : 'Idle')),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  button: true,
                  label: 'Stop speaking',
                  child: ElevatedButton(
                    onPressed: _voice.isSpeaking
                        ? () => _voice.stopSpeaking()
                        : null,
                    child: const Icon(Icons.stop),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}