import 'dart:async';
import 'dart:convert';
import 'package:audoria/utils/child_signup_helper.dart';
import 'package:audoria/utils/firebase_helpers.dart';
import 'package:audoria/widgets/custom_text.dart';
import 'package:audoria/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ParentQrScreen extends StatefulWidget {
  final String? childUid;
  final String username;

  const ParentQrScreen({super.key, this.childUid, this.username = "username"});

  static Route<dynamic> route(RouteSettings settings) {
    final args = settings.arguments;
    return MaterialPageRoute(
      builder: (context) => ParentQrScreen(
        childUid: args is String ? args : null,
        username: "username",
      ),
    );
  }

  @override
  State<ParentQrScreen> createState() => _ParentQrScreenState();
}

class _ParentQrScreenState extends State<ParentQrScreen> {
  final ChildSignupHelper childSignupHelper = ChildSignupHelper();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _qrData = '';
  bool _isLoading = true;
  String _errorMessage = '';
  String? _actualChildUid;
  StreamSubscription? _loginListener;
  bool _childLoggedIn = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeQRCode();
  }

  void _initializeQRCode() {
    if (_actualChildUid != null) return;

    final String? childUid =
        widget.childUid ??
        (ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>?)?['childUid'];

    print('Received childUid: $childUid');

    if (childUid == null || childUid.isEmpty) {
      setState(() {
        _errorMessage = 'Child UID is required to generate QR code';
        _isLoading = false;
      });
      return;
    }

    _generateQRCode(childUid);
    _startLoginListener(childUid);
  }

  Future<void> _generateQRCode(String childUid) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.childUid == null) {
        throw Exception('Child UID is null');
      }

      final tokenData = await childSignupHelper.generateQRLoginToken(
        widget.childUid!,
      );
      setState(() {
        _qrData = jsonEncode(tokenData['qrData']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate QR code: $e';
        _isLoading = false;
      });
    }
  }

  void _startLoginListener(String childUid) {
    final parentUid = _auth.currentUser?.uid;
    if (parentUid == null) {
      print('Parent UID is null, cannot start listener');
      return;
    }

    print('Starting login listener for:');
    print('Child UID: $childUid');
    print('Parent UID: $parentUid');

    _loginListener = _firestore
        .collection('loginStatus')
        .where('childUid', isEqualTo: childUid)
        .where('parentUid', isEqualTo: parentUid)
        .where('status', isEqualTo: 'success')
        .orderBy('loginTime', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            print('Firestore listener triggered');
            print('   Documents found: ${snapshot.docs.length}');

            if (snapshot.docs.isNotEmpty) {
              final doc = snapshot.docs.first;
              print('   Document data: ${doc.data()}');
              print('   Child logged in status: $_childLoggedIn');
            }

            if (snapshot.docs.isNotEmpty && !_childLoggedIn) {
              print('Child login detected! Navigating to parent home...');
              setState(() {
                _childLoggedIn = true;
              });

              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  print('Navigating to parent home screen');
                  Navigator.pushReplacementNamed(context, 'parent_home');
                } else {
                  print('Context not mounted, cannot navigate');
                }
              });
            }
          },
          onError: (error) {
            print('Firestore listener error: $error');
          },
        );
  }

  @override
  void dispose() {
    _loginListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Profile Header
                Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: textColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/profile.png',
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FutureBuilder(
                      future: getCurrentUsername(context),
                      builder: (context, snapshot) {
                        return CustomText.username(snapshot.data ?? '');
                      },
                    ),
                  ],
                ),

                // Main Content
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),

                      // Success Message
                      Text(
                        'Child Account Created Successfully!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'You\'ve successfully created your first child account. Scan the QR code below on your child\'s device using the Audoria app to let them start their learning journey!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: textColor.withOpacity(0.7),
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Instructions Title
                      Text(
                        'Scan QR Code from Child\'s Phone',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // QR Code Container
                      Container(
                        width: 320,
                        height: 320,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: textColor.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    bgColor,
                                  ),
                                )
                              : _errorMessage.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red.shade400,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _errorMessage,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : QrImageView(
                                  data: _qrData,
                                  size: 260,
                                  version: QrVersions.auto,
                                  backgroundColor: Colors.white,
                                  eyeStyle: QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: textColor,
                                  ),
                                  dataModuleStyle: QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: textColor,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Helper Text
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: textColor.withOpacity(0.7),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Once scanned, you\'ll be automatically redirected to the home screen.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textColor.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
