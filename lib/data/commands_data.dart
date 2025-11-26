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
      message: 'You are now in the lessons section. chose a file to study',
    ),
    CommandsModel(
      command: 'questions',
      navigateTo: 'questions',
      message:
          'Hi! I’m Audoria, your AI assistant. What do you want to ask about?',
    ),
  ],
  'saved_files': [
    CommandsModel(
      command: 'summarize',
      navigateTo: 'summarization',
      message: 'processing text',
    ),
    CommandsModel(
      command: 'quiz',
      navigateTo: 'quizzes',
      message: 'generating questions',
    ),
    CommandsModel(
      command: 'read',
      navigateTo: 'summarization',
      message: 'extracting text',
    ),
  ],
};
