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
      ),
      home: const ChildHomePage(username: 'Mariam'),
      debugShowCheckedModeBanner: false,
    );
  }
}
