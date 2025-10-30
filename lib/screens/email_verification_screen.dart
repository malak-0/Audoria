import 'dart:async';
import 'package:audoria/utils/firebase_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  User? user;
  Timer? timer;
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkEmailVerification(),
    );
  }

  Future<void> _checkEmailVerification() async {
    setState(() => isChecking = true);
    await checkVerification(context, user);
    setState(() => isChecking = false);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Verification')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'A verification email has been sent.\n'
              'Please check your inbox and verify your email.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (isChecking) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
