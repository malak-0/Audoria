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
      commandHandler.handleCommand(
        context,
        'saved_files',
        recognizedText,
        arguments: widget.selectedFile.fileUrl!,
      );
    };

    await tts.speak(
      "now , would u like me to summarize the file, extract the main topics or generate a quiz to test yourself, i can also read the whole file to help u understand what its talking about.",
    );

    voiceService.autoRestart = true;

    await voiceService.init();
  }

  Future<void> _readFile() async {
    try {
      final content = widget.selectedFile.content;

      if (content == null || content.isEmpty || content.trim().isEmpty) {
        await tts.speak(
          "Sorry, this file doesn't have readable text content. The file may not have been processed yet.",
        );
        return;
      }

      await tts.stop();
      await tts.speak("Reading the file now.");
      await Future.delayed(const Duration(milliseconds: 800));
      await tts.speak(content);
    } catch (e) {
      await tts.speak("Sorry, I couldn't read the file. Please try again.");
    }
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
        child: Column(
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                ],
              ),
            ),
            // Enhanced Page Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getFileTypeIcon(widget.selectedFile.fileType),
                          color: bgColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedFile.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getFileTypeColor(
                                      widget.selectedFile.fileType,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.selectedFile.fileType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getFileTypeColor(
                                        widget.selectedFile.fileType,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.description,
                                  size: 14,
                                  color: textColor.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.selectedFile.formattedFileSize,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Options Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu, color: textColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'What would you like to do?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Options List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: ListView.builder(
                  itemCount: fileOptionsList.length,
                  itemBuilder: (context, index) {
                    final fileOption = fileOptionsList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: LottieCard(
                        fileOptions: fileOption,
                        onTap: () async {
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
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getFileTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Colors.red;
      case 'DOC':
        return Colors.blue;
      case 'PPT':
        return Colors.orange;
      case 'MP4':
        return Colors.purple;
      case 'MP3':
        return Colors.green;
      case 'IMAGE':
        return Colors.pink;
      default:
        return Colors.grey;
    }
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
