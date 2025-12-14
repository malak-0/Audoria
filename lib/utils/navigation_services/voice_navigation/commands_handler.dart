import 'dart:io';
import 'dart:async';
import 'package:audoria/models/commands_model.dart';
import 'package:audoria/models/lesson_file_model.dart';
import 'package:audoria/utils/ai_services/gemini.dart';
import 'package:audoria/utils/ai_services/text_extraction.dart';
import 'package:flutter/material.dart';
import 'package:audoria/data/commands_data.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';

class CommandHandler {
  final SpeechFeedback tts;
  final textExtractor = TextExtractionService();
  final geminiService = GeminiService();
  VoiceService? _voiceService;

  Timer? _commandDebounceTimer;
  bool _isDisposed = false;

  CommandHandler({required this.tts});

  void setVoiceService(VoiceService voiceService) {
    _voiceService = voiceService;
  }

  Future<void> _safeResumeAfterTTS() async {
    if (_isDisposed) {
      return;
    }
    await _voiceService?.resumeAfterTTS();
  }

  Future<void> handleCommand(
    BuildContext context,
    String currentScreen,
    String command, {
    Object? arguments,
  }) async {
    command = command.toLowerCase().trim();

    if (command.isEmpty) {
      return;
    }

    if (command.split(' ').length > 6) {
      return;
    }

    _commandDebounceTimer?.cancel();

    _commandDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _processCommand(context, currentScreen, command, arguments);
    });
  }

  Future<void> _processCommand(
    BuildContext context,
    String currentScreen,
    String command,
    Object? arguments,
  ) async {
    if (!commandsData.containsKey(currentScreen)) {
      await _safeResumeAfterTTS();
      return;
    }

    for (var voiceCommand in commandsData[currentScreen]!) {
      final commandLower = voiceCommand.command.toLowerCase();

      if (command == commandLower) {
        await _executeCommand(context, voiceCommand, arguments);
        return;
      }

      if (commandLower.split(' ').length > 1 &&
          command.contains(commandLower)) {
        await _executeCommand(context, voiceCommand, arguments);
        return;
      }

      if (commandLower.split(' ').length == 1 &&
          command.contains(commandLower)) {
        await _executeCommand(context, voiceCommand, arguments);
        return;
      }
    }
  }

  Future<void> _executeCommand(
    BuildContext context,
    CommandsModel voiceCommand,
    Object? arguments,
  ) async {
    if (_isDisposed) {
      return;
    }

    try {
      if (!context.mounted) {
        return;
      }
    } catch (e) {
      return;
    }

    await _voiceService?.pauseDuringTTS();
    await tts.stop();
    await Future.delayed(const Duration(milliseconds: 200));

    if (voiceCommand.command == 'go back') {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        return;
      } else {
        await tts.speak("Cannot go back from this screen.");
        await _safeResumeAfterTTS();
        return;
      }
    } else if (voiceCommand.command == 'capture') {
      await tts.speak(voiceCommand.message);
      await _safeResumeAfterTTS();
      return;
    } else if (voiceCommand.command == 'summarize' ||
        voiceCommand.command == 'summarise' ||
        voiceCommand.command == 'summary' ||
        voiceCommand.command == 'summar') {
      await _handleSummarizationCommand(context, arguments);
    } else if (voiceCommand.command == 'read' ||
        voiceCommand.command == 'read file') {
      await _handleReadCommand(context, arguments);
    } else if (voiceCommand.command == 'quiz' ||
        voiceCommand.command == 'test') {
      await _handleQuizCommand(context, arguments);
    } else {
      try {
        if (context.mounted) {
          _navigateToScreen(
            context,
            voiceCommand.navigateTo,
            arguments: arguments,
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (voiceCommand.message.isNotEmpty) {
            await tts.speak(voiceCommand.message);
          }
        }
      } catch (e) {}
    }

    await _safeResumeAfterTTS();
  }

  void dispose() {
    _isDisposed = true;
    _commandDebounceTimer?.cancel();
    _commandDebounceTimer = null;
  }

  Future<void> _safeNavigate(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    try {
      if (routeName == 'summarization' || routeName == 'quizzes') {
        Navigator.pushReplacementNamed(
          context,
          routeName,
          arguments: arguments,
        );
      } else {
        Navigator.pushNamed(context, routeName, arguments: arguments);
      }
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  void _navigateToScreen(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    _safeNavigate(context, routeName, arguments: arguments);
  }

  Future<void> _handleSummarizationCommand(
    BuildContext context,
    Object? fileData,
  ) async {
    try {
      if (fileData is! Map<String, dynamic>) {
        await tts.speak("Invalid file provided.");
        await _safeResumeAfterTTS();
        return;
      }

      if (!context.mounted) {
        await _safeResumeAfterTTS();
        return;
      }

      // Navigate to loading screen first
      Navigator.pushNamed(
        context,
        'summarization',
        arguments: {'fileData': fileData, 'isLoading': true},
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final file = LessonFile.fromMap(fileData);
      String? summary;

      // Check if content exists and is not empty
      if (file.content != null && file.content!.trim().isNotEmpty) {
        await tts.speak("Summarizing the content...");

        // Clean up the content first - remove page markers and empty lines
        String cleanContent = file.content!
            .replaceAll(RegExp(r'--- Page \d+ ---'), '')
            .replaceAll(RegExp(r'\n\s*\n'), '\n')
            .trim();

        if (cleanContent.isNotEmpty) {
          summary = await geminiService.summarizeText(cleanContent);
        }
      } else {
        await tts.speak("No content available in this file.");
        Navigator.pushReplacementNamed(
          context,
          'summarization',
          arguments: {
            'fileData': fileData,
            'error': "No content available in the file.",
          },
        );
        await _safeResumeAfterTTS();
        return;
      }

      if (summary != null && summary.isNotEmpty) {
        Navigator.pushReplacementNamed(
          context,
          'summarization',
          arguments: {'summary': summary, 'fileData': fileData},
        );
        await Future.delayed(const Duration(milliseconds: 500));
        await tts.speak("Summarization complete.");
      } else {
        await tts.speak("Sorry, I couldn't generate a summary.");
        Navigator.pushReplacementNamed(
          context,
          'summarization',
          arguments: {
            'fileData': fileData,
            'error':
                "Failed to generate summary. The content might be too short or unclear.",
          },
        );
      }

      await _safeResumeAfterTTS();
    } catch (e) {
      await tts.speak("Sorry, I couldn't summarize the file.");
      Navigator.pushReplacementNamed(
        context,
        'summarization',
        arguments: {'fileData': fileData, 'error': "Error: ${e.toString()}"},
      );
      await _safeResumeAfterTTS();
    }
  }

  Future<void> _handleReadCommand(
    BuildContext context,
    Object? fileData,
  ) async {
    try {
      if (fileData is! Map<String, dynamic>) {
        await tts.speak("Invalid file provided.");
        await _safeResumeAfterTTS();
        return;
      }

      if (!context.mounted) {
        await _safeResumeAfterTTS();
        return;
      }

      await tts.stop();

      final file = LessonFile.fromMap(fileData);
      String? contentToRead;

      if (file.content != null && file.content!.trim().isNotEmpty) {
        contentToRead = file.content!;
      } else if (file.fileUrl != null) {
        await tts.speak("Downloading and extracting text...");
        final response = await http.get(Uri.parse(file.fileUrl!));

        if (response.statusCode != 200) {
          await tts.speak("Failed to download file.");
          await _safeResumeAfterTTS();
          return;
        }

        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_file.pdf');
        await tempFile.writeAsBytes(response.bodyBytes);

        final path = tempFile.path.toLowerCase();

        if (path.endsWith('.pdf')) {
          contentToRead = await TextExtractionService.extractTextFromPDF(
            tempFile,
          );
        } else {
          contentToRead = await TextExtractionService.extractTextFromImage(
            tempFile,
          );
        }

        await tempFile.delete();
      } else {
        await tts.speak("No readable content found in this file.");
        await _safeResumeAfterTTS();
        return;
      }

      if (contentToRead != null && contentToRead.trim().isNotEmpty) {
        await tts.speak("Reading the file now.");
        await Future.delayed(const Duration(milliseconds: 800));
        await tts.speak(contentToRead);
      } else {
        await tts.speak("This file doesn't have readable text content.");
      }

      await _safeResumeAfterTTS();
    } catch (e) {
      await tts.speak("Sorry, I couldn't read the file.");
      await _safeResumeAfterTTS();
    }
  }

  Future<void> _handleQuizCommand(
    BuildContext context,
    Object? fileData,
  ) async {
    try {
      if (fileData is! Map<String, dynamic>) {
        await tts.speak("Invalid file provided.");
        await _safeResumeAfterTTS();
        return;
      }

      if (!context.mounted) {
        await _safeResumeAfterTTS();
        return;
      }

      Navigator.pushNamed(
        context,
        'quizzes',
        arguments: {'fileData': fileData, 'isLoading': true},
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final file = LessonFile.fromMap(fileData);
      String? contentForQuiz;

      if (file.content != null && file.content!.trim().isNotEmpty) {
        contentForQuiz = file.content!;
      } else if (file.fileUrl != null) {
        await tts.speak("Downloading and extracting text for quiz...");
        final response = await http.get(Uri.parse(file.fileUrl!));

        if (response.statusCode != 200) {
          await tts.speak("Failed to download file.");
          await _safeResumeAfterTTS();
          return;
        }

        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_file.pdf');
        await tempFile.writeAsBytes(response.bodyBytes);

        final path = tempFile.path.toLowerCase();

        if (path.endsWith('.pdf')) {
          contentForQuiz = await TextExtractionService.extractTextFromPDF(
            tempFile,
          );
        } else {
          contentForQuiz = await TextExtractionService.extractTextFromImage(
            tempFile,
          );
        }

        await tempFile.delete();
      } else {
        await tts.speak("No content available to generate quiz.");
        await _safeResumeAfterTTS();
        return;
      }

      if (contentForQuiz != null && contentForQuiz.trim().isNotEmpty) {
        await tts.speak("Generating quiz questions, please wait...");
        final quizQuestions = await geminiService.generateQuizFromContent(
          contentForQuiz,
        );

        Navigator.pushReplacementNamed(
          context,
          'quizzes',
          arguments: {'quizData': quizQuestions, 'fileData': fileData},
        );
      } else {
        await tts.speak("Could not extract content for quiz generation.");
      }

      await _safeResumeAfterTTS();
    } catch (e) {
      await tts.speak("Sorry, I couldn't generate a quiz.");
      await _safeResumeAfterTTS();
    }
  }
}
