import 'package:flutter/material.dart';

import 'screens/add_child_screen.dart';
import 'screens/all_lessons_screen.dart';
import 'screens/camera_capture_screen.dart';
import 'screens/captured_image_screen.dart';
import 'screens/child_home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/login_screen.dart';
import 'screens/single_file_screen.dart';
import 'screens/parent_home_screen.dart';
import 'screens/parent_qr_screen.dart';
import 'screens/questions_screen.dart';
import 'screens/saved_files_screen.dart';
import 'screens/scan_qr_code_screen.dart';
import 'screens/splash_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => SplashScreen(),
  'login': (context) => LoginScreen(),
  'parent_home': (context) => ParentHomeScreen(),
  'child_home': (context) => ChildHomeScreen(),
  'add_child': (context) => AddChildScreen(),
  'all_lessons': (context) => AllLessonsScreen(),
  'camera_capture': (context) => CameraCaptureScreen(),
  'captured_image': (context) => CapturedImageScreen(),
  'insights': (context) => InsightsScreen(),
  'single_file': (context) => SingleFileScreen(),
  'parent_qr': (context) => ParentQrScreen(),
  'questions': (context) => QuestionsScreen(),
  'saved_files': (context) => SavedFilesScreen(),
  'scan_qr_code': (context) => ScanQrCodeScreen(),
};
