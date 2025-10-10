import 'package:audoria/screens/all_lessons_page.dart';
import 'package:audoria/screens/saved_files_page.dart';
import 'package:audoria/screens/splash_screen.dart';
import 'screens/child_home.dart';
import 'package:audoria/screens/insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:audoria/custom_widgets/custom_appbar.dart';
import 'package:audoria/screens/camera_capture_screen.dart';
import 'package:audoria/utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
            debugShowCheckedModeBanner: false,
      title: 'Audoria',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Inter',
      ),
       home: Scaffold(
        backgroundColor: bgColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: CustomAppbar(),
        ),
        body: InsightsScreen(),
      ),
//       home: const SplashScreen(),
      routes: {
        '/child_home': (context) => const ChildHomePage(username: 'Child'),
        '/saved_files': (context) => const SavedFilesPage(),
        '/all_lessons': (context) => const AllLessonsPage(),
      },
    );
  }
}
