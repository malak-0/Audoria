import 'package:audoria/firebase_options.dart';
import 'package:audoria/screens/captured_image.dart';
import 'package:audoria/screens/one_file.dart';
import 'package:audoria/screens/qr_parent.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CapturedImage(),
    );
  }
}

