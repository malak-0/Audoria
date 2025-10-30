import 'dart:convert';
import 'package:audoria/utils/child_signup_helper.dart';
import 'package:audoria/utils/navigation_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrCodeScreen extends StatefulWidget {
  const ScanQrCodeScreen({super.key});

  @override
  State<ScanQrCodeScreen> createState() => _ScanQrCodeScreenState();
}

class _ScanQrCodeScreenState extends State<ScanQrCodeScreen> {
  final ChildSignupHelper childSignupHelper = ChildSignupHelper();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MobileScannerController cameraController = MobileScannerController();

  bool _isProcessing = false;
  String _statusMessage = '';

  void _onQRCodeDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null) return;

    _processQRCode(qrData);
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing QR code...';
    });

    try {
      print('Raw QR Data: $qrData');

      String cleanedData = qrData;
      
      // Handle the JSON string format
      if (qrData.startsWith('"') && qrData.endsWith('"')) {
        cleanedData = qrData.substring(1, qrData.length - 1);
      }
      
      // Replace escaped characters
      cleanedData = cleanedData.replaceAll(r'\"', '"');
      
      print('Cleaned QR Data: $cleanedData');

      final decodedData = json.decode(cleanedData);
      print('Decoded QR Data: $decodedData');

      if (decodedData is! Map<String, dynamic> || !decodedData.containsKey('token')) {
        throw Exception('Invalid QR code format. Expected token field.');
      }

      final String token = decodedData['token'];
      print('Extracted token: $token');

      if (token.isEmpty) {
        throw Exception('QR code missing authentication token');
      }

      setState(() {
        _statusMessage = 'Validating token...';
      });

      print('Calling validateQRToken with token: $token');
      final result = await childSignupHelper.validateQRToken(token);

      print('Validation result: $result');
      final String? customToken = result['customToken'];
      if (customToken == null || customToken.isEmpty) {
        throw Exception('No authentication token received from server');
      }

      setState(() {
        _statusMessage = 'Signing in...';
      });

      print('Signing in with custom token...');
      final userCredential = await _auth.signInWithCustomToken(customToken);
      print('Sign in successful: ${userCredential.user?.uid}');

      setState(() {
        _statusMessage = 'Login successful! Redirecting...';
      });

      // Add a small delay to show success message
      await Future.delayed(const Duration(seconds: 1));
      
      NavigationHelper.replaceWith(context, "child_home");
      
    } catch (e) {
      print('QR Login Error: $e');
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _isProcessing = false;
      });

      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        _statusMessage = "Please scan the QR code on the parent's screen.";
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _statusMessage.isEmpty
                    ? "Please scan the QR code on the parent's screen."
                    : _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: _isProcessing ? Colors.blue : Colors.black54,
                    width: _isProcessing ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: cameraController,
                        onDetect: _onQRCodeDetect,
                      ),
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
