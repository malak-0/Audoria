import 'package:audoria/utils/voice_navigation/commands_handler.dart';
import 'package:audoria/utils/voice_navigation/listen.dart';
import 'package:audoria/utils/voice_navigation/speak.dart';
import 'package:audoria/utils/constants.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_text.dart';
import '../../widgets/custom_bottom_navbar.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  final String username = "Malak";

  late SpeechFeedback tts;
  late CommandHandler commandHandler;
  final voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _initializeVoiceSystem();
  }

  Future<void> _initializeVoiceSystem() async {
    tts = SpeechFeedback();
    commandHandler = CommandHandler(tts: tts);
    voiceService.autoRestart = false;

    voiceService.onResult = (recognizedText) {
      commandHandler.handleCommand(context, 'home_page', recognizedText);
    };

    await tts.speak(
      "Welcome $username. You are on the home screen. Say camera, saved files, or questions.",
    );

    voiceService.autoRestart = true;

    await voiceService.init();
  }

  @override
  void dispose() {
    voiceService.uninitialize();
    super.dispose();
  }

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
                    child: Icon(Icons.person, color: textColor, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              CustomText.subtitle('Lets study together'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  CustomCard(
                    imagePath: 'assets/images/lesson.png',
                    label: 'LESSON',
                    routeName: "all_lessons",
                  ),
                  const CustomCard(
                    imagePath: 'assets/images/camera.png',
                    label: 'CAMERA',
                  ),
                  const CustomCard(
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
