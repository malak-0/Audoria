import 'package:audoria/services/voice_navigation.dart';
import 'package:flutter/material.dart';
import 'package:audoria/data/commands_data.dart';
import 'package:audoria/services/speak.dart';

class CommandHandler {
  final SpeechFeedback tts;

  CommandHandler({required this.tts});

  void handleCommand(BuildContext context, String currentScreen, String command) {
    command = command.toLowerCase();

    if (!commandsData.containsKey(currentScreen)) return;

    for (var voiceCommand in commandsData[currentScreen]!) {
      if (command.contains(voiceCommand.command)) {
        navigateTo(context, voiceCommand.navigateTo);
        tts.speak(voiceCommand.message);
        break;
      }
    }
  }
}
