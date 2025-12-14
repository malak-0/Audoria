import 'package:audoria/utils/navigation_services/voice_navigation/commands_handler.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/backend_services/firebase_helpers.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_bottom_navbar.dart';
import '../../widgets/custom_appbar.dart';
import '../../main.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> with RouteAware {
  late SpeechFeedback tts;
  late CommandHandler commandHandler;
  final voiceService = VoiceService();
  bool _isVoiceInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceSystem();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    _reinitializeVoiceAfterReturn();
  }

  Future<void> _reinitializeVoiceAfterReturn() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    _isVoiceInitialized = false;
    await _initializeVoiceSystem();
  }

  Future<void> _initializeVoiceSystem() async {
    if (_isVoiceInitialized) return;

    // Wait a bit longer to ensure previous screen's cleanup is complete
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Hard reset voice service to ensure clean state
    await voiceService.hardReset();

    tts = SpeechFeedback();
    commandHandler = CommandHandler(tts: tts);
    commandHandler.setVoiceService(voiceService);
    voiceService.autoRestart = false;

    voiceService.onResult = (recognizedText) {
      if (mounted) {
        commandHandler.handleCommand(context, 'child_home', recognizedText);
      }
    };

    voiceService.autoRestart = true;

    await voiceService.init();
    _isVoiceInitialized = true;

    // Speak welcome message after voice service is initialized
    if (mounted) {
      final username = await getChildUsername();
      await voiceService.pauseDuringTTS();
      await tts.speak(
        "Welcome $username. You are on the home screen. Say camera, lesson, or questions.",
      ); // Wait for TTS to complete
      await voiceService.resumeAfterTTS();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _isVoiceInitialized = false;
    tts.stop();
    voiceService.uninitialize();
    commandHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: const CustomAppbar(showBackButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section with enhanced design
                Container(
                  padding: const EdgeInsets.all(20),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [bgColor, bgColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: textColor.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: getChildUsername(),
                          builder: (context, snapshot) {
                            final username = snapshot.data ?? 'Child';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome,',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor.withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  username,
                                  style: TextStyle(
                                    fontSize: 26,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Subtitle with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.school, color: textColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Let\'s study together',
                      style: TextStyle(
                        fontSize: 22,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                // Cards Grid with improved layout
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 0.85,
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
