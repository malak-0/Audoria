import 'package:flutter/material.dart';

import 'screens/parent/add_child_screen.dart';
import 'screens/parent/all_lessons_screen.dart';
import 'screens/child/camera_capture_screen.dart';
import 'screens/child/captured_image_screen.dart';
import 'screens/child/child_home_screen.dart';
import 'screens/parent/insights_screen.dart';
import 'screens/login_screen.dart';
import 'screens/child/single_file_screen.dart';
import 'screens/parent/parent_home_screen.dart';
import 'screens/parent/parent_qr_screen.dart';
import 'screens/child/questions_screen.dart';
import 'screens/child/saved_files_screen.dart';
import 'screens/child/scan_qr_code_screen.dart';
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
