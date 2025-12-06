import 'package:audoria/models/lesson_file_model.dart';
import 'package:audoria/utils/navigation_services/navigation_helper.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/commands_handler.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:audoria/widgets/lottie_card.dart';
import 'package:audoria/data/single_file_list.dart';
import 'package:audoria/utils/constants.dart';
import 'package:flutter/material.dart';

class SingleFileScreen extends StatefulWidget {
  final LessonFile selectedFile;

  const SingleFileScreen({super.key, required this.selectedFile});

  @override
  State<SingleFileScreen> createState() => _SingleFileScreenState();
}

class _SingleFileScreenState extends State<SingleFileScreen> {
  NavigationHelper navigationHelper = NavigationHelper();
  late SpeechFeedback tts;
  late CommandHandler commandHandler;
  final voiceService = VoiceService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    print("=== SINGLE FILE SCREEN INIT ===");
    
    // Delay initialization to ensure previous screen is cleaned up
    Future.delayed(const Duration(milliseconds: 300), () {
      _initializeVoiceSystem();
    });
  }

  Future<void> _initializeVoiceSystem() async {
    if (_isInitialized) return;
    
    print("Initializing voice system for SingleFileScreen");
    
    // Wait a bit to ensure previous screen's cleanup is complete
    await Future.delayed(const Duration(milliseconds: 300));
    
    tts = SpeechFeedback();
    commandHandler = CommandHandler(tts: tts);
    
    // Hard reset the voice service first
    await voiceService.hardReset();
    
    // Connect voice service to command handler
    commandHandler.setVoiceService(voiceService);
    
    voiceService.autoRestart = false;
    voiceService.onResult = (recognizedText) {
      print("=== VOICE ON SINGLE FILE: $recognizedText ===");
      commandHandler.handleCommand(
        context,
        'single_file_screen',
        recognizedText,
        arguments: widget.selectedFile.toFullMap(),
      );
    };

    // Start voice service
    voiceService.autoRestart = true;
    await voiceService.init();
    
    _isInitialized = true;
    
    // Speak a short instruction
    await Future.delayed(const Duration(milliseconds: 500));
    await voiceService.pauseDuringTTS();
    await tts.speak("File screen. Say summarize, quiz, or read.");
    await Future.delayed(const Duration(seconds: 1));
    await voiceService.resumeAfterTTS();
  }

  Future<void> _readFile() async {
    try {
      final content = widget.selectedFile.content;

      if (content == null || content.isEmpty || content.trim().isEmpty) {
        await voiceService.pauseDuringTTS();
        await tts.speak(
          "Sorry, this file doesn't have readable text content.",
        );
        await Future.delayed(const Duration(seconds: 1));
        await voiceService.resumeAfterTTS();
        return;
      }

      await voiceService.pauseDuringTTS();
      await tts.stop();
      await tts.speak("Reading the file now.");
      await Future.delayed(const Duration(milliseconds: 800));
      await tts.speak(content);
      await Future.delayed(const Duration(seconds: 1));
      await voiceService.resumeAfterTTS();

    } catch (e) {
      await tts.speak("Sorry, I couldn't read the file. Please try again.");
    }
  }

  void _cleanupVoiceSystem() {
    print("Cleaning up SingleFileScreen voice system");
    // Stop TTS first
    tts.stop();
    // Uninitialize voice service
    voiceService.uninitialize();
    // Dispose command handler
    commandHandler.dispose();
    _isInitialized = false;
  }

  @override
  void dispose() {
    print("=== SINGLE FILE SCREEN DISPOSE ===");
    _cleanupVoiceSystem();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Container(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _cleanupVoiceSystem();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: textColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: textColor, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    SizedBox(width: 20,),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getFileTypeIcon(widget.selectedFile.fileType),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedFile.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Added horizontal padding
                child: ListView.builder(
                  itemCount: fileOptionsList.length,
                  itemBuilder: (context, index) {
                    final fileOption = fileOptionsList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: LottieCard(
                        fileOptions: fileOption,
                        onTap: () async {
                          await voiceService.pauseDuringTTS();
                          
                          if (fileOption.title.toLowerCase() == 'read file') {
                            await _readFile();
                          } else if (fileOption.routeName != null) {
                            if (fileOption.routeName == 'summarization' ||
                                fileOption.routeName == 'quizzes') {
                              final fileMap = widget.selectedFile.toFullMap();
                              NavigationHelper.goTo(
                                context,
                                fileOption.routeName!,
                                arguments: {'fileData': fileMap},
                              );
                            } else {
                              NavigationHelper.goTo(
                                context,
                                fileOption.routeName!,
                              );
                            }
                          }
                          
                          await Future.delayed(const Duration(milliseconds: 500));
                          await voiceService.resumeAfterTTS();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
        return Icons.description;
      case 'PPT':
        return Icons.slideshow;
      case 'MP4':
        return Icons.videocam;
      case 'MP3':
        return Icons.audiotrack;
      case 'IMAGE':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}