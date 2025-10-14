import 'package:audoria/utils/ui_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void login(BuildContext context, String email, String password) async {
  String message;
  try {
    final _ = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    message = "Login Successful";
    navigatePushReplacement(context, "home");
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      message = 'No user found for that email.';
    } else if (e.code == 'wrong-password') {
      message = 'Wrong password provided for that user.';
    } else {
      message = e.message ?? "Error";
    }
  }
  showSnackBar(context, message);
}

Future<void> register(
  BuildContext context,
  String email,
  String password,
  String username,
) async {
  String message;
  try {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // Create Firestore document with user data
    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user?.uid)
        .set({
          'userId': credential.user?.uid,
          'email': email,
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
        });

    await credential.user?.sendEmailVerification();
    message =
        "Account created successfully. Verification link sent to your email.";
    navigatePushReplacement(context, "verify");
  } on FirebaseAuthException catch (e) {
    if (e.code == 'weak-password') {
      message = 'The password provided is too weak.';
    } else if (e.code == 'email-already-in-use') {
      message = 'The account already exists for that email.';
    } else {
      message = e.message ?? "Error";
    }
  } catch (e) {
    message = e.toString();
  }
  showSnackBar(context, message);
}

Future<void> checkVerification(BuildContext context, User? user) async {
  bool isEmailVerified = false;
  await user?.reload();
  user = FirebaseAuth.instance.currentUser;
  isEmailVerified = user?.emailVerified ?? false;
  if (isEmailVerified) {
    showSnackBar(context, "Email verified successfully!");
    navigatePushReplacement(context, "home");
  }
}

void resetPassword(BuildContext context, String email) async {
  String message;
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    message = "Password Reset Link Sent";
    navigatePushReplacement(context, "login");
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      message = 'No user found for that email.';
    } else if (e.code == 'invalid-email') {
      message = 'Invalid email format.';
    } else {
      message = e.message ?? "Error";
    }
  } catch (e) {
    message = e.toString();
  }
  showSnackBar(context, message);
}

void logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  navigatePushReplacement(context, "login");
  showSnackBar(context, "Logged Out");
}
