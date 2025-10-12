import 'package:audoria/models/commands_model.dart';

final commandsData = {
  'home_page': [
    CommandsModel(
      command: 'camera',
      navigateTo: 'camera_capture',
      message: 'Say "capture" when you are ready to take the image.',
    ),
    CommandsModel(
      command: 'saved files',
      navigateTo: 'saved_files',
      message: 'You are now in the lessons section. chose afile to study',
    ),
    CommandsModel(
      command: 'questions',
      navigateTo: 'questions',
      message: 'Hi! I’m Audoria, your AI assistant. What do you want to ask about?',
    ),
  ],
};
