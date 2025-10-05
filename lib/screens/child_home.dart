import 'package:flutter/material.dart';

import '../custom_widgets/custom_card.dart';
import '../custom_widgets/custom_text.dart';
import '../custom_widgets/custom_bottom_navbar.dart';

class ChildHomePage extends StatelessWidget {
  final String username;
  const ChildHomePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9BB9FF),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: CustomText.username('Hello, $username')),
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.black, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              CustomText.subtitle('Lets study together'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: const [
                  CustomCard(
                    imagePath: 'assets/images/lesson.png',
                    label: 'LESSON',
                  ),
                  CustomCard(
                    imagePath: 'assets/images/camera.png',
                    label: 'CAMERA',
                  ),
                  CustomCard(
                    imagePath: 'assets/images/question.png',
                    label: 'ASK\nQUESTION',
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
