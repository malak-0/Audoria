import 'package:audoria/models/commands_model.dart';

final commandsData = {
  'child_home': [
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
      command: 'lesson',
      navigateTo: 'saved_files',
      message: 'You are now in the lessons section. chose a file to study',
    ),
    CommandsModel(
      command: 'lessons',
      navigateTo: 'saved_files',
      message: 'You are now in the lessons section. chose a file to study',
    ),
    CommandsModel(
      command: 'questions',
      navigateTo: 'questions',
      message:
          "Hi! I'm Audoria, your AI assistant. What do you want to ask about?",
    ),
  ],
  'single_file_screen': [
     CommandsModel(
      command: 'summarize',
      navigateTo: 'summarization',
      message: 'Processing text',
    ),
    CommandsModel(
      command: 'summarise',
      navigateTo: 'summarization',
      message: 'Processing text',
    ),
    CommandsModel(
      command: 'summary',
      navigateTo: 'summarization',
      message: 'Processing text',
    ),
    CommandsModel(
      command: 'summar',
      navigateTo: 'summarization', message: 'Processing text', 
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
    'captured_image': [
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
