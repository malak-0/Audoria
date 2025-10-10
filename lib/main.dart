import 'package:audoria/firebase_options.dart';
import 'package:audoria/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:audoria/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        colorScheme: ColorScheme.fromSeed(seedColor: bgColor),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: bgColor,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
        ),
      ),
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
