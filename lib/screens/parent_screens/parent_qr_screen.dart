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
  final String ?childUid;
  final String username;

  const ParentQrScreen({
    super.key, 
    this.childUid,
    this.username = "username"
  });

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

    final String? childUid = widget.childUid ?? 
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['childUid'];
    
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

      final tokenData = await childSignupHelper.generateQRLoginToken(widget.childUid!);
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
      .listen((QuerySnapshot snapshot) {
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
  }, onError: (error) {
    print('Firestore listener error: $error');
  });
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
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 25),
            Row(
              children: [
                Image.asset('assets/images/profile.png', width: 50, height: 50),
                SizedBox(width: 10),
                FutureBuilder(
                  future: getCurrentUsername(context),
                  builder: (context, snapshot) {
                    return CustomText.username(snapshot.data ?? '');
                  },
                ),
              ],
            ),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 45),
                  CustomText.body(
                    'Now you‘ve successfully created your \nfirst child account , scan the QR code \non Audoria in your child phone to let \nhim start learning journy !',
                  ),
                  SizedBox(height: 45),
                  CustomText.subtitle('scan QR code from  child phone'),
                  SizedBox(height: 20),
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      color: textColor.withValues(alpha: 0.1),
                    ),
                    child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : _errorMessage.isNotEmpty
                                ? Text(
                                    _errorMessage,
                                    style: const TextStyle(color: textColor),
                                    textAlign: TextAlign.center,
                                  )
                                : QrImageView(
                                    data: _qrData,
                                    size: 260,
                                    version: QrVersions.auto,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black,
                                    ),
                                  ),
                      ),

                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
