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
      home: Scaffold(
        backgroundColor: bgColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: CustomAppbar(),
        ),
        body: InsightsScreen(),
      ),
    );
  }
}
