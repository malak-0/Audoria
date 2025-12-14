import 'package:audoria/utils/backend_services/shared_preferences_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // Navigate to next screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    // Check both Firebase Auth and Shared Preferences
    User? user = FirebaseAuth.instance.currentUser;
    bool isLoggedIn = await SharedPreferencesHelper.getIsLoggedIn();

    // If Firebase Auth has a user but shared preferences says not logged in,
    // sign out from Firebase to keep them in sync
    if (user != null && !isLoggedIn) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, 'login');
      }
      return;
    }

    // If user is logged in (both Firebase Auth and Shared Preferences confirm)
    if (user != null && isLoggedIn) {
      final userUid = user.uid;

      // Check if user is a parent
      final parentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .get();

      if (parentDoc.exists) {
        // User is a parent, navigate to parent home
        if (mounted) {
          Navigator.pushReplacementNamed(context, 'parent_home');
        }
        return;
      }

      // Check if user is a child
      final allUsers = await FirebaseFirestore.instance
          .collection('users')
          .get();
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
          break;
        }
      }

      if (isChild) {
        // User is a child, navigate to child home
        if (mounted) {
          Navigator.pushReplacementNamed(context, 'child_home');
        }
        return;
      }

      // User exists in Firebase Auth but not in database, clear login status
      await SharedPreferencesHelper.setLoggedIn(false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, 'login');
      }
    } else {
      // User is not logged in, navigate to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, 'login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9BB9FF),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 400,
                  height: 400,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
