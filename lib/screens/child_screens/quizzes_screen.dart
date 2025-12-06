import 'package:audoria/models/lesson_file_model.dart';
import 'package:audoria/models/quiz_question_model.dart';
import 'package:audoria/utils/ai_services/gemini.dart';
import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/insights_service.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/commands_handler.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:audoria/widgets/quiz_card.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class QuizzesScreen extends StatefulWidget {
  final LessonFile? selectedFile;

  const QuizzesScreen({super.key, this.selectedFile});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  late SpeechFeedback tts;
  late CommandHandler commandHandler;
  final VoiceService mainVoiceService = VoiceService();
  final GeminiService geminiService = GeminiService();
  final InsightsService insightsService = InsightsService();
  final PageController _pageController = PageController();

  // SIMPLE QUIZ VOICE SYSTEM
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool _isReadingQuestion = false;
  bool _isListeningForAnswer = false;

  bool isLoading = true;
  List<QuizQuestion> questions = [];
  int currentQuestionIndex = 0;
  Timer? loadingTimer;
  Map<int, int> answers = {};
  
  List<String> _voiceAnswerLetters = ['a', 'b', 'c', 'd'];
  String _lastRecognizedText = '';

  @override
  void initState() {
    super.initState();
    tts = SpeechFeedback();
    commandHandler = CommandHandler(tts: tts);
    _initializeQuizVoiceSystem();
    _generateQuiz();
  }

  Future<void> _initializeQuizVoiceSystem() async {
    try {
      print("🎤 QUIZ: Stopping main VoiceService first...");
      
      // Stop the main voice service before starting quiz voice
      await mainVoiceService.stop();
      await mainVoiceService.uninitialize();
      print("✅ QUIZ: Main VoiceService stopped");
      
      // Wait a bit to ensure microphone is released
      await Future.delayed(const Duration(milliseconds: 500));
      
      print("🎤 QUIZ: Initializing simple quiz voice system...");
      
      _isSpeechInitialized = await _speech.initialize(
        onStatus: (status) {
          print("🎤 QUIZ: Speech status: $status");
          
          // If we're supposed to be listening but we're not, restart
          if (_isListeningForAnswer && !_isListening && status == 'notListening') {
            print("🎤 QUIZ: Detected notListening status, restarting...");
            _startQuizListening();
          }
        },
        onError: (error) {
          print("🎤 QUIZ: Speech error: $error");
          
          // Reset on error
          _isListening = false;
          if (_isListeningForAnswer) {
            print("🎤 QUIZ: Error occurred, restarting listening...");
            _startQuizListening();
          }
        },
      );
      
      if (_isSpeechInitialized) {
        print("✅ QUIZ: Simple quiz voice system initialized successfully!");
      } else {
        print("❌ QUIZ: Simple quiz voice system failed to initialize");
      }
    } catch (e) {
      print("❌ QUIZ: Error initializing simple voice system: $e");
    }
  }

  Future<void> _startQuizListening() async {
    if (!_isSpeechInitialized || _isListening || !_isListeningForAnswer) {
      print("🎤 QUIZ: Cannot start listening - initialized: $_isSpeechInitialized, listening: $_isListening, for answer: $_isListeningForAnswer");
      return;
    }

    try {
      print("🎤 QUIZ: Starting quiz listening...");
      
      // Stop any existing listening first
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Start fresh listening session
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _handleQuizVoiceInput(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: false,
        partialResults: false,
        listenMode: stt.ListenMode.dictation,
      );
      
      print("✅ QUIZ: Quiz listening started successfully");
    } catch (e) {
      print("❌ QUIZ: Error starting quiz listening: $e");
      _isListening = false;
      
      // Try again after delay
      if (_isListeningForAnswer) {
        print("🔄 QUIZ: Retrying to start listening in 1 second...");
        Timer(const Duration(seconds: 1), () {
          _startQuizListening();
        });
      }
    }
  }

  Future<void> _stopQuizListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        print("🎤 QUIZ: Quiz listening stopped");
      }
    } catch (e) {
      print("❌ QUIZ: Error stopping quiz listening: $e");
    }
  }

  void _handleQuizVoiceInput(String recognizedText) {
    print("🎤 QUIZ: === VOICE CAPTURED: '$recognizedText' ===");
    
    recognizedText = recognizedText.toLowerCase().trim();
    _lastRecognizedText = recognizedText;
    
    // Simple, direct matching
    if (recognizedText == 'a' || 
        recognizedText == 'one' || 
        recognizedText == '1' ||
        recognizedText == 'first') {
      print("✅ QUIZ: Selected option A");
      _selectQuizAnswer(0);
    } 
    else if (recognizedText == 'b' || 
             recognizedText == 'two' || 
             recognizedText == '2' ||
             recognizedText == 'second') {
      print("✅ QUIZ: Selected option B");
      _selectQuizAnswer(1);
    }
    else if (recognizedText == 'c' || 
             recognizedText == 'three' || 
             recognizedText == '3' ||
             recognizedText == 'third') {
      print("✅ QUIZ: Selected option C");
      _selectQuizAnswer(2);
    }
    else if (recognizedText == 'd' || 
             recognizedText == 'four' || 
             recognizedText == '4' ||
             recognizedText == 'fourth') {
      print("✅ QUIZ: Selected option D");
      _selectQuizAnswer(3);
    }
    else if (recognizedText.contains('a')) {
      print("✅ QUIZ: Contains 'a', selecting option A");
      _selectQuizAnswer(0);
    }
    else if (recognizedText.contains('b')) {
      print("✅ QUIZ: Contains 'b', selecting option B");
      _selectQuizAnswer(1);
    }
    else if (recognizedText.contains('c')) {
      print("✅ QUIZ: Contains 'c', selecting option C");
      _selectQuizAnswer(2);
    }
    else if (recognizedText.contains('d')) {
      print("✅ QUIZ: Contains 'd', selecting option D");
      _selectQuizAnswer(3);
    }
    else {
      print("❌ QUIZ: Unrecognized input: '$recognizedText'");
      print("🎤 QUIZ: Expected: a, b, c, d, 1, 2, 3, 4, one, two, three, four");
    }
  }

  void _selectQuizAnswer(int answerIndex) {
    if (currentQuestionIndex < questions.length) {
      print("🎯 QUIZ: Processing answer $answerIndex for question $currentQuestionIndex");
      _onAnswerSelected(currentQuestionIndex, answerIndex);
    }
  }

  Future<void> _readCurrentQuestion() async {
    if (currentQuestionIndex >= questions.length) return;
    
    setState(() {
      _isReadingQuestion = true;
      _isListeningForAnswer = false;
    });
    
    // Stop listening while reading
    await _stopQuizListening();
    
    final question = questions[currentQuestionIndex];
    
    // Read question with pauses
    await tts.speak("Question ${currentQuestionIndex + 1}.");
    await Future.delayed(const Duration(milliseconds: 800));
    await tts.speak(question.question);
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Read options
    for (int i = 0; i < question.options.length; i++) {
      await tts.speak("Option ${_voiceAnswerLetters[i].toUpperCase()}: ${question.options[i]}");
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Simple instruction
    await tts.speak("Say A, B, C, or D for your answer.");
    await Future.delayed(const Duration(seconds: 1));
    
    // Start listening for answer
    setState(() {
      _isReadingQuestion = false;
      _isListeningForAnswer = true;
    });
    
    _startQuizListening();
  }

  Future<void> _generateQuiz() async {
    try {
      String? content;

      if (widget.selectedFile != null) {
        content = widget.selectedFile!.content;
      }

      final isValidContent =
          content != null &&
          content.isNotEmpty &&
          content.trim().isNotEmpty &&
          content != 'Text extraction not available for this file type';

      if (!isValidContent) {
        setState(() {
          isLoading = false;
        });
        await tts.speak('Sorry, this file does not have readable text content.');
        return;
      }

      _startLoadingMessages();

      final questionsJson = await geminiService.generateQuizFromContent(
        content,
      );
      final generatedQuestions = questionsJson
          .map((q) => QuizQuestion.fromMap(q))
          .toList();

      _stopLoadingMessages();

      setState(() {
        isLoading = false;
        questions = generatedQuestions;
      });

      // Start reading first question
      if (generatedQuestions.isNotEmpty) {
        await _readCurrentQuestion();
      } else {
        await tts.speak('No questions were generated.');
      }
    } catch (e) {
      _stopLoadingMessages();
      setState(() {
        isLoading = false;
      });
      await tts.speak('Sorry, I could not generate a quiz.');
    }
  }

  void _startLoadingMessages() {
    loadingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (isLoading && mounted) {
        await tts.speak("Generating quiz");
      } else {
        timer.cancel();
      }
    });
  }

  void _stopLoadingMessages() {
    loadingTimer?.cancel();
    loadingTimer = null;
  }

  void _onAnswerSelected(int questionIndex, int selectedAnswerIndex) async {
    // Stop listening immediately
    await _stopQuizListening();
    setState(() {
      _isListeningForAnswer = false;
    });
    
    // Store the answer
    answers[questionIndex] = selectedAnswerIndex;
    
    // Give feedback
    final question = questions[questionIndex];
    final isCorrect = selectedAnswerIndex == question.correctAnswerIndex;
    
    if (isCorrect) {
      await tts.speak("Correct!");
    } else {
      await tts.speak("Incorrect. The answer is ${_voiceAnswerLetters[question.correctAnswerIndex].toUpperCase()}.");
    }
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (currentQuestionIndex < questions.length - 1) {
      // Next question
      setState(() {
        currentQuestionIndex++;
      });
      
      // Animate to next page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      await tts.speak("Next question.");
      await Future.delayed(const Duration(seconds: 1));
      
      await _readCurrentQuestion();
    } else {
      // Quiz completed
      await tts.speak("Quiz completed.");
      await _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    // Calculate results
    int correctAnswers = 0;
    for (int i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }

    // Save to insights if available
    try {
      final childId = insightsService.getCurrentChildId();
      if (childId != null) {
        final parentId = await insightsService.getParentIdFromChild(childId);
        if (parentId != null) {
          await insightsService.saveInsights(
            childId: childId,
            parentId: parentId,
            totalQuestions: questions.length,
            correctAnswers: correctAnswers,
            wrongAnswers: questions.length - correctAnswers,
            fileId: widget.selectedFile?.id,
            fileName: widget.selectedFile?.title,
          );
        }
      }
    } catch (e) {
      print("Error saving insights: $e");
    }

    // Show completion dialog
    _showCompletionDialog(correctAnswers: correctAnswers, totalQuestions: questions.length);
  }

  void _showCompletionDialog({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quiz Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Great job completing the quiz!'),
            const SizedBox(height: 16),
            Text(
              'Score: $correctAnswers/$totalQuestions',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Restart main voice service before going back
              _restartMainVoiceService();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _restartMainVoiceService() async {
    try {
      print("🎤 QUIZ: Restarting main VoiceService...");
      await mainVoiceService.init();
      print("✅ QUIZ: Main VoiceService restarted");
    } catch (e) {
      print("❌ QUIZ: Error restarting main VoiceService: $e");
    }
  }

  Future<void> _repeatQuestion() async {
    if (currentQuestionIndex < questions.length) {
      await _readCurrentQuestion();
    }
  }

  @override
  void dispose() {
    _stopLoadingMessages();
    _stopQuizListening();
    _pageController.dispose();
    commandHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header (from first code with voice status)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _restartMainVoiceService();
                      Navigator.pop(context);
                    },
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
                      child: Icon(Icons.arrow_back, color: textColor, size: 20),
                    ),
                  ),
                  const Spacer(),
                  
                  // Voice status indicator
                  if (!isLoading && questions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isReadingQuestion
                            ? Colors.blue.withOpacity(0.1)
                            : _isListeningForAnswer
                                ? Colors.green.withOpacity(0.1)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isReadingQuestion
                                ? Icons.volume_up
                                : _isListeningForAnswer
                                    ? Icons.mic
                                    : Icons.quiz,
                            size: 16,
                            color: _isReadingQuestion
                                ? Colors.blue
                                : _isListeningForAnswer
                                    ? Colors.green
                                    : bgColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isReadingQuestion
                                ? 'Reading'
                                : _isListeningForAnswer
                                    ? 'Listening'
                                    : 'Voice Quiz',
                            style: TextStyle(
                              fontSize: 14,
                              color: _isReadingQuestion
                                  ? Colors.blue
                                  : _isListeningForAnswer
                                      ? Colors.green
                                      : textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz, color: bgColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Quiz',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator (from first code)
            if (!isLoading && questions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Question ${currentQuestionIndex + 1} of ${questions.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${((currentQuestionIndex + 1) / questions.length * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

            // Content area with PageView (from first code)
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: textColor.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Lottie.asset(
                              'assets/animations/quizes.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 40),
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            'Generating quiz questions...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : questions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: textColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quiz questions available',
                            style: TextStyle(
                              fontSize: 18,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // PageView for questions
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: questions.length,
                            itemBuilder: (context, index) {
                              return QuizCard(
                                question: questions[index],
                                questionNumber: index + 1,
                                totalQuestions: questions.length,
                                onAnswerSelected: (selectedIndex) =>
                                    _onAnswerSelected(index, selectedIndex),
                              );
                            },
                          ),
                        ),
                        
                        // Voice controls (from second code)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: textColor.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Voice instructions
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _isListeningForAnswer
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isListeningForAnswer ? Icons.mic : Icons.info_outline,
                                        color: _isListeningForAnswer ? Colors.green : Colors.blue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _isListeningForAnswer
                                              ? 'Say "A", "B", "C", or "D" to answer'
                                              : 'Question will be read aloud automatically',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _isListeningForAnswer ? Colors.green : Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}