import 'package:audoria/custom_widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:audoria/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF9BB9FF),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: CustomAppbar(),
        ),
        body: LoginScreen(),
      ),
    );
  }
}
