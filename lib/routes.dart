import 'package:audoria/models/lesson_file_model.dart';
import 'package:flutter/material.dart';
import 'screens/parent_screens/add_child_screen.dart';
import 'screens/parent_screens/all_lessons_screen.dart';
import 'screens/child_screens/camera_capture_screen.dart';
import 'screens/child_screens/captured_image_screen.dart';
import 'screens/child_screens/child_home_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/parent_screens/insights_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/child_screens/single_file_screen.dart';
import 'screens/parent_screens/parent_home_screen.dart';
import 'screens/parent_screens/parent_qr_screen.dart';
import 'screens/child_screens/questions_screen.dart';
import 'screens/child_screens/quizzes_screen.dart';
import 'screens/child_screens/saved_files_screen.dart';
import 'screens/child_screens/scan_qr_code_screen.dart';
import 'screens/child_screens/summarization_screen.dart';
import 'screens/child_screens/setting_child_screen.dart';
import 'screens/parent_screens/setting_parent_screen.dart';
import 'screens/child_screens/profile_child_screen.dart';
import 'screens/parent_screens/profile_parent_screen.dart';
import 'screens/splash_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => SplashScreen(),
  'login': (context) => LoginScreen(),
  'register': (context) => RegisterScreen(),
  'verify': (context) => EmailVerificationScreen(),
  'parent_home': (context) => ParentHomeScreen(),
  'child_home': (context) => ChildHomeScreen(),
  'add_child': (context) => AddChildScreen(),
  'all_lessons': (context) => AllLessonsScreen(),
  'camera_capture': (context) => const CameraCaptureScreen(),
  'captured_image': (context) => const CapturedImageScreen(),
  'insights': (context) => InsightsScreen(),
  'single_file_screen': (context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    LessonFile? selectedFile;

    if (arguments != null) {
      // Try new format with fileData map
      if (arguments['fileData'] != null) {
        final fileData = arguments['fileData'] as Map<String, dynamic>;
        selectedFile = LessonFile.fromMap(fileData);
      }
      // Try old format with selectedFile object
      else if (arguments['selectedFile'] != null) {
        selectedFile = arguments['selectedFile'] as LessonFile;
      }
    }

    if (selectedFile == null) {
      // Return error screen or handle gracefully
      return Scaffold(body: Center(child: Text('Error: File data not found')));
    }

    return SingleFileScreen(selectedFile: selectedFile);
  },
  'parent_qr': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return ParentQrScreen(
      childUid: args?['childUid'],
      username: args?['username'] ?? 'username',
    );
  },
  'questions': (context) => QuestionsScreen(),
  'quizzes': (context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is Map<String, dynamic>) {
      if (arguments['fileData'] != null) {
        final fileData = arguments['fileData'] as Map<String, dynamic>;
        final selectedFile = LessonFile.fromMap(fileData);
        return QuizzesScreen(selectedFile: selectedFile);
      }
    }

    return const QuizzesScreen();
  },
  'saved_files': (context) => SavedFilesScreen(),
  'scan_qr_code': (context) => ScanQrCodeScreen(),
  'summarization': (context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is Map<String, dynamic>) {
      if (arguments['fileData'] != null) {
        final fileData = arguments['fileData'] as Map<String, dynamic>;
        final selectedFile = LessonFile.fromMap(fileData);
        return SummarizationScreen(selectedFile: selectedFile);
      } else if (arguments['selectedFile'] != null) {
        final selectedFile = arguments['selectedFile'] as LessonFile;
        return SummarizationScreen(selectedFile: selectedFile);
      }
    } else if (arguments is String) {
      return SummarizationScreen(summary: arguments);
    }

    return SummarizationScreen(summary: '');
  },
  'setting_child': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SettingChild(childData: args?['childData'] as Map<String, String>?);
  },
  'setting_parent': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SettingParent(
      childrenData: args?['childrenData'] as List<Map<String, String>>? ?? [],
      parentName: args?['parentName'] as String? ?? 'Parent',
      parentEmail: args?['parentEmail'] as String? ?? '',
    );
  },
  'profile_child': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return ProfileChildScreen(
      childData: args?['childData'] as Map<String, String>?,
    );
  },
  'profile_parent': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return ProfileParentScreen(
      parentName: args?['parentName'] as String? ?? 'Parent',
      parentEmail: args?['parentEmail'] as String? ?? '',
    );
  },
};
