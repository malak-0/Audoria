import 'package:audoria/models/lesson_file_model.dart';
import 'package:audoria/utils/navigation_services/navigation_helper.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/commands_handler.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:audoria/widgets/lottie_card.dart';
import 'package:audoria/widgets/page_header.dart';
import 'package:audoria/data/single_file_list.dart';
import 'package:audoria/utils/constants.dart';
import 'package:flutter/material.dart';

class SingleFileScreen extends StatefulWidget {
  final LessonFile selectedFile; 

  const SingleFileScreen({
    super.key,
    required this.selectedFile, 
  });

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
      commandHandler.handleCommand(context, 'saved_files', recognizedText,arguments: widget.selectedFile.fileUrl!,);
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
        await tts.speak("Sorry, this file doesn't have readable text content. The file may not have been processed yet.");
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
      body: Column(
        children: [
          PageHeader(
            title: widget.selectedFile.title,
            subTitle: '${widget.selectedFile.fileType} • ${widget.selectedFile.formattedFileSize}',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: ListView.builder(
                itemCount: fileOptionsList.length,
                itemBuilder: (context, index) {
                  final fileOption = fileOptionsList[index];
                  return Column(
                    children: [
                      LottieCard(
                        fileOptions: fileOption,
                        onTap: () async {
                          if (fileOption.title.toLowerCase() == 'read file') {
                            await _readFile();
                          } else if (fileOption.routeName != null) {
                            if (fileOption.routeName == 'summarization') {
                              // Convert to map to preserve all fields during navigation
                              final fileMap = widget.selectedFile.toFullMap();
                              NavigationHelper.goTo(
                                context,
                                fileOption.routeName!,
                                arguments: {'fileData': fileMap},
                              );
                            } else {
                              NavigationHelper.goTo(context, fileOption.routeName!);
                            }
                          }
                        },
                      ),
                      if (index != fileOptionsList.length - 1)
                        const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
