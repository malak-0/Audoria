import 'package:audoria/screens/all_lessons_page.dart';
import 'package:audoria/screens/saved_files_page.dart';
import 'package:audoria/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'screens/child_home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audoria',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Inter',
      ),
      home: const SplashScreen(),
      routes: {
        '/child_home': (context) => const ChildHomePage(username: 'Child'),
        '/saved_files': (context) => const SavedFilesPage(),
        '/all_lessons': (context) => const AllLessonsPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
