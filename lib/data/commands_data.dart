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
      message: '',
    ),
    CommandsModel(command: 'lesson', navigateTo: 'saved_files', message: ''),
    CommandsModel(command: 'lessons', navigateTo: 'saved_files', message: ''),
    CommandsModel(
      command: 'questions',
      navigateTo: 'questions',
      message:
          "Hi! I'm Audoria, your AI assistant. What do you want to ask about?",
    ),
    CommandsModel(
      command: 'go back',
      navigateTo: 'back',
      message: 'Going back',
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
      navigateTo: 'summarization',
      message: 'Processing text',
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
    CommandsModel(
      command: 'go back',
      navigateTo: 'back',
      message: 'Going back',
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
    CommandsModel(
      command: 'go back',
      navigateTo: 'back',
      message: 'Going back',
    ),
  ],
  'saved_files': [
    CommandsModel(
      command: 'go back',
      navigateTo: 'back',
      message: 'Going back',
    ),
  ],
  'summarization': [
    CommandsModel(
      command: 'go back',
      navigateTo: 'back',
      message: 'Going back',
    ),
  ],
  'camera_capture': [
    CommandsModel(
      command: 'capture',
      navigateTo: 'capture',
      message: 'Capturing image',
    ),
    CommandsModel(
      command: 'go back',
      navigateTo: 'back',
      message: 'Going back',
    ),
  ],
};
