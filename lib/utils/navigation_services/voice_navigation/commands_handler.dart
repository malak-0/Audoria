import 'dart:io';
import 'package:audoria/utils/ai_services/gemini.dart';
import 'package:audoria/utils/ai_services/text_extraction.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/voice_navigation.dart';
import 'package:flutter/material.dart';
import 'package:audoria/data/commands_data.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CommandHandler {
  final SpeechFeedback tts;
  final textExtractor = TextExtractionService();
  final geminiService = GeminiService();

  CommandHandler({required this.tts});

  void handleCommand(
    BuildContext context,
    String currentScreen,
    String command, {
    Object? arguments,
  }) async {
    command = command.toLowerCase();

    if (!commandsData.containsKey(currentScreen)) return;

    for (var voiceCommand in commandsData[currentScreen]!) {
      if (command.contains(voiceCommand.command)) {
        await tts.speak(voiceCommand.message);

        if (voiceCommand.command == 'summarize') {
          final summary = await handleSummarization(arguments);
          if (summary != null) {
            navigateTo(context, 'summarization', arguments: summary);
          }
        }

        break;
      }
    }
  }

  Future<String?> handleSummarization(Object? fileUrl) async {
    try {
      if (fileUrl is! String) {
        await tts.speak("Invalid file provided.");
        return null;
      }

      await tts.speak("Downloading file, please wait...");

      // Download the file from the URL
      final http.Response response = await http.get(
        Uri.parse(fileUrl),
      ); // Use fileUrl parameter
      if (response.statusCode != 200) {
        await tts.speak("Failed to download file.");
        return null;
      }

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_file.pdf');
      await tempFile.writeAsBytes(response.bodyBytes);

      if (!await tempFile.exists()) {
        await tts.speak("File not found.");
        return null;
      }

      String extractedText;
      final path = tempFile.path.toLowerCase(); // Use tempFile, not file
      if (path.endsWith('.pdf')) {
        extractedText = await TextExtractionService.extractTextFromPDF(
          tempFile,
        );
      } else {
        extractedText = await TextExtractionService.extractTextFromImage(
          tempFile,
        );
      }

      await tts.speak("Summarizing the content...");
      final summary = await geminiService.summarizeText(extractedText);
      await tts.speak("Summarization complete.");

      // Clean up temporary file
      await tempFile.delete();

      return summary;
    } catch (e) {
      await tts.speak("Sorry, I couldn't summarize the file.");
      debugPrint("Error in summarization: $e");
      return null;
    }
  }

  // Future<void> _handleReading(BuildContext context, Object? file) async {
  //   try {
  //     await tts.speak("Reading the file, please wait...");
  //     final extractedText = await TextExtractionService.extractTextFromPDF(file);
  //     await tts.speak(extractedText);
  //   } catch (e) {
  //     await tts.speak("Sorry, I couldn't read the file.");
  //     debugPrint("Error in reading: $e");
  //   }
  // }

  // Future<void> _handleQuiz(BuildContext context, Object? file) async {
  //   try {
  //     await tts.speak("Extracting text from the file for quiz generation...");
  //     final extractedText = await TextExtractionService.extractTextFromPDF(file);

  //     await tts.speak("Generating quiz questions, please wait...");
  //     final quizQuestions = await geminiService.generateQuiz(extractedText);

  //     navigateTo(context, 'quizzes', arguments: quizQuestions);
  //   } catch (e) {
  //     await tts.speak("Sorry, I couldn't generate a quiz.");
  //     debugPrint("Error in quiz generation: $e");
  //   }
  // }
}
