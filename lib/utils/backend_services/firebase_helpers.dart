import 'package:audoria/utils/ui_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> login(BuildContext context, String email, String password) async {
  String message = "";

  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userUid = credential.user!.uid;

    // Check if user is a parent FIRST (more efficient)
    final parentDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .get();

    if (parentDoc.exists) {
      navigatePushReplacement(context, "parent_home");
      showSnackBar(context, "Welcome Parent!");
      return;
    }

    // Check if user is a child by searching through all users' children subcollections
    final allUsers = await FirebaseFirestore.instance.collection('users').get();

    bool isChild = false;

    for (final userDoc in allUsers.docs) {
      final childDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('children')
          .doc(userUid)
          .get();

      if (childDoc.exists) {
        isChild = true;
        break; // Exit loop early if found
      }
    }

    if (isChild) {
      navigatePushReplacement(context, "child_home");
      showSnackBar(context, "Welcome!");
      return;
    }

    await FirebaseAuth.instance.signOut();
    message = "User account not found in system.";
  } on FirebaseAuthException catch (e) {
    message = _handleAuthError(e);
  } catch (e) {
    message = "An unexpected error occurred: $e";
  }

  showSnackBar(context, message);
}

Future<void> register(
  BuildContext context,
  String email,
  String password,
  String username,
) async {
  String message = "";

  try {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
          "userId": credential.user!.uid,
          "email": email,
          "username": username,
          "createdAt": FieldValue.serverTimestamp(),
        });

    await credential.user!.sendEmailVerification();
    navigatePushReplacement(context, "add_child");
    message = "Account created.";
  } on FirebaseAuthException catch (e) {
    message = _handleAuthError(e);
  }

  showSnackBar(context, message);
}

Future<void> checkVerification(BuildContext context, User? user) async {
  await user?.reload();
  user = FirebaseAuth.instance.currentUser;

  if (user?.emailVerified ?? false) {
    showSnackBar(context, "Email verified successfully!");
    navigatePushReplacement(context, "add_child");
  }
}

void resetPassword(BuildContext context, String email) async {
  String message = "";
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    message = "Password reset link sent!";
    navigatePushReplacement(context, "login");
  } on FirebaseAuthException catch (e) {
    message = _handleAuthError(e);
  }
  showSnackBar(context, message);
}

void logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  navigatePushReplacement(context, "login");
  showSnackBar(context, "Logged Out");
}

// Update getCurrentUsername
Future<String> getCurrentUsername() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return "User";

  // Check if parent
  final parentDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (parentDoc.exists) {
    return parentDoc.data()?['username'] ?? "Parent";
  }

  // Check if child (direct collection)
  final childDoc = await FirebaseFirestore.instance
      .collection('children')
      .doc(user.uid)
      .get();

  if (childDoc.exists) {
    return childDoc.data()?['name'] ?? "Child";
  }

  return "User";
}

// Update getUserType
Future<String> getUserType() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return "unknown";

  final parentDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (parentDoc.exists) return "parent";

  // Check if user is a child by searching through all users' children subcollections
  final allUsers = await FirebaseFirestore.instance.collection('users').get();

  for (final userDoc in allUsers.docs) {
    final childDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userDoc.id)
        .collection('children')
        .doc(user.uid)
        .get();

    if (childDoc.exists) {
      return "child";
    }
  }

  final childDoc = await FirebaseFirestore.instance
      .collection('children')
      .doc(user.uid)
      .get();

  if (childDoc.exists) return "child";

  return "unknown";
}

// Update getCurrentUserData
Future<Map<String, dynamic>?> getCurrentUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final parentDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (parentDoc.exists) return parentDoc.data();

  final childDoc = await FirebaseFirestore.instance
      .collection('children')
      .doc(user.uid)
      .get();

  if (childDoc.exists) return childDoc.data();

  return null;
}

// Update getChildParent
Future<Map<String, dynamic>?> getChildParent(String childId) async {
  final childDoc = await FirebaseFirestore.instance
      .collection('children')
      .doc(childId)
      .get();

  if (childDoc.exists) {
    final parentId = childDoc.data()?['parentUid'];
    if (parentId != null) {
      final parentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .get();
      return parentDoc.data();
    }
  }
  return null;
}

// Get child data for settings screen
Future<Map<String, String>?> getChildDataForSettings() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  // Try direct children collection first
  final childDoc = await FirebaseFirestore.instance
      .collection('children')
      .doc(user.uid)
      .get();

  if (childDoc.exists) {
    final data = childDoc.data();
    if (data != null) {
      return {
        'name': data['name']?.toString() ?? '',
        'age': data['age']?.toString() ?? '',
        'grade': data['grade']?.toString() ?? '',
        'school': data['school']?.toString() ?? '',
      };
    }
  }

  // Try searching in users' children subcollections
  final allUsers = await FirebaseFirestore.instance.collection('users').get();

  for (final userDoc in allUsers.docs) {
    final childDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userDoc.id)
        .collection('children')
        .doc(user.uid)
        .get();

    if (childDoc.exists) {
      final data = childDoc.data();
      if (data != null) {
        return {
          'name': data['name']?.toString() ?? '',
          'age': data['age']?.toString() ?? '',
          'grade': data['grade']?.toString() ?? '',
          'school': data['school']?.toString() ?? '',
        };
      }
    }
  }

  return null;
}

// Get parent children list for settings screen
Future<List<Map<String, String>>> getParentChildrenForSettings() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  try {
    final childrenSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('children')
        .get();

    return childrenSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name']?.toString() ?? '',
        'age': data['age']?.toString() ?? '',
        'grade': data['grade']?.toString() ?? '',
        'school': data['school']?.toString() ?? '',
      };
    }).toList();
  } catch (e) {
    print('Error fetching parent children: $e');
    return [];
  }
}

String _handleAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'Invalid email format.';
    case 'user-not-found':
      return 'No user found with this email.';
    case 'wrong-password':
      return 'Wrong password.';
    case 'weak-password':
      return 'Password is too weak.';
    case 'email-already-in-use':
      return 'Email already exists.';
    case 'network-request-failed':
      return 'Network error. Please check your connection.';
    default:
      return e.message ?? "Authentication error.";
  }
}
