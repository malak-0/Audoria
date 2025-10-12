import 'package:audoria/widgets/custom_insight_item.dart';
import 'package:flutter/material.dart';
import 'package:audoria/widgets/custom_insight_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Summary cards
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  CustomInsightCard(
                    icon: Icons.book,
                    number: 12,
                    label: 'Total Lessons',
                  ),
                  CustomInsightCard(
                    icon: Icons.check_circle,
                    number: 8,
                    label: 'Completed',
                  ),
                  CustomInsightCard(
                    icon: Icons.pending,
                    number: 4,
                    label: 'Pending',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Progress
            const Text(
              'Lesson Completion Rate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.75,
              color: Colors.green,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 30),
            // Recent activity
            const Text(
              'Recent Activity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: const [
                  CustomInsightItem(
                    title: 'Math - Lesson 2',
                    subtitle: 'Listened on 5 Feb 2025',
                    result: '8/10',
                  ),
                  CustomInsightItem(
                    title: 'English - Lesson 3',
                    subtitle: 'Listened on 6 Feb 2025',
                    result: '9/10',
                  ),
                  CustomInsightItem(
                    title: 'Science - Lesson 1',
                    subtitle: 'Listened on 10 Feb 2025',
                    result: '7/10',
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
