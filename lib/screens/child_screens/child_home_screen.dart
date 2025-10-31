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
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          CustomText.username(username),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: textColor.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: textColor, size: 30),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                // Welcome Section
                Container(
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          color: bgColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Let\'s Study Together!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Choose an option to start learning',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Options Section
                Text(
                  'What would you like to do?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 24),

                // Cards Grid
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  alignment: WrapAlignment.start,
                  children: [
                    CustomCard(
                      imagePath: 'assets/images/lesson.png',
                      label: 'LESSON',
                      routeName: "saved_files",
                    ),
                    const CustomCard(
                      imagePath: 'assets/images/camera.png',
                      label: 'CAMERA',
                      routeName: "camera_capture",
                    ),
                    const CustomCard(
                      imagePath: 'assets/images/question.png',
                      label: 'ASK\nQUESTION',
                      routeName: "questions",
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
