import 'package:audoria/models/quiz_question_model.dart';
import 'package:audoria/utils/constants.dart';
import 'package:flutter/material.dart';

class QuizCard extends StatefulWidget {
  final QuizQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final Function(int) onAnswerSelected; // Changed to pass selected index

  const QuizCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.onAnswerSelected,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int? selectedIndex;
  bool isAnswered = false;

  void _selectAnswer(int index) {
    if (isAnswered) return;

    setState(() {
      selectedIndex = index;
      isAnswered = true;
    });

    // Wait a moment to show the result, then move to next
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onAnswerSelected(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = selectedIndex == widget.question.correctAnswerIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with question number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bgColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Question ${widget.questionNumber}/${widget.totalQuestions}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: bgColor,
                  ),
                ),
              ),
              if (isAnswered)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Question text
          Text(
            widget.question.question,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Options
          ...widget.question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedIndex == index;
            final isCorrectOption = index == widget.question.correctAnswerIndex;

            Color? backgroundColor;
            Color? borderColor;
            Color? textColor;

            if (isAnswered) {
              if (isCorrectOption) {
                backgroundColor = Colors.green.withOpacity(0.1);
                borderColor = Colors.green;
                textColor = Colors.green.shade700;
              } else if (isSelected && !isCorrectOption) {
                backgroundColor = Colors.red.withOpacity(0.1);
                borderColor = Colors.red;
                textColor = Colors.red.shade700;
              } else {
                backgroundColor = Colors.grey.shade50;
                borderColor = Colors.grey.shade300;
                textColor = Colors.grey.shade700;
              }
            } else {
              backgroundColor = isSelected
                  ? bgColor.withOpacity(0.1)
                  : Colors.grey.shade50;
              borderColor = isSelected ? bgColor : Colors.grey.shade300;
              textColor = isSelected ? bgColor : Colors.black87;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectAnswer(index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor, width: 2),
                          color: isSelected ? borderColor : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(
                                isAnswered && isCorrectOption
                                    ? Icons.check
                                    : Icons.circle,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${String.fromCharCode(65 + index)}. $option',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
