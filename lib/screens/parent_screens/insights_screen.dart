import 'package:audoria/models/insights_model.dart';
import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/insights_service.dart';
import 'package:audoria/widgets/custom_appbar.dart';
import 'package:audoria/widgets/custom_insight_item.dart';
import 'package:audoria/widgets/custom_bottom_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audoria/widgets/custom_insight_card.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final InsightsService _insightsService = InsightsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<InsightsModel> _insights = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parentId = _auth.currentUser?.uid;
      if (parentId == null) {
        setState(() {
          _errorMessage = 'Parent not logged in';
          _isLoading = false;
        });
        return;
      }

      // Fetch all insights for parent's children
      final insights = await _insightsService.getParentChildrenInsights(
        parentId,
      );

      // Calculate aggregated statistics
      final stats = _calculateStatistics(insights);

      setState(() {
        _insights = insights;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load insights: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateStatistics(List<InsightsModel> insights) {
    if (insights.isEmpty) {
      return {
        'totalCompletedQuizzes': 0,
        'totalQuestions': 0,
        'totalCorrect': 0,
        'totalWrong': 0,
        'averageAccuracy': 0.0,
      };
    }

    int totalQuestions = 0;
    int totalCorrect = 0;
    int totalWrong = 0;

    for (var insight in insights) {
      totalQuestions += insight.totalQuestions;
      totalCorrect += insight.correctAnswers;
      totalWrong += insight.wrongAnswers;
    }

    final averageAccuracy = totalQuestions > 0
        ? (totalCorrect / totalQuestions) * 100
        : 0.0;

    return {
      'totalCompletedQuizzes': insights.length,
      'totalQuestions': totalQuestions,
      'totalCorrect': totalCorrect,
      'totalWrong': totalWrong,
      'averageAccuracy': averageAccuracy,
    };
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          const CustomAppbar(),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadInsights,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _insights.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.insights_outlined,
                            size: 64,
                            color: textColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No insights available yet',
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Insights will appear here once your child completes question sessions',
                            style: TextStyle(
                              color: textColor.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary cards in 2x2 grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.3,
                            children: [
                              CustomInsightCard(
                                icon: Icons.quiz,
                                number: _statistics['totalCompletedQuizzes'] ?? 0,
                                label: 'Completed Quizzes',
                              ),
                              CustomInsightCard(
                                icon: Icons.help_outline,
                                number: _statistics['totalQuestions'] ?? 0,
                                label: 'Total Questions',
                              ),
                              CustomInsightCard(
                                icon: Icons.check_circle,
                                number: _statistics['totalCorrect'] ?? 0,
                                label: 'Total Correct',
                              ),
                              CustomInsightCard(
                                icon: Icons.cancel,
                                number: _statistics['totalWrong'] ?? 0,
                                label: 'Total Wrong',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Progress
                          const Text(
                            'Average Accuracy',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (_statistics['averageAccuracy'] ?? 0.0) / 100,
                            color: Colors.green,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_statistics['averageAccuracy'] ?? 0.0).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Recent activity
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadInsights,
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Recent insights list
                          ..._insights.map((insight) {
                            final title = insight.fileName != null
                                ? 'Quiz: ${insight.fileName}'
                                : 'Question Session';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CustomInsightItem(
                                title: title,
                                subtitle:
                                    'Completed on ${_formatDate(insight.completedAt)}',
                                result: insight.scoreString,
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
