import 'package:audoria/models/lesson_file_model.dart';
import 'package:audoria/utils/ai_services/gemini.dart';
import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/commands_handler.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../../main.dart';

class SummarizationScreen extends StatefulWidget {
  final LessonFile? selectedFile;
  final String? summary;
  final bool isLoading;
  final String? error;

  const SummarizationScreen({
    super.key,
    this.selectedFile,
    this.summary,
    this.isLoading = false,
    this.error,
  });

  @override
  State<SummarizationScreen> createState() => _SummarizationScreenState();
}

class _SummarizationScreenState extends State<SummarizationScreen>
    with RouteAware {
  late SpeechFeedback tts;
  late CommandHandler commandHandler;
  final voiceService = VoiceService();
  final GeminiService geminiService = GeminiService();

  bool isLoading = true;
  String summary = '';
  Timer? loadingTimer;

  @override
  void initState() {
    super.initState();
    _initializeVoiceSystem();
    _generateSummary();
  }

  @override
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

    await _initializeVoiceSystem();
  }

  Future<void> _initializeVoiceSystem() async {
    // Wait a bit to ensure previous screen's cleanup is complete
    await Future.delayed(const Duration(milliseconds: 500));

    // Hard reset voice service to ensure clean state
    await voiceService.hardReset();

    if (!mounted) return;

    tts = SpeechFeedback();
    commandHandler = CommandHandler(tts: tts);
    commandHandler.setVoiceService(voiceService);
    voiceService.autoRestart = false;

    voiceService.onResult = (recognizedText) {
      if (mounted) {
        commandHandler.handleCommand(context, 'summarization', recognizedText);
      }
    };

    voiceService.autoRestart = true;
    await voiceService.init();
  }

  Future<void> _generateSummary() async {
    try {
      // Get content from file
      String? content;

      if (widget.selectedFile != null) {
        content = widget.selectedFile!.content;
      } else if (widget.summary != null && widget.summary!.isNotEmpty) {
        // If summary is already provided (backward compatibility)
        setState(() {
          isLoading = false;
          summary = widget.summary!;
        });
        await _readSummary();
        return;
      }

      // Check if content is valid (not null, not empty, and not the placeholder message)
      final isValidContent =
          content != null &&
          content.isNotEmpty &&
          content.trim().isNotEmpty &&
          content != 'Text extraction not available for this file type';

      if (!isValidContent) {
        setState(() {
          isLoading = false;
          summary =
              'Sorry, this file does not have readable text content. '
              'This might be because:\n'
              '• The file type does not support text extraction\n'
              '• The file was uploaded before text extraction was added\n'
              '• Text extraction failed during upload\n\n'
              'Please try re-uploading the file.';
        });
        await voiceService.pauseDuringTTS();
        await tts.speak(
          'Sorry, this file does not have readable text content. Please try re-uploading the file.',
        );
        await Future.delayed(const Duration(seconds: 1));
        await voiceService.resumeAfterTTS();
        return;
      }

      // Start periodic "loading" messages
      _startLoadingMessages();

      // Generate summary using Gemini
      final generatedSummary = await geminiService.summarizeText(content);

      // Stop loading messages
      _stopLoadingMessages();

      setState(() {
        isLoading = false;
        summary = generatedSummary;
      });

      // Read the summary
      await _readSummary();
    } catch (e) {
      _stopLoadingMessages();
      setState(() {
        isLoading = false;
        summary = 'Sorry, I could not generate a summary. Please try again.';
      });
      await voiceService.pauseDuringTTS();
      await tts.speak(summary);
      await Future.delayed(const Duration(seconds: 1));
      await voiceService.resumeAfterTTS();
    }
  }

  void _startLoadingMessages() {
    loadingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (isLoading && mounted) {
        await voiceService.pauseDuringTTS();
        await tts.speak("Loading");
        await Future.delayed(const Duration(milliseconds: 500));
        await voiceService.resumeAfterTTS();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopLoadingMessages() {
    loadingTimer?.cancel();
    loadingTimer = null;
  }

  Future<void> _readSummary() async {
    if (summary.isNotEmpty && mounted) {
      await voiceService.pauseDuringTTS();
      await tts.speak(summary); // This Future completes when TTS finishes
      await voiceService.resumeAfterTTS();
    }
  }

  @override
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _stopLoadingMessages();
    try {
      tts.stop();
    } catch (e) {}
    try {
      voiceService.uninitialize();
    } catch (e) {}
    try {
      commandHandler.dispose();
    } catch (e) {}
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
                // Header
                Row(
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
                        child: Icon(
                          Icons.arrow_back,
                          color: textColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: textColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.summarize, color: bgColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Summary',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Title Section
                Text(
                  'File Summary',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.selectedFile?.title ?? 'File Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 40),

                // Summary Card
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
                  child: isLoading
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: bgColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: bgColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Generating Summary',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            Text(
                              'Please wait while we summarize the content...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: bgColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: bgColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Summary',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              summary,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: textColor.withOpacity(0.8),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 40),

                // Animation Section
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Lottie.asset(
                      'assets/animations/summarization.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
