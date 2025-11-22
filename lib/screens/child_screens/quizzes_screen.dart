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
  final voiceService = VoiceService();
  final GeminiService geminiService = GeminiService();
  final InsightsService insightsService = InsightsService();
  final PageController _pageController = PageController();

  bool isLoading = true;
  List<QuizQuestion> questions = [];
  int currentQuestionIndex = 0;
  Timer? loadingTimer;
  Map<int, int> answers = {}; // questionIndex -> selectedAnswerIndex

  @override
  void initState() {
    super.initState();
    _initializeVoiceSystem();
    _generateQuiz();
  }

  Future<void> _initializeVoiceSystem() async {
    tts = SpeechFeedback();
    commandHandler = CommandHandler(tts: tts);
    voiceService.autoRestart = false;

    voiceService.onResult = (recognizedText) {
      commandHandler.handleCommand(context, 'saved_files', recognizedText);
    };

    voiceService.autoRestart = true;
    await voiceService.init();
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
        await tts.speak(
          'Sorry, this file does not have readable text content. Please try re-uploading the file.',
        );
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

      await tts.speak('Quiz generated. Let\'s start!');
    } catch (e) {
      _stopLoadingMessages();
      setState(() {
        isLoading = false;
      });
      await tts.speak('Sorry, I could not generate a quiz. Please try again.');
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

  void _onAnswerSelected(int questionIndex, int selectedAnswerIndex) {
    // Store the answer
    answers[questionIndex] = selectedAnswerIndex;

    if (currentQuestionIndex < questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      // Quiz completed - calculate results and save
      _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    // Calculate results
    int correctAnswers = 0;
    int wrongAnswers = 0;

    for (int i = 0; i < questions.length; i++) {
      final selectedAnswer = answers[i];
      if (selectedAnswer != null) {
        if (selectedAnswer == questions[i].correctAnswerIndex) {
          correctAnswers++;
        } else {
          wrongAnswers++;
        }
      } else {
        // Question not answered counts as wrong
        wrongAnswers++;
      }
    }

    // Save to insights
    try {
      final childId = insightsService.getCurrentChildId();
      if (childId == null) {
        _showCompletionDialog(
          correctAnswers: correctAnswers,
          totalQuestions: questions.length,
          showError: true,
          errorMessage: 'Child not logged in',
        );
        return;
      }

      final parentId = await insightsService.getParentIdFromChild(childId);
      if (parentId == null) {
        _showCompletionDialog(
          correctAnswers: correctAnswers,
          totalQuestions: questions.length,
          showError: true,
          errorMessage: 'Could not find parent information',
        );
        return;
      }

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Save insights
      await insightsService.saveInsights(
        childId: childId,
        parentId: parentId,
        totalQuestions: questions.length,
        correctAnswers: correctAnswers,
        wrongAnswers: wrongAnswers,
        fileId: widget.selectedFile?.id,
        fileName: widget.selectedFile?.title,
      );

      // Close loading
      if (mounted) {
        Navigator.pop(context);
      }

      // Show completion dialog
      _showCompletionDialog(
        correctAnswers: correctAnswers,
        totalQuestions: questions.length,
        showError: false,
      );
    } catch (e) {
      // Close loading if still open
      if (mounted) {
        Navigator.pop(context);
      }
      _showCompletionDialog(
        correctAnswers: correctAnswers,
        totalQuestions: questions.length,
        showError: true,
        errorMessage: 'Failed to save results: $e',
      );
    }
  }

  void _showCompletionDialog({
    required int correctAnswers,
    required int totalQuestions,
    required bool showError,
    String? errorMessage,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(showError ? 'Error' : 'Quiz Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showError) ...[
              Text('Great job completing the quiz!'),
              const SizedBox(height: 16),
              Text(
                'Score: $correctAnswers/$totalQuestions',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              Text(errorMessage ?? 'An error occurred'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopLoadingMessages();
    _pageController.dispose();
    voiceService.uninitialize();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
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
                      child: Icon(Icons.arrow_back, color: textColor, size: 20),
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

            // Progress indicator
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

            // Content
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
                              'assets/animations/quizzes.json',
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
                  : PageView.builder(
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
          ],
        ),
      ),
    );
  }
}
