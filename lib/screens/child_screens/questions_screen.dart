import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/insights_service.dart';
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

  // Insights tracking
  final InsightsService _insightsService = InsightsService();
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  bool _isSessionActive = false;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Method to record a correct answer (to be called when question is answered correctly)
  void recordCorrectAnswer() {
    setState(() {
      _totalQuestions++;
      _correctAnswers++;
      _isSessionActive = true;
    });
  }

  // Method to record a wrong answer (to be called when question is answered incorrectly)
  void recordWrongAnswer() {
    setState(() {
      _totalQuestions++;
      _wrongAnswers++;
      _isSessionActive = true;
    });
  }

  // Method to finish the session and save insights to Firestore
  Future<void> finishSession() async {
    if (!_isSessionActive || _totalQuestions == 0) {
      // No questions answered, just go back
      Navigator.pop(context);
      return;
    }

    try {
      final childId = _insightsService.getCurrentChildId();
      if (childId == null) {
        _showError('Child not logged in');
        return;
      }

      final parentId = await _insightsService.getParentIdFromChild(childId);
      if (parentId == null) {
        _showError('Could not find parent information');
        return;
      }

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Save insights to Firestore
      await _insightsService.saveInsights(
        childId: childId,
        parentId: parentId,
        totalQuestions: _totalQuestions,
        correctAnswers: _correctAnswers,
        wrongAnswers: _wrongAnswers,
      );

      // Close loading indicator
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Great job! You answered $_totalQuestions questions. '
              'Score: $_correctAnswers/$_totalQuestions',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to previous screen
      }
    } catch (e) {
      // Close loading indicator if still open
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      _showError('Failed to save insights: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
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
                      // Microphone Icon with Animation
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
                                child: Icon(
                                  Icons.mic,
                                  size: 80,
                                  color: bgColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 50),

                      // Title
                      Text(
                        'Ask Any Question',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Listening Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: textColor.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Listening...',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Helper Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Speak clearly and your question will be answered!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ),

                      // Session Stats (shown when questions are answered)
                      if (_isSessionActive) ...[
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: textColor.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Session Progress',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    'Total',
                                    '$_totalQuestions',
                                    Colors.blue,
                                  ),
                                  _buildStatItem(
                                    'Correct',
                                    '$_correctAnswers',
                                    Colors.green,
                                  ),
                                  _buildStatItem(
                                    'Wrong',
                                    '$_wrongAnswers',
                                    Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Finish Button (shown when session is active)
                      if (_isSessionActive) ...[
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: finishSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bgColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Finish Session',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
        ),
      ],
    );
  }
}
