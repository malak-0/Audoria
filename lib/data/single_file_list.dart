import 'package:audoria/models/file_options_model.dart';

final List<FileOptionsModel> fileOptionsList = [
  FileOptionsModel(
    title: 'Read file',
    iconPath: 'assets/animations/readFile.json',
  ),
  FileOptionsModel(
    title: 'Summarization',
    iconPath: 'assets/animations/summarization.json',
    isReversed: true,
    routeName: 'summarization',
  ),
  FileOptionsModel(
    title: 'quizzes',
    iconPath: 'assets/animations/quizzes.json',
    routeName: 'quizzes',
  ),
];
