import 'package:audoria/screens/add_child.dart';
import 'package:audoria/screens/captured_image.dart';
import 'package:audoria/screens/one_file.dart';
import 'package:audoria/screens/parent_home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OneFile(),
    );
  }
}

